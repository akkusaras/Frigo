import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frigo/app.dart';
import 'package:frigo/core/router/app_router.dart';
import 'package:frigo/core/utils/date_format.dart';
import 'package:frigo/data/services/ingredient_catalog.dart';
import 'package:frigo/models/models.dart';
import 'package:frigo/providers/fridge_provider.dart';
import 'package:frigo/providers/repository_providers.dart';
import 'package:frigo/providers/router_provider.dart';

final _today = DateTime(2026, 11, 15, 9);

Future<ProviderContainer> pumpAt(WidgetTester tester, String location) async {
  tester.view.physicalSize = const Size(1080, 2340);
  tester.view.devicePixelRatio = 2.75;
  addTearDown(tester.view.reset);
  final container = ProviderContainer(
    overrides: [
      clockProvider.overrideWithValue(() => _today),
      routerProvider.overrideWithValue(
        createAppRouter(initialLocation: location),
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

Ingredient? findInFridge(ProviderContainer c, String name) {
  for (final i in c.read(fridgeProvider)) {
    if (i.name == name) return i;
  }
  return null;
}

Future<void> tapVisible(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

/// Toggles a scan row via its checkbox.
Future<void> toggleRow(WidgetTester tester, String name) => tapVisible(
      tester,
      find.descendant(
        of: find.byKey(Key('scan-row-$name')),
        matching: find.byType(Checkbox),
      ),
    );

Finder onShelf(ShelfCategory shelf, String text) => find.descendant(
      of: find.byKey(Key('shelf-${shelf.name}')),
      matching: find.text(text),
    );

void main() {
  group('IngredientCatalog', () {
    const catalog = IngredientCatalog();

    test('suggests prefix matches first', () {
      expect(catalog.suggestions('spin'), ['Spinach', 'Spinach, frozen']);
      expect(catalog.suggestions('cheese').first, 'Cheese');
      expect(catalog.suggestions('cheese'), contains('Feta cheese'));
      expect(catalog.suggestions('  '), isEmpty);
    });

    test('assigns shelves for known and unknown items', () {
      expect(catalog.shelfFor('feta CHEESE'), ShelfCategory.dairy);
      expect(catalog.shelfFor('Salmon'), ShelfCategory.meatAndLeftovers);
      expect(catalog.shelfFor('Goat milk'), ShelfCategory.dairy);
      expect(catalog.shelfFor('Leftover pilaf'), ShelfCategory.meatAndLeftovers);
      expect(catalog.shelfFor('Rocket'), ShelfCategory.vegetableDrawer);
    });

    test('estimates expiry and canonicalises names', () {
      expect(catalog.estimatedExpiry('Spinach', _today), DateTime(2026, 11, 19));
      expect(catalog.estimatedExpiry('Mystery jar', _today), isNull);
      expect(catalog.canonicalName('  spinach '), 'Spinach');
      expect(catalog.canonicalName('rocket   leaves'), 'Rocket leaves');
    });

    test('formats short dates', () {
      expect(formatShortDate(DateTime(2026, 11, 20)), '20 Nov');
      expect(formatShortDate(DateTime(2027, 1, 3)), '3 Jan');
    });
  });

  group('4. Add ingredients', () {
    testWidgets('shows capture cards and manual entry', (tester) async {
      await pumpAt(tester, '/fridge/add');

      expect(find.text('Take a photo'), findsOneWidget);
      expect(find.text('Scan a receipt'), findsOneWidget);
      expect(find.text('OR TYPE IT IN'), findsOneWidget);
      expect(find.text('e.g. 20 Nov'), findsOneWidget);
      final button = tester.widget<FilledButton>(
        find.byKey(const Key('add-to-fridge')),
      );
      expect(button.onPressed, isNull);
    });

    testWidgets('suggestion chip + date picker add the item to its shelf',
        (tester) async {
      final container = await pumpAt(tester, '/fridge/add');

      await tester.enterText(find.byKey(const Key('ingredient-input')), 'spin');
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('suggestion-Spinach')), findsOneWidget);
      expect(find.byKey(const Key('suggestion-Spinach, frozen')), findsOneWidget);

      await tester.tap(find.byKey(const Key('suggestion-Spinach')));
      await tester.pumpAndSettle();
      expect(find.text('Leave empty and we will use 19 Nov.'), findsOneWidget);
      final shelfChip = tester.widget<ChoiceChip>(
        find.byKey(const Key('shelf-choice-vegetableDrawer')),
      );
      expect(shelfChip.selected, isTrue);

      await tapVisible(tester, find.byKey(const Key('expiry-input')));
      await tester.tap(find.text('20'));
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
      expect(find.text('20 Nov'), findsOneWidget);

      await tapVisible(tester, find.byKey(const Key('add-to-fridge')));

      final spinach = findInFridge(container, 'Spinach')!;
      expect(spinach.shelf, ShelfCategory.vegetableDrawer);
      expect(spinach.expiresOn, DateTime(2026, 11, 20));
      expect(find.text('My Fridge'), findsOneWidget);
      expect(find.text('14 items'), findsOneWidget);
      expect(onShelf(ShelfCategory.vegetableDrawer, 'Spinach'), findsOneWidget);
      expect(find.text('Spinach added to Vegetable drawer'), findsOneWidget);
    });

    testWidgets('shelf can be overridden and unknown items have no expiry',
        (tester) async {
      final container = await pumpAt(tester, '/fridge/add');

      await tester.enterText(
        find.byKey(const Key('ingredient-input')),
        'homemade pesto',
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('expiry-estimate')), findsNothing);
      await tapVisible(
        tester,
        find.byKey(const Key('shelf-choice-meatAndLeftovers')),
      );
      await tapVisible(tester, find.byKey(const Key('add-to-fridge')));

      final pesto = findInFridge(container, 'Homemade pesto')!;
      expect(pesto.shelf, ShelfCategory.meatAndLeftovers);
      expect(pesto.expiresOn, isNull);
      expect(
        onShelf(ShelfCategory.meatAndLeftovers, 'Homemade pesto'),
        findsOneWidget,
      );
    });
  });

  group('5. Check what we found', () {
    testWidgets('photo card opens the checklist with mock detections',
        (tester) async {
      await pumpAt(tester, '/fridge/add');
      await tester.tap(find.text('Take a photo'));
      await tester.pumpAndSettle();

      expect(find.text('Check what we found'), findsOneWidget);
      expect(find.byKey(const Key('scan-preview')), findsOneWidget);
      expect(
        find.text('5 ingredients found. Untick anything that is wrong.'),
        findsOneWidget,
      );
      for (final name in [
        'Cucumber',
        'Spinach',
        'Feta cheese',
        'Garlic',
        'Zucchini',
      ]) {
        expect(find.text(name), findsOneWidget);
      }
      expect(find.text('Dairy'), findsOneWidget);
      expect(find.text('Vegetable drawer'), findsNWidgets(3));
      expect(find.text('Not added'), findsOneWidget);
      expect(find.text('Save 4 to my fridge'), findsOneWidget);
    });

    testWidgets('untick, add missed, change shelf and save', (tester) async {
      final container = await pumpAt(tester, '/fridge/add/scan?source=photo');

      // Untick garlic, tick zucchini back on.
      await toggleRow(tester, 'Garlic');
      expect(find.text('Save 3 to my fridge'), findsOneWidget);
      expect(find.text('Not added'), findsNWidgets(2));
      await toggleRow(tester, 'Zucchini');

      // Add something the scanner missed.
      final missed = find.byKey(const Key('scan-missed-input'));
      await tester.ensureVisible(missed);
      await tester.enterText(missed, 'kefir');
      await tapVisible(tester, find.byKey(const Key('scan-missed-add')));
      expect(find.text('Kefir'), findsOneWidget);
      expect(find.text('Save 5 to my fridge'), findsOneWidget);

      // Move spinach to the meat shelf.
      await tapVisible(tester, find.byKey(const Key('scan-shelf-Spinach')));
      await tester.tap(find.text('Meat and leftovers').last);
      await tester.pumpAndSettle();

      await tapVisible(tester, find.byKey(const Key('scan-save')));

      expect(find.text('My Fridge'), findsOneWidget);
      expect(find.text('18 items'), findsOneWidget);
      expect(find.text('5 items added to your fridge'), findsOneWidget);
      expect(findInFridge(container, 'Garlic'), isNull);
      expect(findInFridge(container, 'Kefir')!.shelf, ShelfCategory.dairy);
      expect(
        findInFridge(container, 'Spinach')!.shelf,
        ShelfCategory.meatAndLeftovers,
      );
      expect(onShelf(ShelfCategory.dairy, 'Feta cheese'), findsOneWidget);
      expect(onShelf(ShelfCategory.vegetableDrawer, 'Zucchini'), findsOneWidget);

      final ids = container.read(fridgeProvider).map((i) => i.id).toList();
      expect(ids.toSet().length, ids.length);
    });

    testWidgets('receipt scan has its own items and empty selection disables '
        'save', (tester) async {
      await pumpAt(tester, '/fridge/add/scan?source=receipt');

      expect(find.text('Receipt scan'), findsOneWidget);
      expect(find.text('Ground beef'), findsOneWidget);
      expect(find.text('Meat and leftovers'), findsOneWidget);

      for (final name in ['Milk', 'Cucumber', 'Ground beef', 'Kefir']) {
        await toggleRow(tester, name);
      }

      expect(find.text('Save 0 to my fridge'), findsOneWidget);
      final button =
          tester.widget<FilledButton>(find.byKey(const Key('scan-save')));
      expect(button.onPressed, isNull);
    });
  });
}
