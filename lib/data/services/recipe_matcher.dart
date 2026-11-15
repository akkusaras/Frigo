import 'package:flutter/foundation.dart';

import '../../models/models.dart';

/// Why a recipe was removed from the suggestions.
enum HiddenReason { allergy, diet }

/// A recipe that must not be suggested to the user.
@immutable
class HiddenRecipe {
  HiddenRecipe({
    required this.recipe,
    required this.reason,
    Set<String> triggers = const {},
  }) : triggers = Set.unmodifiable(triggers);

  final Recipe recipe;
  final HiddenReason reason;

  /// Lower-case allergy labels (`peanuts`, `lactose`) that caused an
  /// [HiddenReason.allergy] hide. Empty for diet hides.
  final Set<String> triggers;

  @override
  String toString() => 'HiddenRecipe(${recipe.id}, $reason, $triggers)';
}

/// A fridge item used by a recipe that is about to expire.
@immutable
class ExpiringUse {
  const ExpiringUse({required this.name, required this.daysLeft});

  final String name;

  /// Whole days until expiry (`0` = today).
  final int daysLeft;

  String get _when => switch (daysLeft) {
    0 => 'expires today',
    1 => 'expires in 1 day',
    _ => 'expires in $daysLeft days',
  };

  @override
  bool operator ==(Object other) =>
      other is ExpiringUse && other.name == name && other.daysLeft == daysLeft;

  @override
  int get hashCode => Object.hash(name, daysLeft);

  @override
  String toString() => '$name ($_when)';
}

/// How well a single recipe fits what is currently in the fridge.
@immutable
class RecipeMatch {
  RecipeMatch({
    required this.recipe,
    required List<RecipeIngredient> available,
    required List<RecipeIngredient> missing,
    required List<ExpiringUse> expiringUses,
    required this.priorityScore,
  }) : available = List.unmodifiable(available),
       missing = List.unmodifiable(missing),
       expiringUses = List.unmodifiable(expiringUses);

  final Recipe recipe;

  /// Key ingredients found in the fridge.
  final List<RecipeIngredient> available;

  /// Key ingredients the user still needs to buy.
  final List<RecipeIngredient> missing;

  /// Expiring fridge items this recipe would use, most urgent first.
  final List<ExpiringUse> expiringUses;

  /// Ranking score: match percentage plus a bonus per expiring item used.
  final int priorityScore;

  int get totalKeyIngredients => available.length + missing.length;

  /// Share of key ingredients available, rounded to a whole percent.
  int get matchPercent => totalKeyIngredients == 0
      ? 100
      : (available.length * 100 / totalKeyIngredients).round();

  bool get isFullMatch => missing.isEmpty;

  bool get usesExpiring => expiringUses.isNotEmpty;

  /// Days left on the most urgent expiring item used, or `null`.
  int? get mostUrgentDaysLeft =>
      expiringUses.isEmpty ? null : expiringUses.first.daysLeft;

  List<String> get missingNames =>
      missing.map((i) => i.name).toList(growable: false);

  /// Badge text, e.g. `100% match` or `80% match – missing garlic`.
  String get matchLabel {
    if (isFullMatch) return '$matchPercent% match';
    final names = missing.map((i) => i.name.toLowerCase()).toList();
    final listed = names.length <= 2
        ? names.join(' and ')
        : '${names.take(2).join(', ')} +${names.length - 2}';
    return '$matchPercent% match – missing $listed';
  }

  /// Expiry priority note on the recipe card, e.g.
  /// `Uses sea bass – expires in 1 day`, or `null` when nothing expires.
  String? get expiryNote {
    if (expiringUses.isEmpty) return null;
    final first = expiringUses.first;
    final names = expiringUses.map((e) => e.name.toLowerCase()).join(' and ');
    return 'Uses $names – ${first._when}';
  }

  @override
  String toString() => 'RecipeMatch(${recipe.id}, $matchPercent%)';
}

/// Output of [RecipeMatcher.match]: ranked suggestions plus what was hidden.
@immutable
class MatchResult {
  MatchResult({
    required List<RecipeMatch> matches,
    required List<HiddenRecipe> hidden,
    required this.diet,
  }) : matches = List.unmodifiable(matches),
       hidden = List.unmodifiable(hidden);

  /// Safe recipes, best first.
  final List<RecipeMatch> matches;
  final List<HiddenRecipe> hidden;
  final Diet diet;

  List<HiddenRecipe> get hiddenByAllergy =>
      hidden.where((h) => h.reason == HiddenReason.allergy).toList();

