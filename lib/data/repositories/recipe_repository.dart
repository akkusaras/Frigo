import '../../models/models.dart';
import '../seed/seed_data.dart';

/// Read-only recipe catalogue.
abstract interface class RecipeRepository {
  List<Recipe> loadRecipes();
  Recipe? findById(String id);
}

class InMemoryRecipeRepository implements RecipeRepository {
  InMemoryRecipeRepository({List<Recipe>? recipes})
      : _recipes = List.unmodifiable(recipes ?? SeedData.recipes);

  final List<Recipe> _recipes;

  @override
  List<Recipe> loadRecipes() => _recipes;

  @override
  Recipe? findById(String id) {
    for (final recipe in _recipes) {
      if (recipe.id == id) return recipe;
    }
    return null;
  }
}
