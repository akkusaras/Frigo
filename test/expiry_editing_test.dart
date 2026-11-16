// Covers editing the expiry date of an existing fridge item: the
// `FridgeNotifier.updateExpiry` state change, its immediate persistence
// through `FridgeRepository` / `shared_preferences`, and the item sheet's
// quick day-offset chips, date picker and "No expiry" action.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frigo/app.dart';
import 'package:frigo/core/persistence/local_store.dart';
import 'package:frigo/core/router/app_router.dart';
import 'package:frigo/data/repositories/fridge_repository.dart';
import 'package:frigo/providers/fridge_provider.dart';
import 'package:frigo/providers/repository_providers.dart';
import 'package:frigo/providers/router_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

final _today = DateTime(2026, 11, 15, 9);

/// A fresh `SharedPreferences` instance over the same mock backing store
/// stands in for "the app restarted".
Future<LocalStore> _restart() async =>
    SharedPreferencesLocalStore(await SharedPreferences.getInstance());

ProviderContainer _container(LocalStore store) {
  final container = ProviderContainer(
    overrides: [
      clockProvider.overrideWithValue(() => _today),
      localStoreProvider.overrideWithValue(store),
      routerProvider.overrideWithValue(
        createAppRouter(initialLocation: '/fridge'),
      ),
    ],
  );
  addTearDown(container.dispose);
  return container;
}

DateTime? _expiryOf(ProviderContainer container, String id) =>
    container.read(fridgeProvider).firstWhere((i) => i.id == id).expiresOn;

Future<ProviderContainer> _pumpFridge(
  WidgetTester tester,
  LocalStore store,
) async {
  tester.view.physicalSize = const Size(1080, 2340);
  tester.view.devicePixelRatio = 2.75;
  addTearDown(tester.view.reset);
  final container = _container(store);
  await tester.pumpWidget(
    UncontrolledProviderScope(container: container, child: const FrigoApp()),
  );
  await tester.pumpAndSettle();
  return container;
}