  List<HiddenRecipe> get hiddenByDiet =>
      hidden.where((h) => h.reason == HiddenReason.diet).toList();

  int get hiddenAllergenCount => hiddenByAllergy.length;

  /// Number of hidden recipes per allergy label (a recipe with two
  /// allergens counts once for each).
  Map<String, int> get hiddenCountByAllergy {
    final counts = <String, int>{};
    for (final h in hiddenByAllergy) {
      for (final t in h.triggers) {
        counts[t] = (counts[t] ?? 0) + 1;
      }
    }
    return Map.unmodifiable(counts);
  }

  /// Footer on `6. What to cook`, e.g.
  /// `Hidden: 2 recipes with peanuts (your allergy)`; `null` when nothing
  /// was hidden for allergies.
  String? get hiddenAllergySummary {
    final count = hiddenAllergenCount;
    if (count == 0) return null;
    final labels = hiddenCountByAllergy.keys.toList()..sort();
    final noun = count == 1 ? 'recipe' : 'recipes';
    final what = labels.length == 1
        ? labels.single
        : '${labels.sublist(0, labels.length - 1).join(', ')} or '
              '${labels.last}';
    final suffix = labels.length == 1 ? 'your allergy' : 'your allergies';
    return 'Hidden: $count $noun with $what ($suffix)';
  }

  /// e.g. `Hidden: 3 recipes that are not vegetarian`; `null` when none.
  String? get hiddenDietSummary {
    final count = hiddenByDiet.length;
    if (count == 0) return null;
    final verb = count == 1 ? 'recipe that is' : 'recipes that are';
    return 'Hidden: $count $verb not ${diet.label.toLowerCase()}';
  }

  RecipeMatch? matchFor(String recipeId) {
    for (final m in matches) {
      if (m.recipe.id == recipeId) return m;
    }
    return null;
  }
}

/// Pure ranking engine behind `6. What to cook`.
///
/// 1. Hides every recipe containing one of the user's allergens (standard
///    chips or custom text such as `Lactose`).
/// 2. Hides recipes that break the user's diet (`Vegetarian`, `Vegan`,
///    `Halal`).
/// 3. Scores the rest by how many key ingredients are in the fridge and
///    boosts recipes that use items about to expire.
class RecipeMatcher {
  const RecipeMatcher({this.expiringBonus = 20});

  /// Points added to the match percentage per expiring fridge item a recipe
  /// would use up.
  final int expiringBonus;

  /// Custom allergy words that map onto a standard allergen.
  static const Map<String, Allergen> _allergySynonyms = {
    'lactose': Allergen.milk,
    'dairy': Allergen.milk,
    'egg': Allergen.eggs,
    'wheat': Allergen.gluten,
    'peanut': Allergen.peanuts,
    'nuts': Allergen.treeNuts,
    'seafood': Allergen.shellfish,
  };

  MatchResult match({
    required List<Recipe> recipes,
    required List<Ingredient> fridge,
    required UserProfile profile,
    required DateTime now,
  }) {
    final usable = [
      for (final item in fridge)
        if (!item.isExpired(now)) item,
    ];
    final customTerms = [
      for (final c in profile.customAllergies)
        if (normalizeIngredientName(c).isNotEmpty) normalizeIngredientName(c),
    ];

    final matches = <RecipeMatch>[];
    final hidden = <HiddenRecipe>[];

    for (final recipe in recipes) {
      final triggers = allergyTriggers(
        recipe,
        allergies: profile.allergies,
        customAllergies: customTerms,
      );
      if (triggers.isNotEmpty) {
        hidden.add(
          HiddenRecipe(
            recipe: recipe,
            reason: HiddenReason.allergy,
            triggers: triggers,
          ),
        );
        continue;
      }
      if (!recipe.fitsDiet(profile.diet)) {
        hidden.add(HiddenRecipe(recipe: recipe, reason: HiddenReason.diet));
        continue;
      }
      matches.add(scoreRecipe(recipe, usable, now));
    }

    matches.sort(_compare);
    return MatchResult(matches: matches, hidden: hidden, diet: profile.diet);
  }

  /// Lower-case allergy labels in [recipe] that the user reacts to.
  Set<String> allergyTriggers(
    Recipe recipe, {
    required Set<Allergen> allergies,
    List<String> customAllergies = const [],
  }) {
    final found = <String>{};
    final recipeAllergens = recipe.allergens;
    for (final a in allergies) {
      if (recipeAllergens.contains(a)) found.add(a.label.toLowerCase());
    }
    for (final raw in customAllergies) {
      final term = normalizeIngredientName(raw);
      if (term.isEmpty) continue;
      if (_customTermHits(term, recipe)) found.add(term);
    }
    return found;
  }

