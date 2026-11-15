import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/services/recipe_matcher.dart';
import '../models/models.dart';
import 'fridge_provider.dart';
import 'profile_provider.dart';
import 'repository_providers.dart';
import 'service_providers.dart';

/// A favorited recipe with its live fridge match.
@immutable
class FavoriteRecipe {
  const FavoriteRecipe({
    required this.recipe,
    required this.match,
    required this.timesCooked,
  });

  final Recipe recipe;
  final RecipeMatch match;
  final int timesCooked;

  /// Every key ingredient is in the fridge.
  bool get isReady => match.isFullMatch;

  int get missingCount => match.missing.length;
}

/// The user's favorites, in catalogue order, scored against the fridge.
final favoriteRecipesProvider = Provider<List<FavoriteRecipe>>((ref) {
  final profile = ref.watch(profileProvider);
  final recipes = ref.watch(recipeRepositoryProvider).loadRecipes();
  final matcher = ref.watch(recipeMatcherProvider);
  final now = ref.watch(clockProvider)();
  final usable = [
    for (final item in ref.watch(fridgeProvider))
      if (!item.isExpired(now)) item,
  ];
  return [
    for (final recipe in recipes)
      if (profile.isFavorite(recipe.id))
        FavoriteRecipe(
          recipe: recipe,
          match: matcher.scoreRecipe(recipe, usable, now),
          timesCooked: profile.timesCooked(recipe.id),
        ),
  ];
});

/// Lower-cases and strips Turkish diacritics so `cacik` finds `Cacık`.
String foldForSearch(String text) {
  const map = {
    'ı': 'i',
    'İ': 'i',
    'ç': 'c',
    'Ç': 'c',
    'ş': 's',
    'Ş': 's',
    'ğ': 'g',
    'Ğ': 'g',
    'ö': 'o',
    'Ö': 'o',
    'ü': 'u',
    'Ü': 'u',
    'é': 'e',
  };
  final buffer = StringBuffer();
  for (final rune in text.runes) {
    final char = String.fromCharCode(rune);
    buffer.write(map[char] ?? char);
  }
  return normalizeIngredientName(buffer.toString());
}

/// Favorites whose title or ingredients contain [query].
List<FavoriteRecipe> filterFavorites(
  List<FavoriteRecipe> favorites,
  String query,
) {
  final q = foldForSearch(query);
  if (q.isEmpty) return favorites;
  return [
    for (final f in favorites)
      if (foldForSearch(f.recipe.title).contains(q) ||
          f.recipe.ingredients.any((i) => foldForSearch(i.name).contains(q)))
        f,
  ];
}