Finder _onTile(String id, String text) => find.descendant(
  of: find.byKey(Key('fridge-item-$id')),
  matching: find.text(text),
);

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('FridgeNotifier.updateExpiry', () {
    test('changes only the target item and drops the time of day', () {
      final container = _container(InMemoryLocalStore());
      final before = container.read(fridgeProvider);

      container
          .read(fridgeProvider.notifier)
          .updateExpiry('ing-sea-bass', DateTime(2026, 11, 22, 18, 45));

      final after = container.read(fridgeProvider);
      expect(_expiryOf(container, 'ing-sea-bass'), DateTime(2026, 11, 22));
      expect(after, hasLength(before.length));
      for (final (i, item) in after.indexed) {
        if (item.id != 'ing-sea-bass') expect(item, before[i]);
      }
    });

    test('null clears the expiry date', () {
      final container = _container(InMemoryLocalStore());
      container.read(fridgeProvider.notifier).updateExpiry('ing-yogurt', null);
      expect(_expiryOf(container, 'ing-yogurt'), isNull);
    });

    test('unknown ids are ignored and nothing is written', () {
      final store = InMemoryLocalStore();
      final container = _container(store);
      final before = container.read(fridgeProvider);
      final saved = store.getString('frigo.fridge.ingredients.v1');

      container
          .read(fridgeProvider.notifier)
          .updateExpiry('ing-missing', DateTime(2026, 12, 1));

      expect(identical(container.read(fridgeProvider), before), isTrue);
      expect(store.getString('frigo.fridge.ingredients.v1'), saved);
    });

    test('writes through FridgeRepository immediately', () {
      final store = InMemoryLocalStore();
      final container = _container(store);
      container
          .read(fridgeProvider.notifier)
          .updateExpiry('ing-milk', DateTime(2026, 11, 30));

      final persisted = PersistentFridgeRepository(
        store,
        today: _today,
      ).loadIngredients().firstWhere((i) => i.id == 'ing-milk');
      expect(persisted.expiresOn, DateTime(2026, 11, 30));
    });

    test('edited and cleared dates survive an app restart', () async {
      final first = _container(await _restart());
      first.read(fridgeProvider.notifier)
        ..updateExpiry('ing-sea-bass', DateTime(2026, 11, 25))
        ..updateExpiry('ing-yogurt', null);

      final second = _container(await _restart());
      expect(_expiryOf(second, 'ing-sea-bass'), DateTime(2026, 11, 25));
      expect(_expiryOf(second, 'ing-yogurt'), isNull);
      expect(second.read(fridgeProvider), hasLength(13));
    });
  });

  group('Item sheet expiry editing', () {
    testWidgets('quick offset updates the sheet, tile badge and banner', (
      tester,
    ) async {
      final container = await _pumpFridge(tester, InMemoryLocalStore());
      expect(_onTile('ing-sea-bass', '1d'), findsOneWidget);

      await tester.tap(find.text('Sea bass'));
      await tester.pumpAndSettle();
      expect(find.text('CHANGE EXPIRY DATE'), findsOneWidget);
      expect(find.textContaining('Expires tomorrow'), findsOneWidget);

      await tester.tap(find.byKey(const Key('expiry-offset-7')));
      await tester.pumpAndSettle();

      // The sheet stays open and reflects the new date in place.
      expect(find.textContaining('Expires in 7 days'), findsOneWidget);
      expect(find.textContaining('22 Nov'), findsOneWidget);
      expect(_expiryOf(container, 'ing-sea-bass'), DateTime(2026, 11, 22));

      Navigator.of(tester.element(find.text('CHANGE EXPIRY DATE'))).pop();
      await tester.pumpAndSettle();
      expect(_onTile('ing-sea-bass', '1d'), findsNothing);
      expect(
        find.text('Yogurt expires soon. Try cacık today.'),
        findsOneWidget,
      );
    });

    testWidgets('"Today" marks a far-off item as expiring', (tester) async {
      await _pumpFridge(tester, InMemoryLocalStore());

      await tester.tap(find.text('Butter'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('expiry-offset-0')));
      await tester.pumpAndSettle();
      expect(find.textContaining('Expires today'), findsOneWidget);

      Navigator.of(tester.element(find.text('CHANGE EXPIRY DATE'))).pop();
      await tester.pumpAndSettle();
      expect(_onTile('ing-butter', '0d'), findsOneWidget);
    });

    testWidgets('date picker sets an exact date', (tester) async {
      final container = await _pumpFridge(tester, InMemoryLocalStore());

      await tester.tap(find.text('Sea bass'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('expiry-pick-date')));
      await tester.pumpAndSettle();

      expect(find.text('Expiry date'), findsOneWidget);
      await tester.tap(
        find.descendant(of: find.byType(Dialog), matching: find.text('28')),
      );
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(_expiryOf(container, 'ing-sea-bass'), DateTime(2026, 11, 28));
      expect(find.textContaining('Expires in 13 days'), findsOneWidget);
    });

    testWidgets('tapping the expiry line also opens the picker; cancel keeps '
        'the date', (tester) async {
      final container = await _pumpFridge(tester, InMemoryLocalStore());
      final original = _expiryOf(container, 'ing-yogurt');

      await tester.tap(find.text('Yogurt'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('expiry-edit')));
      await tester.pumpAndSettle();
      expect(find.byType(DatePickerDialog), findsOneWidget);

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(_expiryOf(container, 'ing-yogurt'), original);
    });

    testWidgets('"No expiry" clears the date and hides the chip', (
      tester,
    ) async {
      final container = await _pumpFridge(tester, InMemoryLocalStore());

      await tester.tap(find.text('Yogurt'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('expiry-clear')));
      await tester.pumpAndSettle();

      expect(find.text('No expiry date'), findsOneWidget);
      expect(find.byKey(const Key('expiry-clear')), findsNothing);
      expect(_expiryOf(container, 'ing-yogurt'), isNull);
    });

    testWidgets('an edit made in the UI survives an app restart', (
      tester,
    ) async {
      await _pumpFridge(tester, await _restart());
      await tester.tap(find.text('Sea bass'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('expiry-offset-3')));
      await tester.pumpAndSettle();

      // Tear the app down and boot it again over the same stored prefs.
      await tester.pumpWidget(const SizedBox());
      final relaunched = await _pumpFridge(tester, await _restart());

      expect(_expiryOf(relaunched, 'ing-sea-bass'), DateTime(2026, 11, 18));
      expect(_onTile('ing-sea-bass', '1d'), findsNothing);
      expect(
        find.text('Yogurt expires soon. Try cacık today.'),
        findsOneWidget,
      );
    });
  });
}
