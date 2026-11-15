import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frigo/data/repositories/fridge_repository.dart';
import 'package:frigo/data/repositories/profile_repository.dart';
import 'package:frigo/data/repositories/recipe_repository.dart';
import 'package:frigo/data/repositories/shopping_repository.dart';
import 'package:frigo/data/seed/seed_data.dart';
import 'package:frigo/models/models.dart';
import 'package:frigo/providers/repository_providers.dart';

void main() {
  final today = DateTime(2026, 11, 15, 9, 30);

  group('Ingredient', () {
    Ingredient item(int? inDays) => Ingredient(
          id: 'x',
          name: '  Sea   Bass ',
          shelf: ShelfCategory.meatAndLeftovers,
          expiresOn: inDays == null
              ? null
              : DateTime(today.year, today.month, today.day + inDays),
        );

    test('computes days until expiry and badges', () {
      expect(item(1).daysUntilExpiry(today), 1);
      expect(item(1).expiryBadge(today), '1d');
      expect(item(2).expiryBadge(today), '2d');
      expect(item(3).isExpiringSoon(today), isFalse);
      expect(item(3).expiryBadge(today), isNull);
      expect(item(-1).isExpired(today), isTrue);
      expect(item(-1).expiryBadge(today), 'expired');
      expect(item(null).daysUntilExpiry(today), isNull);
      expect(item(null).isExpiringSoon(today), isFalse);
    });

    test('normalises names and supports value equality / copyWith', () {
      expect(item(1).normalizedName, 'sea bass');
      expect(item(1), item(1));
      expect(item(1).hashCode, item(1).hashCode);
      final moved = item(1).copyWith(shelf: ShelfCategory.dairy);
      expect(moved.shelf, ShelfCategory.dairy);
      expect(moved.name, item(1).name);
      expect(item(1).copyWith(clearExpiresOn: true).expiresOn, isNull);
    });
  });

  group('Diet rules', () {
    test('vegetarian, vegan and halal forbid the right traits', () {
      expect(Diet.none.allows({IngredientTrait.pork}), isTrue);
      expect(Diet.vegetarian.allows({IngredientTrait.dairy}), isTrue);
      expect(Diet.vegetarian.allows({IngredientTrait.fish}), isFalse);
      expect(Diet.vegan.allows({IngredientTrait.egg}), isFalse);
      expect(Diet.halal.allows({IngredientTrait.poultry}), isTrue);
      expect(Diet.halal.allows({IngredientTrait.alcohol}), isFalse);
    });

    test('allergen chips match the Allergies and diet screen', () {
      expect(Allergen.values.map((a) => a.label), [
        'Peanuts',
        'Tree nuts',
        'Milk',
        'Eggs',
        'Gluten',
        'Fish',
        'Shellfish',
        'Soy',
        'Sesame',
      ]);
      expect(Diet.values.map((d) => d.label),
          ['None', 'Vegetarian', 'Vegan', 'Halal']);
    });
  });

  group('Models are immutable', () {
    test('collections cannot be mutated', () {
      final recipe = SeedData.recipes.first;
      expect(() => recipe.ingredients.add(recipe.ingredients.first),
          throwsUnsupportedError);
      expect(() => recipe.steps.clear(), throwsUnsupportedError);
      expect(() => SeedData.userProfile.favoriteRecipeIds.add('x'),
          throwsUnsupportedError);
      expect(() => SeedData.shoppingNotes.first.items.clear(),
          throwsUnsupportedError);
    });
  });

  group('Seed data', () {
    test('fridge holds the 13 mockup items across 3 shelves', () {
      final items = SeedData.fridgeIngredients(today);
      expect(items, hasLength(13));
      expect(items.map((i) => i.id).toSet(), hasLength(13));
      for (final name in [
        'Milk',
        'Cheese',
        'Eggs',
        'Yogurt',
        'Chicken',
        'Sea bass',
        'Lentil soup',
        'Tomato',
        'Pepper',
        'Carrot',
        'Lemon',
      ]) {
        expect(items.any((i) => i.name == name), isTrue, reason: name);
      }
      final byShelf = {for (final s in ShelfCategory.values) s: 0};
      for (final i in items) {
        byShelf[i.shelf] = byShelf[i.shelf]! + 1;
      }
      expect(byShelf.values.every((n) => n > 0), isTrue);
    });

    test('only yogurt (2d) and sea bass (1d) are expiring soon', () {
      final expiring = {
        for (final i in SeedData.fridgeIngredients(today))
          if (i.isExpiringSoon(today)) i.name: i.expiryBadge(today),
      };
      expect(expiring, {'Yogurt': '2d', 'Sea bass': '1d'});
    });

    test('recipes cover the mockup catalogue with timed steps', () {
      final titles = SeedData.recipes.map((r) => r.title).toList();
      expect(
        titles,
        containsAll([
          'Menemen',
          'Cacık',
          'Chicken sauté',
          'Baked sea bass',
          'Lentil soup',
          'Pasta with yogurt',
          'Rice pudding',
        ]),
      );
      expect(SeedData.recipes.map((r) => r.id).toSet(),
          hasLength(SeedData.recipes.length));
      for (final r in SeedData.recipes) {
        expect(r.id, matches(RegExp(r'^[a-z0-9-]+$')));
        expect(r.steps, isNotEmpty, reason: r.id);
        expect(r.keyIngredients, isNotEmpty, reason: r.id);
        expect(r.steps.every((s) => s.duration > Duration.zero), isTrue);
      }
    });

    test('exactly two recipes contain peanuts', () {
      final peanut = SeedData.recipes
          .where((r) => r.allergens.contains(Allergen.peanuts))
          .toList();
      expect(peanut, hasLength(2));
    });

    test('recipe helpers derive traits and diet fit', () {
      final repo = InMemoryRecipeRepository();
      expect(repo.findById('menemen')!.isVegetarian, isTrue);
      expect(repo.findById('baked-sea-bass')!.isVegetarian, isFalse);
      expect(repo.findById('cacik')!.fitsDiet(Diet.vegan), isFalse);
      expect(repo.findById('cacik')!.allergens, {Allergen.milk});
      expect(repo.findById('nope'), isNull);
    });

    test('user profile matches the Profile mockup', () {
      final p = SeedData.userProfile;
      expect(p.name, 'Elif Yılmaz');
      expect(p.email, 'elif@example.com');
      expect(p.initials, 'EY');
      expect(p.allergyLabels, contains('Peanuts'));
      expect(p.favoritesCount, 4);
      expect(p.mealsCooked, 15);
      expect(p.timesCooked('menemen'), 6);
      expect(p.isFavorite('baked-sea-bass'), isTrue);
      final updated = p.copyWith(diet: Diet.vegetarian);
      expect(updated.diet, Diet.vegetarian);
      expect(updated, isNot(p));
      expect(p.copyWith(), p);
    });

    test('shopping notes match the fridge door mockup', () {
      final notes = SeedData.shoppingNotes;
      expect(notes.map((n) => n.title), ['For cacık', 'Weekly']);
      expect(notes.first.color, NoteColor.yellow);
      expect(notes.last.color, NoteColor.pink);
      expect(notes.first.items.map((i) => i.name),
          ['Cucumber', 'Garlic', 'Dried mint']);
      expect(notes.last.items.map((i) => i.name), ['Milk', 'Bread']);
      final checked = notes.first.copyWith(items: [
        notes.first.items.first.copyWith(isChecked: true),
        ...notes.first.items.skip(1),
      ]);
      expect(checked.openItemCount, 2);
      expect(checked.recipeId, 'cacik');
    });
  });

  group('Repositories', () {
    test('in-memory repositories load seed data and persist saves', () {
      final fridge = InMemoryFridgeRepository(today: today);
      expect(fridge.loadIngredients(), hasLength(13));
      fridge.saveIngredients(fridge.loadIngredients().take(2).toList());
      expect(fridge.loadIngredients(), hasLength(2));

      final profile = InMemoryProfileRepository();
      profile.saveProfile(profile.loadProfile().copyWith(itemsSaved: 1));
      expect(profile.loadProfile().itemsSaved, 1);

      final shopping = InMemoryShoppingRepository();
      shopping.saveNotes(const []);
      expect(shopping.loadNotes(), isEmpty);
    });

    test('providers expose the repositories with an overridable clock', () {
      final container = ProviderContainer(
        overrides: [clockProvider.overrideWithValue(() => today)],
      );
      addTearDown(container.dispose);

      final items = container.read(fridgeRepositoryProvider).loadIngredients();
      expect(items.firstWhere((i) => i.name == 'Sea bass').expiryBadge(today),
          '1d');
      expect(container.read(recipeRepositoryProvider).loadRecipes(),
          SeedData.recipes);
      expect(container.read(profileRepositoryProvider).loadProfile().initials,
          'EY');
      expect(container.read(shoppingRepositoryProvider).loadNotes(),
          hasLength(2));
    });
  });
}
