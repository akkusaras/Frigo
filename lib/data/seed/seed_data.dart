import '../../models/models.dart';

/// Realistic local seed data mirroring the Frigo mockups.
///
/// Expiry dates are relative to [today] so the `1d` / `2d` badges stay
/// meaningful whenever the app is launched.
abstract final class SeedData {
  static DateTime _day(DateTime today, int offset) =>
      DateTime(today.year, today.month, today.day + offset);

  /// The 13 items shown on `2. My Fridge`.
  static List<Ingredient> fridgeIngredients(DateTime today) => [
        // DAIRY
        Ingredient(
          id: 'ing-milk',
          name: 'Milk',
          shelf: ShelfCategory.dairy,
          quantity: '1 L',
          expiresOn: _day(today, 5),
        ),
        Ingredient(
          id: 'ing-cheese',
          name: 'Cheese',
          shelf: ShelfCategory.dairy,
          quantity: '250 g',
          expiresOn: _day(today, 12),
        ),
        Ingredient(
          id: 'ing-eggs',
          name: 'Eggs',
          shelf: ShelfCategory.dairy,
          quantity: '6 pcs',
          expiresOn: _day(today, 10),
        ),
        Ingredient(
          id: 'ing-yogurt',
          name: 'Yogurt',
          shelf: ShelfCategory.dairy,
          quantity: '500 g',
          expiresOn: _day(today, 2),
        ),
        Ingredient(
          id: 'ing-butter',
          name: 'Butter',
          shelf: ShelfCategory.dairy,
          quantity: '200 g',
          expiresOn: _day(today, 20),
        ),
        // MEAT AND LEFTOVERS
        Ingredient(
          id: 'ing-chicken',
          name: 'Chicken',
          shelf: ShelfCategory.meatAndLeftovers,
          quantity: '500 g',
          expiresOn: _day(today, 3),
        ),
        Ingredient(
          id: 'ing-sea-bass',
          name: 'Sea bass',
          shelf: ShelfCategory.meatAndLeftovers,
          quantity: '2 fillets',
          expiresOn: _day(today, 1),
        ),
        Ingredient(
          id: 'ing-lentil-soup',
          name: 'Lentil soup',
          shelf: ShelfCategory.meatAndLeftovers,
          quantity: '2 bowls',
          expiresOn: _day(today, 3),
        ),
        // VEGETABLE DRAWER
        Ingredient(
          id: 'ing-tomato',
          name: 'Tomato',
          shelf: ShelfCategory.vegetableDrawer,
          quantity: '4 pcs',
          expiresOn: _day(today, 5),
        ),
        Ingredient(
          id: 'ing-pepper',
          name: 'Pepper',
          shelf: ShelfCategory.vegetableDrawer,
          quantity: '3 pcs',
          expiresOn: _day(today, 6),
        ),
        Ingredient(
          id: 'ing-carrot',
          name: 'Carrot',
          shelf: ShelfCategory.vegetableDrawer,
          quantity: '5 pcs',
          expiresOn: _day(today, 14),
        ),
        Ingredient(
          id: 'ing-lemon',
          name: 'Lemon',
          shelf: ShelfCategory.vegetableDrawer,
          quantity: '2 pcs',
          expiresOn: _day(today, 9),
        ),
        Ingredient(
          id: 'ing-onion',
          name: 'Onion',
          shelf: ShelfCategory.vegetableDrawer,
          quantity: '3 pcs',
          expiresOn: _day(today, 21),
        ),
      ];

  // Reusable ingredient lines.
  static const _salt = RecipeIngredient(
    name: 'Salt',
    amount: 'to taste',
    isPantryStaple: true,
  );
  static const _oliveOil = RecipeIngredient(
    name: 'Olive oil',
    amount: '2 tbsp',
    isPantryStaple: true,
  );
  static const _garlic = RecipeIngredient(name: 'Garlic', amount: '2 cloves');
  static const _onion = RecipeIngredient(name: 'Onion', amount: '1');
  static const _tomato = RecipeIngredient(name: 'Tomato', amount: '2');
  static const _pepper = RecipeIngredient(name: 'Pepper', amount: '1');
  static const _lemon = RecipeIngredient(name: 'Lemon', amount: '1');
  static const _carrot = RecipeIngredient(name: 'Carrot', amount: '1');
  static const _driedMint = RecipeIngredient(
    name: 'Dried mint',
    amount: '1 tsp',
  );
  static const _yogurt = RecipeIngredient(
    name: 'Yogurt',
    amount: '400 g',
    allergens: {Allergen.milk},
    traits: {IngredientTrait.dairy},
  );
  static const _butter = RecipeIngredient(
    name: 'Butter',
    amount: '1 tbsp',
    allergens: {Allergen.milk},
    traits: {IngredientTrait.dairy},
  );
  static const _chicken = RecipeIngredient(
    name: 'Chicken',
    amount: '400 g',
    traits: {IngredientTrait.poultry},
  );

