import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frigo/app.dart';
import 'package:frigo/core/router/app_router.dart';
import 'package:frigo/data/seed/seed_data.dart';
import 'package:frigo/models/models.dart';
import 'package:frigo/providers/fridge_overview_provider.dart';
import 'package:frigo/providers/fridge_provider.dart';
import 'package:frigo/providers/profile_provider.dart';
import 'package:frigo/providers/repository_providers.dart';
import 'package:frigo/providers/router_provider.dart';

final _today = DateTime(2026, 11, 15, 9);

Future<ProviderContainer> pumpFridge(WidgetTester tester) async {
  tester.view.physicalSize = const Size(1080, 2340);
  tester.view.devicePixelRatio = 2.75;
  addTearDown(tester.view.reset);
  final container = ProviderContainer(
    overrides: [
      clockProvider.overrideWithValue(() => _today),
      routerProvider.overrideWithValue(
        createAppRouter(initialLocation: '/fridge'),
      ),
    ],
  );
  addTearDown(container.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(container: container, child: const FrigoApp()),
  );
  await tester.pumpAndSettle();
  return container;
}

Finder onShelf(ShelfCategory shelf, Finder finder) =>
    find.descendant(of: find.byKey(Key('shelf-${shelf.name}')), matching: finder);

void main() {
  group('My Fridge screen', () {
    testWidgets('shows item count, banner and the three shelves',
        (tester) async {
      await pumpFridge(tester);

      expect(find.text('My Fridge'), findsOneWidget);
      expect(find.text('13 items'), findsOneWidget);
      expect(find.text('EY'), findsOneWidget);
      expect(
        find.text('Yogurt and sea bass expire soon. Try cacık or baked sea '
            'bass today.'),
        findsOneWidget,
      );
      expect(find.text('DAIRY'), findsOneWidget);
      expect(find.text('MEAT AND LEFTOVERS'), findsOneWidget);
      expect(find.text('VEGETABLE DRAWER'), findsOneWidget);
      expect(find.text('+ Add ingredients'), findsOneWidget);
      expect(find.text('Suggest recipes'), findsOneWidget);
    });

    testWidgets('items sit on their shelf with 1d / 2d badges',
        (tester) async {
      await pumpFridge(tester);

      for (final name in ['Milk', 'Cheese', 'Eggs', 'Yogurt', 'Butter']) {
        expect(onShelf(ShelfCategory.dairy, find.text(name)), findsOneWidget);
      }
      for (final name in ['Chicken', 'Sea bass', 'Lentil soup']) {
        expect(
          onShelf(ShelfCategory.meatAndLeftovers, find.text(name)),
          findsOneWidget,
        );
      }
      for (final name in ['Tomato', 'Pepper', 'Carrot', 'Lemon', 'Onion']) {
        expect(
          onShelf(ShelfCategory.vegetableDrawer, find.text(name)),
          findsOneWidget,
        );
      }

      expect(
        find.descendant(
          of: find.byKey(const Key('fridge-item-ing-yogurt')),
          matching: find.text('2d'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byKey(const Key('fridge-item-ing-sea-bass')),
          matching: find.text('1d'),
        ),
        findsOneWidget,
      );
      expect(find.text('1d'), findsOneWidget);
      expect(find.text('2d'), findsOneWidget);
    });

    testWidgets('newly added items appear live and update the count',
        (tester) async {
      final container = await pumpFridge(tester);

      container.read(fridgeProvider.notifier).add(
            Ingredient(
              id: 'ing-spinach',
              name: 'Spinach',
              shelf: ShelfCategory.vegetableDrawer,
              expiresOn: DateTime(2026, 11, 15),
            ),
          );
      await tester.pumpAndSettle();

      expect(find.text('14 items'), findsOneWidget);
      expect(
        onShelf(ShelfCategory.vegetableDrawer, find.text('Spinach')),
        findsOneWidget,
      );
      expect(find.text('0d'), findsOneWidget);
      expect(
        find.textContaining('Yogurt, sea bass and spinach expire soon.'),
        findsOneWidget,
      );
    });

    testWidgets('tapping an item shows details and can remove it',
        (tester) async {
      final container = await pumpFridge(tester);

      await tester.tap(find.text('Sea bass'));
      await tester.pumpAndSettle();
      expect(
        find.text('Expires tomorrow · 16 Nov', findRichText: true),
        findsOneWidget,
      );
      expect(find.text('Meat and leftovers · 2 fillets'), findsOneWidget);

      await tester.tap(find.text('Remove from fridge'));
      await tester.pumpAndSettle();

      expect(find.text('Sea bass removed'), findsOneWidget);
      expect(find.text('12 items'), findsOneWidget);
      expect(
        container.read(fridgeProvider).any((i) => i.id == 'ing-sea-bass'),
        isFalse,
      );
      expect(
        find.text('Yogurt expires soon. Try cacık today.'),
        findsOneWidget,
      );
    });

    testWidgets('banner hides when nothing is expiring and empty shelves '
        'say so', (tester) async {
      final container = await pumpFridge(tester);
      final notifier = container.read(fridgeProvider.notifier);
      for (final item in [...container.read(fridgeProvider)]) {
        if (item.shelf != ShelfCategory.vegetableDrawer) {
          notifier.remove(item.id);
        }
      }
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('expiry-banner')), findsNothing);
      expect(find.text('5 items'), findsOneWidget);
      expect(find.text('Nothing here yet'), findsNWidgets(2));
    });

    testWidgets('top buttons open shopping list and profile', (tester) async {
      await pumpFridge(tester);

      await tester.tap(find.byTooltip('Shopping list'));
      await tester.pumpAndSettle();
      expect(find.text('Notes on your fridge door'), findsOneWidget);
      await tester.tap(find.byTooltip('Back'));
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Profile'));
      await tester.pumpAndSettle();
      expect(find.text('Elif Yılmaz'), findsOneWidget);
    });
  });

  group('fridge overview helpers', () {
    test('groupByShelf keeps every shelf and sorts soonest first', () {
      final grouped = groupByShelf(SeedData.fridgeIngredients(_today));
      expect(grouped.keys, ShelfCategory.values);
      expect(
        grouped[ShelfCategory.dairy]!.map((i) => i.name),
        ['Yogurt', 'Milk', 'Eggs', 'Cheese', 'Butter'],
      );
      expect(
        grouped[ShelfCategory.meatAndLeftovers]!.first.name,
        'Sea bass',
      );
      expect(groupByShelf(const []).values, everyElement(isEmpty));
    });

    test('alert respects allergies when suggesting recipes', () {
      final container = ProviderContainer(
        overrides: [clockProvider.overrideWithValue(() => _today)],
      );
      addTearDown(container.dispose);
      final profile = container.read(profileProvider);
      container.read(profileProvider.notifier).updateDietary(
            allergies: {...profile.allergies, Allergen.fish, Allergen.milk},
            customAllergies: const [],
            diet: Diet.none,
          );

      expect(
        container.read(fridgeExpiryAlertProvider)!.message,
        'Yogurt and sea bass expire soon.',
      );
    });

    test('expired items get their own warning', () {
      final alert = buildExpiryAlert(
        fridge: [
          Ingredient(
            id: 'old-milk',
            name: 'Milk',
            shelf: ShelfCategory.dairy,
            expiresOn: DateTime(2026, 11, 13),
          ),
        ],
        matches: const [],
        now: _today,
      );
      expect(alert!.expiringSoon, isEmpty);
      expect(alert.message, 'Milk has expired – check before using.');
    });

    test('no alert without expiring items', () {
      expect(
        buildExpiryAlert(
          fridge: [
            const Ingredient(
              id: 'salt',
              name: 'Salt',
              shelf: ShelfCategory.dairy,
            ),
          ],
          matches: const [],
          now: _today,
        ),
        isNull,
      );
    });
  });
}
