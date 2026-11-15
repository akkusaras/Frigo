import 'package:flutter/foundation.dart';

import 'dietary.dart';
import 'ingredient.dart';
import 'recipe_step.dart';

/// An ingredient line inside a recipe.
@immutable
class RecipeIngredient {
  const RecipeIngredient({
    required this.name,
    required this.amount,
    this.allergens = const {},
    this.traits = const {},
    this.isPantryStaple = false,
  });

  final String name;

  /// Human readable amount, e.g. `200 g` or `2 cloves`.
  final String amount;

  final Set<Allergen> allergens;
  final Set<IngredientTrait> traits;

  /// Staples (salt, oil, water...) are assumed to be at home and never count
  /// towards the match percentage or the missing list.
  final bool isPantryStaple;

  String get normalizedName => normalizeIngredientName(name);

  @override
  bool operator ==(Object other) =>
      other is RecipeIngredient &&
      other.name == name &&
      other.amount == amount &&
      setEquals(other.allergens, allergens) &&
      setEquals(other.traits, traits) &&
      other.isPantryStaple == isPantryStaple;

  @override
  int get hashCode => Object.hash(
        name,
        amount,
        Object.hashAllUnordered(allergens),
        Object.hashAllUnordered(traits),
        isPantryStaple,
      );

  @override
  String toString() => 'RecipeIngredient($name, $amount)';
}

/// A recipe that can be suggested, favorited and cooked.
@immutable
class Recipe {
  Recipe({
    required this.id,
    required this.title,
    required this.cookTime,
    required List<RecipeIngredient> ingredients,
    required List<RecipeStep> steps,
    this.servings = 2,
  })  : ingredients = List.unmodifiable(ingredients),
        steps = List.unmodifiable(steps);

  /// URL-safe id used in routes, e.g. `baked-sea-bass`.
  final String id;
  final String title;
  final Duration cookTime;
  final int servings;
  final List<RecipeIngredient> ingredients;
  final List<RecipeStep> steps;

  int get cookMinutes => cookTime.inMinutes;

  /// Ingredients that count towards matching (pantry staples excluded).
  List<RecipeIngredient> get keyIngredients =>
      ingredients.where((i) => !i.isPantryStaple).toList(growable: false);

  Set<Allergen> get allergens => {for (final i in ingredients) ...i.allergens};

  Set<IngredientTrait> get traits => {for (final i in ingredients) ...i.traits};

  bool fitsDiet(Diet diet) => diet.allows(traits);

  bool get isVegetarian => fitsDiet(Diet.vegetarian);

  @override
  bool operator ==(Object other) =>
      other is Recipe &&
      other.id == id &&
      other.title == title &&
      other.cookTime == cookTime &&
      other.servings == servings &&
      listEquals(other.ingredients, ingredients) &&
      listEquals(other.steps, steps);

  @override
  int get hashCode => Object.hash(
        id,
        title,
        cookTime,
        servings,
        Object.hashAll(ingredients),
        Object.hashAll(steps),
      );

  @override
  String toString() => 'Recipe($id)';
}
