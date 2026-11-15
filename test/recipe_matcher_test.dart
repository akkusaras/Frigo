import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frigo/data/seed/seed_data.dart';
import 'package:frigo/data/services/recipe_matcher.dart';
import 'package:frigo/models/models.dart';
import 'package:frigo/providers/service_providers.dart';

void main() {
  final now = DateTime(2026, 11, 15, 9, 30);
  const matcher = RecipeMatcher();

  DateTime inDays(int d) => DateTime(now.year, now.month, now.day + d);

  Ingredient fridgeItem(String name, {int? expiresIn}) => Ingredient(
    id: 'ing-$name',
    name: name,
    shelf: ShelfCategory.vegetableDrawer,
    expiresOn: expiresIn == null ? null : inDays(expiresIn),
  );

  Recipe recipe(
    String id,
    List<RecipeIngredient> ingredients, {
    int minutes = 15,
  }) => Recipe(
    id: id,
    title: id,
    cookTime: Duration(minutes: minutes),
    ingredients: ingredients,
    steps: const [
      RecipeStep(instruction: 'Cook.', duration: Duration(minutes: 1)),
    ],
  );

  RecipeIngredient line(
    String name, {
    Set<Allergen> allergens = const {},
    Set<IngredientTrait> traits = const {},
    bool staple = false,
  }) => RecipeIngredient(
    name: name,
    amount: '1',
    allergens: allergens,
    traits: traits,
    isPantryStaple: staple,
  );

  UserProfile profile({
    Set<Allergen> allergies = const {},
    List<String> custom = const [],
    Diet diet = Diet.none,
  }) => UserProfile(
    name: 'Test User',
    email: 't@example.com',
    allergies: allergies,
    customAllergies: custom,
    diet: diet,
  );

  group('seed data', () {
    final result = matcher.match(
      recipes: SeedData.recipes,
      fridge: SeedData.fridgeIngredients(now),
      profile: SeedData.userProfile,
      now: now,
    );

    test('hides both peanut recipes for the peanut-allergic seed user', () {
      expect(
        result.hiddenByAllergy.map((h) => h.recipe.id),
        unorderedEquals(['peanut-noodle-salad', 'chicken-satay']),
      );
      expect(result.hiddenAllergenCount, 2);
      expect(result.hiddenCountByAllergy, {'peanuts': 2});
      expect(
        result.hiddenAllergySummary,
        'Hidden: 2 recipes with peanuts (your allergy)',
      );
      expect(result.hiddenDietSummary, isNull);
      expect(
        result.matches.map((m) => m.recipe.id),
        isNot(contains('chicken-satay')),
      );
    });

    test('ranks full and expiring matches first', () {
      expect(result.matches.map((m) => m.recipe.id), [
        'baked-sea-bass',
        'menemen',
        'chicken-saute',
        'lentil-soup',
        'pasta-with-yogurt',
        'cacik',
        'rice-pudding',
      ]);
    });

    test('produces mockup match labels and expiry notes', () {
      final seaBass = result.matchFor('baked-sea-bass')!;
      expect(seaBass.matchPercent, 100);
      expect(seaBass.matchLabel, '100% match');
      expect(seaBass.usesExpiring, isTrue);
      expect(seaBass.expiryNote, 'Uses sea bass – expires in 1 day');

      final saute = result.matchFor('chicken-saute')!;
      expect(saute.matchPercent, 80);
      expect(saute.matchLabel, '80% match – missing garlic');
      expect(saute.missingNames, ['Garlic']);
      expect(saute.expiryNote, isNull);

      final cacik = result.matchFor('cacik')!;
      expect(cacik.matchPercent, 25);
      expect(cacik.expiryNote, 'Uses yogurt – expires in 2 days');
      expect(cacik.missingNames, ['Cucumber', 'Garlic', 'Dried mint']);
      expect(cacik.matchLabel, '25% match – missing cucumber, garlic +1');
    });

    test('pantry staples never count as missing', () {
      final menemen = result.matchFor('menemen')!;
      expect(menemen.totalKeyIngredients, 4);
      expect(menemen.missing, isEmpty);
      expect(menemen.isFullMatch, isTrue);
    });
  });

  group('allergies', () {
    final peanutSalad = recipe('peanut-salad', [
      line('Peanut butter', allergens: {Allergen.peanuts}),
      line('Carrot'),
    ]);
    final fishBake = recipe('fish-bake', [
      line('Sea bass', allergens: {Allergen.fish}),
    ]);
    final yogurtDip = recipe('yogurt-dip', [
      line('Yogurt', allergens: {Allergen.milk}),
    ]);
    final salad = recipe('salad', [line('Carrot'), line('Tomato')]);

    test('a recipe with any user allergen is never suggested', () {
      final result = matcher.match(
        recipes: [peanutSalad, fishBake, salad],
        fridge: [fridgeItem('Carrot'), fridgeItem('Sea bass')],
        profile: profile(allergies: {Allergen.peanuts, Allergen.fish}),
        now: now,
      );
      expect(result.matches.map((m) => m.recipe.id), ['salad']);
      expect(result.hiddenCountByAllergy, {'peanuts': 1, 'fish': 1});
      expect(
        result.hiddenAllergySummary,
        'Hidden: 2 recipes with fish or peanuts (your allergies)',
      );
    });

    test('custom allergies match by ingredient name and synonyms', () {
      final result = matcher.match(
        recipes: [peanutSalad, yogurtDip, salad],
        fridge: const [],
        profile: profile(custom: ['Lactose', '  CARROTS ']),
        now: now,
      );
      expect(result.matches, isEmpty);
      final byId = {for (final h in result.hidden) h.recipe.id: h.triggers};
      expect(byId['yogurt-dip'], {'lactose'});
      expect(byId['peanut-salad'], {'carrots'});
      expect(byId['salad'], {'carrots'});
    });

    test('custom term does not match unrelated substrings', () {
      final triggers = matcher.allergyTriggers(
        recipe('pine', [line('Pineapple')]),
        allergies: const {},
        customAllergies: ['pine'],
      );
      expect(triggers, isEmpty);
    });

    test('summary uses singular for one hidden recipe', () {
      final result = matcher.match(
        recipes: [peanutSalad, salad],
        fridge: const [],
        profile: profile(allergies: {Allergen.peanuts}),
        now: now,
      );
      expect(
        result.hiddenAllergySummary,
        'Hidden: 1 recipe with peanuts (your allergy)',
      );
    });

    test('no allergy hides gives no summary', () {
      final result = matcher.match(
        recipes: [salad],
        fridge: const [],
        profile: profile(),
        now: now,
      );
      expect(result.hiddenAllergySummary, isNull);
      expect(result.hiddenAllergenCount, 0);
    });
  });

  group('diet rules', () {
    final chicken = recipe('chicken', [
      line('Chicken', traits: {IngredientTrait.poultry}),
    ]);
    final omelette = recipe('omelette', [
      line('Eggs', traits: {IngredientTrait.egg}),
    ]);
    final porkStew = recipe('pork-stew', [
      line('Pork', traits: {IngredientTrait.pork}),
    ]);
    final wineRisotto = recipe('wine-risotto', [
      line('Rice'),
      line('White wine', traits: {IngredientTrait.alcohol}),
    ]);
    final salad = recipe('salad', [line('Tomato')]);
    final all = [chicken, omelette, porkStew, wineRisotto, salad];

    List<String> visible(Diet diet) =>
        matcher
            .match(
              recipes: all,
              fridge: const [],
              profile: profile(diet: diet),
              now: now,
            )
            .matches
            .map((m) => m.recipe.id)
            .toList()
          ..sort();

    test('none allows everything', () {
      expect(visible(Diet.none), hasLength(5));
    });

    test('vegetarian removes meat, poultry and pork', () {
      expect(visible(Diet.vegetarian), ['omelette', 'salad', 'wine-risotto']);
    });

    test('vegan also removes eggs and dairy', () {
      expect(visible(Diet.vegan), ['salad', 'wine-risotto']);
    });

    test('halal removes pork and alcohol', () {
      expect(visible(Diet.halal), ['chicken', 'omelette', 'salad']);
    });

    test('diet hides are reported separately from allergy hides', () {
      final result = matcher.match(
        recipes: all,
        fridge: const [],
        profile: profile(diet: Diet.vegetarian),
        now: now,
      );
      expect(result.hiddenAllergenCount, 0);
      expect(result.hiddenByDiet, hasLength(2));
      expect(
        result.hiddenDietSummary,
        'Hidden: 2 recipes that are not vegetarian',
      );
    });

    test('allergy wins over diet when both apply', () {
      final result = matcher.match(
        recipes: [
          recipe('satay', [
            line('Chicken', traits: {IngredientTrait.poultry}),
            line('Peanuts', allergens: {Allergen.peanuts}),
          ]),
        ],
        fridge: const [],
        profile: profile(allergies: {Allergen.peanuts}, diet: Diet.vegan),
        now: now,
      );
      expect(result.hidden.single.reason, HiddenReason.allergy);
      expect(result.hiddenDietSummary, isNull);
    });
  });

  group('match percentage', () {
    test('counts only key ingredients and rounds', () {
      final r = recipe('soup', [
        line('Onion'),
        line('Carrot'),
        line('Celery'),
        line('Salt', staple: true),
      ]);
      final m = matcher.scoreRecipe(r, [
        fridgeItem('Onion'),
        fridgeItem('Carrot'),
      ], now);
      expect(m.matchPercent, 67);
      expect(m.missingNames, ['Celery']);
      expect(m.matchLabel, '67% match – missing celery');
    });

    test('recipe of only staples is a full match', () {
      final m = matcher.scoreRecipe(
        recipe('water', [line('Water', staple: true)]),
        const [],
        now,
      );
      expect(m.matchPercent, 100);
      expect(m.isFullMatch, isTrue);
    });

    test('names match ignoring case, plurals and qualifiers', () {
      expect(RecipeMatcher.ingredientMatches('tomatoes', 'Tomato'), isTrue);
      expect(RecipeMatcher.ingredientMatches('EGGS', 'Egg'), isTrue);
      expect(
        RecipeMatcher.ingredientMatches('Spinach, frozen', 'Spinach'),
        isTrue,
      );
      expect(RecipeMatcher.ingredientMatches('Sea bass', 'sea  bass'), isTrue);
      expect(
        RecipeMatcher.ingredientMatches('Lentil soup', 'Red lentils'),
        isFalse,
      );
    });

    test('expired fridge items do not count as available', () {
      final result = matcher.match(
        recipes: [
          recipe('dip', [line('Yogurt')]),
        ],
        fridge: [fridgeItem('Yogurt', expiresIn: -1)],
        profile: profile(),
        now: now,
      );
      expect(result.matches.single.matchPercent, 0);
      expect(result.matches.single.usesExpiring, isFalse);
    });

    test('uses the soonest-expiring duplicate first', () {
      final m = matcher.scoreRecipe(recipe('dip', [line('Yogurt')]), [
        fridgeItem('Yogurt', expiresIn: 9),
        fridgeItem('yogurt', expiresIn: 1),
      ], now);
      expect(
        m.expiringUses.single,
        const ExpiringUse(name: 'yogurt', daysLeft: 1),
      );
    });
  });

  group('expiry prioritisation', () {
    test('expiring ingredients boost a recipe above a fresher equal match', () {
      final fresh = recipe('fresh', [line('Carrot')], minutes: 5);
      final urgent = recipe('urgent', [line('Sea bass')], minutes: 30);
      final result = matcher.match(
        recipes: [fresh, urgent],
        fridge: [
          fridgeItem('Carrot', expiresIn: 10),
          fridgeItem('Sea bass', expiresIn: 1),
        ],
        profile: profile(),
        now: now,
      );
      expect(result.matches.map((m) => m.recipe.id), ['urgent', 'fresh']);
      expect(result.matches.first.priorityScore, 120);
      expect(result.matches.last.priorityScore, 100);
    });

    test('a partial match using expiring food beats a slightly better one', () {
      final usesYogurt = recipe('a', [line('Yogurt'), line('Cucumber')]);
      final noExpiry = recipe('b', [
        line('Carrot'),
        line('Onion'),
        line('Leek'),
      ]);
      final result = matcher.match(
        recipes: [noExpiry, usesYogurt],
        fridge: [
          fridgeItem('Yogurt', expiresIn: 2),
          fridgeItem('Carrot'),
          fridgeItem('Onion'),
        ],
        profile: profile(),
        now: now,
      );
      // a: 50% + 20 bonus = 70 > b: 67%
      expect(result.matches.map((m) => m.recipe.id), ['a', 'b']);
    });

    test('ties break by urgency, then cook time, then title', () {
      final result = matcher.match(
        recipes: [
          recipe('slow', [line('Milk')], minutes: 40),
          recipe('quick', [line('Milk')], minutes: 10),
          recipe('b-same', [line('Milk')], minutes: 10),
        ],
        fridge: [fridgeItem('Milk')],
        profile: profile(),
        now: now,
      );
      expect(result.matches.map((m) => m.recipe.id), [
        'b-same',
        'quick',
        'slow',
      ]);
    });

    test('expiry note covers today and lists every expiring item', () {
      final m = matcher.scoreRecipe(
        recipe('bake', [line('Sea bass'), line('Yogurt')]),
        [
          fridgeItem('Yogurt', expiresIn: 2),
          fridgeItem('Sea bass', expiresIn: 0),
        ],
        now,
      );
      expect(m.mostUrgentDaysLeft, 0);
      expect(m.expiryNote, 'Uses sea bass and yogurt – expires today');
    });

    test('bonus is configurable', () {
      const noBonus = RecipeMatcher(expiringBonus: 0);
      final m = noBonus.scoreRecipe(recipe('dip', [line('Yogurt')]), [
        fridgeItem('Yogurt', expiresIn: 1),
      ], now);
      expect(m.priorityScore, 100);
    });
  });

  test('recipeMatcherProvider exposes the engine', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    expect(container.read(recipeMatcherProvider), isA<RecipeMatcher>());
  });
}