  bool _customTermHits(String term, Recipe recipe) {
    final synonym = _allergySynonyms[term];
    if (synonym != null && recipe.allergens.contains(synonym)) return true;
    for (final ingredient in recipe.ingredients) {
      if (ingredient.allergens.any((a) => a.label.toLowerCase() == term)) {
        return true;
      }
      if (_containsWord(ingredient.normalizedName, term)) return true;
    }
    return false;
  }

  /// Computes availability and expiry usage of one (already safe) recipe.
  RecipeMatch scoreRecipe(
    Recipe recipe,
    List<Ingredient> fridge,
    DateTime now,
  ) {
    final available = <RecipeIngredient>[];
    final missing = <RecipeIngredient>[];
    final expiring = <ExpiringUse>[];

    for (final line in recipe.keyIngredients) {
      final stocked = _bestFridgeItem(line, fridge, now);
      if (stocked == null) {
        missing.add(line);
        continue;
      }
      available.add(line);
      if (stocked.isExpiringSoon(now)) {
        expiring.add(
          ExpiringUse(
            name: stocked.name,
            daysLeft: stocked.daysUntilExpiry(now)!,
          ),
        );
      }
    }
    expiring.sort((a, b) => a.daysLeft.compareTo(b.daysLeft));

    final total = available.length + missing.length;
    final percent = total == 0 ? 100 : (available.length * 100 / total).round();

    return RecipeMatch(
      recipe: recipe,
      available: available,
      missing: missing,
      expiringUses: expiring,
      priorityScore: percent + expiring.length * expiringBonus,
    );
  }

  /// The fridge item satisfying [line]; prefers the one expiring soonest so
  /// it gets used up first.
  Ingredient? _bestFridgeItem(
    RecipeIngredient line,
    List<Ingredient> fridge,
    DateTime now,
  ) {
    Ingredient? best;
    for (final item in fridge) {
      if (!ingredientMatches(item.name, line.name)) continue;
      if (best == null) {
        best = item;
        continue;
      }
      final a = item.daysUntilExpiry(now);
      final b = best.daysUntilExpiry(now);
      if (a != null && (b == null || a < b)) best = item;
    }
    return best;
  }

  /// Whether a fridge item called [fridgeName] satisfies a recipe line
  /// called [recipeName]. Case, spacing, simple plurals and qualifiers after
  /// a comma (`Spinach, frozen`) are ignored.
  static bool ingredientMatches(String fridgeName, String recipeName) =>
      _canonical(fridgeName) == _canonical(recipeName);

  static String _canonical(String name) {
    var n = normalizeIngredientName(name);
    final comma = n.indexOf(',');
    if (comma >= 0) n = n.substring(0, comma).trim();
    return n.split(' ').map(_singular).join(' ');
  }

  static String _singular(String word) {
    if (word.length > 3 && word.endsWith('oes')) {
      return word.substring(0, word.length - 2);
    }
    if (word.length > 3 && word.endsWith('ies')) {
      return '${word.substring(0, word.length - 3)}y';
    }
    if (word.length > 2 && word.endsWith('s') && !word.endsWith('ss')) {
      return word.substring(0, word.length - 1);
    }
    return word;
  }

  static bool _containsWord(String haystack, String term) {
    final h = _canonical(haystack);
    final t = _canonical(term);
    if (h == t) return true;
    return RegExp('(^| )${RegExp.escape(t)}( |\$)').hasMatch(h);
  }

  static int _compare(RecipeMatch a, RecipeMatch b) {
    final byScore = b.priorityScore.compareTo(a.priorityScore);
    if (byScore != 0) return byScore;
    final byPercent = b.matchPercent.compareTo(a.matchPercent);
    if (byPercent != 0) return byPercent;
    final ua = a.mostUrgentDaysLeft;
    final ub = b.mostUrgentDaysLeft;
    if (ua != ub) {
      if (ua == null) return 1;
      if (ub == null) return -1;
      return ua.compareTo(ub);
    }
    final byTime = a.recipe.cookTime.compareTo(b.recipe.cookTime);
    if (byTime != 0) return byTime;
    return a.recipe.title.compareTo(b.recipe.title);
  }
}
