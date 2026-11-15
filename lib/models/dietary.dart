/// Allergens offered as chips on the `Allergies and diet` screen.
enum Allergen {
  peanuts('Peanuts'),
  treeNuts('Tree nuts'),
  milk('Milk'),
  eggs('Eggs'),
  gluten('Gluten'),
  fish('Fish'),
  shellfish('Shellfish'),
  soy('Soy'),
  sesame('Sesame');

  const Allergen(this.label);

  final String label;
}

/// Properties of a recipe ingredient that diet rules care about.
enum IngredientTrait { meat, poultry, fish, shellfish, dairy, egg, pork, alcohol }

/// Single-select diet on the `Allergies and diet` screen.
enum Diet {
  none('None', {}),
  vegetarian('Vegetarian', {
    IngredientTrait.meat,
    IngredientTrait.poultry,
    IngredientTrait.fish,
    IngredientTrait.shellfish,
    IngredientTrait.pork,
  }),
  vegan('Vegan', {
    IngredientTrait.meat,
    IngredientTrait.poultry,
    IngredientTrait.fish,
    IngredientTrait.shellfish,
    IngredientTrait.pork,
    IngredientTrait.dairy,
    IngredientTrait.egg,
  }),
  halal('Halal', {IngredientTrait.pork, IngredientTrait.alcohol});

  const Diet(this.label, this.forbiddenTraits);

  final String label;

  /// Ingredient traits a recipe must not contain to fit this diet.
  final Set<IngredientTrait> forbiddenTraits;

  bool allows(Iterable<IngredientTrait> traits) =>
      !traits.any(forbiddenTraits.contains);
}
