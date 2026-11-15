import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/services/recipe_matcher.dart';
import '../models/models.dart';
import 'fridge_provider.dart';
import 'profile_provider.dart';
import 'repository_providers.dart';
import 'service_providers.dart';

/// Filter chips on `6. What to cook`.
enum RecipeFilter {
  allergySafe('Allergy-safe'),
  under20Min('Under 20 min'),
  vegetarian('Vegetarian'),
  usesExpiring('Uses expiring');

  const RecipeFilter(this.label);

  final String label;

  /// Longest cook time accepted by [under20Min].
  static const quickCookLimit = Duration(minutes: 20);

  /// Allergen hiding is enforced by [RecipeMatcher] and cannot be turned off.
  bool get isLocked => this == allergySafe;

  bool accepts(RecipeMatch match) => switch (this) {
    // Allergen recipes never reach the match list in the first place.
    allergySafe => true,
    under20Min => match.recipe.cookTime <= quickCookLimit,
    vegetarian => match.recipe.isVegetarian,
    usesExpiring => match.usesExpiring,
  };
}

/// Matches passing every active filter, keeping the ranking order.
List<RecipeMatch> applyRecipeFilters(
  List<RecipeMatch> matches,
  Set<RecipeFilter> filters,
) => [
  for (final m in matches)
    if (filters.every((f) => f.accepts(m))) m,
];

/// Active filter chips (Allergy-safe is always on).
final recipeFiltersProvider =
    NotifierProvider<RecipeFiltersNotifier, Set<RecipeFilter>>(
      RecipeFiltersNotifier.new,
    );

class RecipeFiltersNotifier extends Notifier<Set<RecipeFilter>> {
  static const _defaults = {RecipeFilter.allergySafe};

  @override
  Set<RecipeFilter> build() => Set.unmodifiable(_defaults);

  void toggle(RecipeFilter filter) {
    if (filter.isLocked) return;
    final next = {...state};
    if (!next.remove(filter)) next.add(filter);
    state = Set.unmodifiable(next);
  }

  void clear() => state = Set.unmodifiable(_defaults);
}

/// All safe recipes ranked against the fridge, plus what was hidden.
final recipeSuggestionsProvider = Provider<MatchResult>((ref) {
  final matcher = ref.watch(recipeMatcherProvider);
  return matcher.match(
    recipes: ref.watch(recipeRepositoryProvider).loadRecipes(),
    fridge: ref.watch(fridgeProvider),
    profile: ref.watch(profileProvider),
    now: ref.watch(clockProvider)(),
  );
});

/// Ranked suggestions after the active filter chips.
final filteredRecipeMatchesProvider = Provider<List<RecipeMatch>>((ref) {
  return applyRecipeFilters(
    ref.watch(recipeSuggestionsProvider).matches,
    ref.watch(recipeFiltersProvider),
  );
});

/// Everything the detail and cooking screens need about one recipe.
@immutable
class RecipeInsight {
  RecipeInsight({
    required this.recipe,
    required this.match,
    required Set<String> allergyTriggers,
    required this.fitsDiet,
  }) : allergyTriggers = Set.unmodifiable(allergyTriggers);

  final Recipe recipe;
  final RecipeMatch match;

  /// Lower-case allergy labels the user reacts to (empty when safe).
  final Set<String> allergyTriggers;
  final bool fitsDiet;

  bool get isAllergySafe => allergyTriggers.isEmpty;

  bool isAvailable(RecipeIngredient line) =>
      line.isPantryStaple || match.available.contains(line);
}

/// Live insight for a recipe id, or `null` when the id is unknown.
final recipeInsightProvider = Provider.family<RecipeInsight?, String>((
  ref,
  recipeId,
) {
  final recipe = ref.watch(recipeRepositoryProvider).findById(recipeId);
  if (recipe == null) return null;
  final profile = ref.watch(profileProvider);
  final matcher = ref.watch(recipeMatcherProvider);
  final now = ref.watch(clockProvider)();
  final usable = [
    for (final item in ref.watch(fridgeProvider))
      if (!item.isExpired(now)) item,
  ];
  return RecipeInsight(
    recipe: recipe,
    match: matcher.scoreRecipe(recipe, usable, now),
    allergyTriggers: matcher.allergyTriggers(
      recipe,
      allergies: profile.allergies,
      customAllergies: profile.customAllergies,
    ),
    fitsDiet: recipe.fitsDiet(profile.diet),
  );
});