  static Duration _min(int minutes) => Duration(minutes: minutes);

  /// Recipe catalogue. The two peanut recipes exist so the allergy engine
  /// has something to hide for the seed user (`Hidden: 2 recipes with
  /// peanuts`).
  static final List<Recipe> recipes = [
    Recipe(
      id: 'menemen',
      title: 'Menemen',
      cookTime: _min(15),
      ingredients: const [
        RecipeIngredient(
          name: 'Eggs',
          amount: '3',
          allergens: {Allergen.eggs},
          traits: {IngredientTrait.egg},
        ),
        _tomato,
        _pepper,
        _onion,
        _oliveOil,
        _salt,
      ],
      steps: [
        RecipeStep(
          instruction: 'Dice the onion and pepper, then soften them in olive '
              'oil over medium heat.',
          duration: _min(4),
        ),
        RecipeStep(
          instruction: 'Grate in the tomatoes and simmer until most of the '
              'juice has cooked off.',
          duration: _min(6),
        ),
        RecipeStep(
          instruction: 'Crack in the eggs, stir gently and cook until just '
              'set. Season with salt.',
          duration: _min(3),
        ),
      ],
    ),
    Recipe(
      id: 'cacik',
      title: 'Cacık',
      cookTime: _min(10),
      ingredients: const [
        _yogurt,
        RecipeIngredient(name: 'Cucumber', amount: '1'),
        _garlic,
        _driedMint,
        _oliveOil,
        _salt,
      ],
      steps: [
        RecipeStep(
          instruction: 'Grate the cucumber and squeeze out the excess water.',
          duration: _min(3),
        ),
        RecipeStep(
          instruction: 'Whisk the yogurt with crushed garlic, salt and a '
              'splash of cold water.',
          duration: _min(2),
        ),
        RecipeStep(
          instruction: 'Fold in the cucumber, sprinkle with dried mint and '
              'olive oil, then chill.',
          duration: _min(5),
        ),
      ],
    ),
    Recipe(
      id: 'chicken-saute',
      title: 'Chicken sauté',
      cookTime: _min(25),
      ingredients: const [
        _chicken,
        _pepper,
        _tomato,
        _onion,
        _garlic,
        _oliveOil,
        _salt,
      ],
      steps: [
        RecipeStep(
          instruction: 'Cut the chicken into cubes and sear in a hot pan '
              'until golden.',
          duration: _min(8),
        ),
        RecipeStep(
          instruction: 'Add sliced onion, pepper and garlic; sauté until '
              'soft.',
          duration: _min(5),
        ),
        RecipeStep(
          instruction: 'Stir in chopped tomatoes, cover and simmer until the '
              'chicken is cooked through.',
          duration: _min(12),
        ),
      ],
    ),
    Recipe(
      id: 'baked-sea-bass',
      title: 'Baked sea bass',
      cookTime: _min(30),
      ingredients: const [
        RecipeIngredient(
          name: 'Sea bass',
          amount: '2 fillets',
          allergens: {Allergen.fish},
          traits: {IngredientTrait.fish},
        ),
        _lemon,
        _tomato,
        _pepper,
        _onion,
        _oliveOil,
        _salt,
      ],
      steps: [
        RecipeStep(
          instruction: 'Heat the oven to 200°C and slice the onion, tomato '
              'and pepper into a baking dish.',
          duration: _min(8),
        ),
        RecipeStep(
          instruction: 'Lay the sea bass on top, season, drizzle with olive '
              'oil and add lemon slices.',
          duration: _min(2),
        ),
        RecipeStep(
          instruction: 'Bake until the fish flakes easily.',
          duration: _min(20),
        ),
      ],
    ),
    Recipe(
      id: 'lentil-soup',
      title: 'Lentil soup',
      cookTime: _min(35),
      ingredients: const [
        RecipeIngredient(name: 'Red lentils', amount: '200 g'),
        _onion,
        _carrot,
        _butter,
        _lemon,
        RecipeIngredient(
          name: 'Water',
          amount: '1.2 L',
          isPantryStaple: true,
        ),
        _salt,
      ],
      steps: [
        RecipeStep(
          instruction: 'Melt the butter and cook the chopped onion and carrot '
              'until soft.',
          duration: _min(5),
        ),
        RecipeStep(
          instruction: 'Add rinsed lentils and water, bring to a boil and '
              'simmer until the lentils fall apart.',
          duration: _min(25),
        ),
        RecipeStep(
          instruction: 'Blend until smooth, season and serve with lemon '
              'wedges.',
          duration: _min(5),
        ),
      ],
    ),
    Recipe(
      id: 'pasta-with-yogurt',
      title: 'Pasta with yogurt',
      cookTime: _min(20),
      ingredients: const [
        RecipeIngredient(
          name: 'Pasta',
          amount: '250 g',
          allergens: {Allergen.gluten},
        ),
        _yogurt,
        _garlic,
        _butter,
        _driedMint,
        _salt,
      ],
      steps: [
        RecipeStep(
          instruction: 'Boil the pasta in salted water until al dente.',
          duration: _min(10),
        ),
        RecipeStep(
          instruction: 'Mix the yogurt with crushed garlic and a pinch of '
              'salt.',
          duration: _min(3),
        ),
        RecipeStep(
          instruction: 'Sizzle the dried mint in butter, then pour over the '
              'pasta and garlic yogurt.',
          duration: _min(2),
        ),
      ],
    ),
    Recipe(
      id: 'rice-pudding',
      title: 'Rice pudding',
      cookTime: _min(40),
      ingredients: const [
        RecipeIngredient(
          name: 'Milk',
          amount: '1 L',
          allergens: {Allergen.milk},
          traits: {IngredientTrait.dairy},
        ),
        RecipeIngredient(name: 'Rice', amount: '100 g'),
        RecipeIngredient(name: 'Sugar', amount: '120 g'),
        RecipeIngredient(name: 'Cinnamon', amount: '1 tsp'),
      ],
      steps: [
        RecipeStep(
          instruction: 'Simmer the rice in a cup of water until it is '
              'absorbed.',
          duration: _min(10),
        ),
        RecipeStep(
          instruction: 'Pour in the milk and sugar and cook, stirring often, '
              'until thick and creamy.',
          duration: _min(25),
        ),
        RecipeStep(
          instruction: 'Spoon into bowls, dust with cinnamon and let it '
              'cool.',
          duration: _min(5),
        ),
      ],
    ),
    Recipe(
      id: 'peanut-noodle-salad',
      title: 'Peanut noodle salad',
      cookTime: _min(15),
      ingredients: const [
        RecipeIngredient(name: 'Rice noodles', amount: '200 g'),
        RecipeIngredient(
          name: 'Peanut butter',
          amount: '3 tbsp',
          allergens: {Allergen.peanuts},
        ),
        _carrot,
        _pepper,
        RecipeIngredient(
          name: 'Soy sauce',
          amount: '2 tbsp',
          allergens: {Allergen.soy, Allergen.gluten},
        ),
      ],
      steps: [
        RecipeStep(
          instruction: 'Soak the rice noodles in boiling water until tender, '
              'then rinse cold.',
          duration: _min(6),
        ),
        RecipeStep(
          instruction: 'Whisk peanut butter with soy sauce and a little warm '
              'water.',
          duration: _min(2),
        ),
        RecipeStep(
          instruction: 'Toss noodles with julienned carrot, pepper and the '
              'dressing.',
          duration: _min(3),
        ),
      ],
    ),
    Recipe(
      id: 'chicken-satay',
      title: 'Chicken satay',
      cookTime: _min(25),
      ingredients: const [
        _chicken,
        RecipeIngredient(
          name: 'Peanuts',
          amount: '80 g',
          allergens: {Allergen.peanuts},
        ),
        RecipeIngredient(
          name: 'Soy sauce',
          amount: '2 tbsp',
          allergens: {Allergen.soy, Allergen.gluten},
        ),
        _lemon,
        _garlic,
      ],
      steps: [
        RecipeStep(
          instruction: 'Marinate the chicken strips in soy sauce, garlic and '
              'lemon juice.',
          duration: _min(10),
        ),
        RecipeStep(
          instruction: 'Thread onto skewers and grill, turning once.',
          duration: _min(10),
        ),
        RecipeStep(
          instruction: 'Blitz the peanuts into a sauce and serve alongside.',
          duration: _min(5),
        ),
      ],
    ),
  ];

