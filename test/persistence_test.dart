// Verifies Phase 1 local persistence: repositories backed by a real
// `SharedPreferences` instance keep the fridge, shopping list and profile
// across what simulates an app restart (a fresh `SharedPreferences`
// instance reading the same mock-backed storage), seed demo data only on
// first launch, and `resetToDemo()` cleanly restores the mockup data.
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frigo/core/persistence/local_store.dart';
import 'package:frigo/data/repositories/fridge_repository.dart';
import 'package:frigo/data/repositories/profile_repository.dart';
import 'package:frigo/data/repositories/shopping_repository.dart';
import 'package:frigo/data/seed/seed_data.dart';
import 'package:frigo/models/models.dart';
import 'package:frigo/providers/fridge_provider.dart';
import 'package:frigo/providers/profile_provider.dart';
import 'package:frigo/providers/repository_providers.dart';
import 'package:frigo/providers/shopping_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

final _today = DateTime(2026, 11, 15, 9);

void main() {
  setUp(() {
    // A clean platform-backed store for every test, as if the app had
    // never been launched before.
    SharedPreferences.setMockInitialValues({});
  });

  /// A fresh `SharedPreferences.getInstance()` call against the same mock
  /// backing store stands in for "the app restarted".
  Future<LocalStore> restart() async =>
      SharedPreferencesLocalStore(await SharedPreferences.getInstance());

  group('InMemoryLocalStore', () {
    test('holds values only for its own lifetime', () {
      final store = InMemoryLocalStore();
      expect(store.getString('k'), isNull);
      store.setString('k', 'v');
      expect(store.getString('k'), 'v');
      store.remove('k');
      expect(store.getString('k'), isNull);
    });
  });

  group('PersistentFridgeRepository', () {
    test('seeds the demo fridge only on first launch', () async {
      final repo = PersistentFridgeRepository(await restart(), today: _today);
      expect(repo.loadIngredients(), hasLength(13));

      // Calling load again must not re-seed or duplicate anything.
      expect(repo.loadIngredients(), hasLength(13));
    });

    test('added ingredients and expiry dates survive a restart', () async {
      final store = await restart();
      final first = PersistentFridgeRepository(store, today: _today);
      first.loadIngredients(); // first launch: seeds.
      first.saveIngredients([
        ...first.loadIngredients(),
        Ingredient(
          id: 'ing-garlic',
          name: 'Garlic',
          shelf: ShelfCategory.vegetableDrawer,
          expiresOn: DateTime(2026, 11, 20),
        ),
      ]);

      // Simulate a restart: a brand new repository over a fresh prefs
      // instance pointed at the same backing store.
      final second = PersistentFridgeRepository(
        await restart(),
        today: _today,
      );
      final reloaded = second.loadIngredients();
      expect(reloaded, hasLength(14));
      final garlic = reloaded.firstWhere((i) => i.name == 'Garlic');
      expect(garlic.shelf, ShelfCategory.vegetableDrawer);
      expect(garlic.expiresOn, DateTime(2026, 11, 20));
    });

    test('resetToDemo discards saved state and reseeds', () async {
      final store = await restart();
      final repo = PersistentFridgeRepository(store, today: _today);
      repo.saveIngredients(const []);
      expect(repo.loadIngredients(), isEmpty);

      repo.resetToDemo();
      expect(repo.loadIngredients(), hasLength(13));
    });
  });

  group('PersistentShoppingRepository', () {
    test('checked state survives a restart', () async {
      final store = await restart();
      final first = PersistentShoppingRepository(store);
      final notes = first.loadNotes();
      final cacik = notes.firstWhere((n) => n.id == 'note-cacik');
      first.saveNotes([
        for (final n in notes)
          if (n.id == cacik.id)
            n.copyWith(
              items: [
                for (final item in n.items)
                  item.name == 'Garlic'
                      ? item.copyWith(isChecked: true)
                      : item,
              ],
            )
          else
            n,
      ]);

      final second = PersistentShoppingRepository(await restart());
      final reloaded = second
          .loadNotes()
          .firstWhere((n) => n.id == 'note-cacik');
      expect(
        reloaded.items.firstWhere((i) => i.name == 'Garlic').isChecked,
        isTrue,
      );
    });

    test('resetToDemo restores the two demo notes', () async {
      final store = await restart();
      final repo = PersistentShoppingRepository(store);
      repo.saveNotes(const []);
      repo.resetToDemo();
      expect(repo.loadNotes().map((n) => n.title), ['For cacık', 'Weekly']);
    });
  });

  group('PersistentProfileRepository', () {
    test('allergies, diet, favorites and stats survive a restart', () async {
      final store = await restart();
      final first = PersistentProfileRepository(store);
      final profile = first.loadProfile();
      first.saveProfile(
        profile.copyWith(
          allergies: {...profile.allergies, Allergen.gluten},
          customAllergies: const ['Lactose'],
          diet: Diet.vegetarian,
          favoriteRecipeIds: {...profile.favoriteRecipeIds, 'cacik'},
          cookedCounts: {...profile.cookedCounts, 'cacik': 7},
          itemsSaved: profile.itemsSaved + 1,
        ),
      );

      final second = PersistentProfileRepository(await restart());
      final reloaded = second.loadProfile();
      expect(reloaded.allergies, {Allergen.peanuts, Allergen.gluten});
      expect(reloaded.customAllergies, ['Lactose']);
      expect(reloaded.diet, Diet.vegetarian);
      expect(reloaded.isFavorite('cacik'), isTrue);
      expect(reloaded.timesCooked('cacik'), 7);
      expect(reloaded.itemsSaved, 24);
    });

    test('resetToDemo restores the seed profile', () async {
      final store = await restart();
      final repo = PersistentProfileRepository(store);
      repo.saveProfile(
        repo.loadProfile().copyWith(diet: Diet.vegan, itemsSaved: 0),
      );
      repo.resetToDemo();
      expect(repo.loadProfile(), SeedData.userProfile);
    });
  });

  group('Riverpod notifiers reset to demo data', () {
    test('fridge, shopping list and profile notifiers restore seed state', () {
      final container = ProviderContainer(
        overrides: [
          clockProvider.overrideWithValue(() => _today),
          localStoreProvider.overrideWithValue(InMemoryLocalStore()),
        ],
      );
      addTearDown(container.dispose);

      container.read(fridgeProvider.notifier).remove('ing-milk');
      container.read(shoppingNotesProvider.notifier).removeNote('note-weekly');
      container
          .read(profileProvider.notifier)
          .updateDietary(
            allergies: {Allergen.shellfish},
            customAllergies: const ['Kiwi'],
            diet: Diet.vegan,
          );

      expect(container.read(fridgeProvider), hasLength(12));
      expect(container.read(shoppingNotesProvider), hasLength(1));
      expect(container.read(profileProvider).diet, Diet.vegan);

      container.read(fridgeProvider.notifier).resetToDemo();
      container.read(shoppingNotesProvider.notifier).resetToDemo();
      container.read(profileProvider.notifier).resetToDemo();

      expect(container.read(fridgeProvider), hasLength(13));
      expect(container.read(shoppingNotesProvider), hasLength(2));
      expect(container.read(profileProvider), SeedData.userProfile);
      // The repositories' own saved copy is reset too, not just the
      // in-memory Riverpod state.
      expect(
        container.read(fridgeRepositoryProvider).loadIngredients(),
        hasLength(13),
      );
    });
  });
}