  /// The signed-in mock user shown on `7. Profile`.
  static final UserProfile userProfile = UserProfile(
    name: 'Elif Yılmaz',
    email: 'elif@example.com',
    allergies: const {Allergen.peanuts},
    favoriteRecipeIds: const {
      'menemen',
      'baked-sea-bass',
      'lentil-soup',
      'rice-pudding',
    },
    cookedCounts: const {
      'menemen': 6,
      'lentil-soup': 4,
      'cacik': 3,
      'baked-sea-bass': 2,
    },
    itemsSaved: 23,
  );

  /// Sticky notes on `3. Shopping list`.
  static final List<ShoppingNote> shoppingNotes = [
    ShoppingNote(
      id: 'note-cacik',
      title: 'For cacık',
      color: NoteColor.yellow,
      recipeId: 'cacik',
      items: const [
        ShoppingItem(id: 'item-cucumber', name: 'Cucumber'),
        ShoppingItem(id: 'item-garlic', name: 'Garlic'),
        ShoppingItem(id: 'item-dried-mint', name: 'Dried mint'),
      ],
    ),
    ShoppingNote(
      id: 'note-weekly',
      title: 'Weekly',
      color: NoteColor.pink,
      items: const [
        ShoppingItem(id: 'item-milk', name: 'Milk'),
        ShoppingItem(id: 'item-bread', name: 'Bread'),
      ],
    ),
  ];
}
