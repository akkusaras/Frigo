import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/services/recipe_matcher.dart';
import '../models/models.dart';
import 'fridge_provider.dart';
import 'recipe_suggestions_provider.dart';
import 'repository_providers.dart';

/// Fridge items grouped by shelf, each shelf sorted soonest-expiring first.
final fridgeShelvesProvider = Provider<Map<ShelfCategory, List<Ingredient>>>((
  ref,
) {
  return groupByShelf(ref.watch(fridgeProvider));
});

/// Expiry banner shown at the top of `2. My Fridge`, or `null` when nothing
/// is about to expire.
final fridgeExpiryAlertProvider = Provider<ExpiryAlert?>((ref) {
  return buildExpiryAlert(
    fridge: ref.watch(fridgeProvider),
    matches: ref.watch(recipeSuggestionsProvider).matches,
    now: ref.watch(clockProvider)(),
  );
});

/// Groups [items] into the three shelves (every shelf is present, possibly
/// empty). Items with an expiry date come first, soonest first; ties keep
/// their original order.
Map<ShelfCategory, List<Ingredient>> groupByShelf(List<Ingredient> items) {
  final grouped = {
    for (final shelf in ShelfCategory.values) shelf: <Ingredient>[],
  };
  for (final item in items) {
    grouped[item.shelf]!.add(item);
  }
  return {
    for (final entry in grouped.entries)
      entry.key: List.unmodifiable(_sortedByExpiry(entry.value)),
  };
}

List<Ingredient> _sortedByExpiry(List<Ingredient> items) {
  final indexed = items.indexed.toList();
  indexed.sort((a, b) {
    final ea = a.$2.expiresOn;
    final eb = b.$2.expiresOn;
    if (ea != null && eb != null) {
      final byDate = ea.compareTo(eb);
      if (byDate != 0) return byDate;
    } else if (ea != null) {
      return -1;
    } else if (eb != null) {
      return 1;
    }
    return a.$1.compareTo(b.$1);
  });
  return [for (final (_, item) in indexed) item];
}

/// Content of the coral expiry banner.
@immutable
class ExpiryAlert {
  ExpiryAlert({
    required List<Ingredient> expiringSoon,
    required List<Ingredient> expired,
    required List<Recipe> suggestions,
  })  : expiringSoon = List.unmodifiable(expiringSoon),
        expired = List.unmodifiable(expired),
        suggestions = List.unmodifiable(suggestions);

  /// Items expiring within [Ingredient.expiringSoonDays], fridge order.
  final List<Ingredient> expiringSoon;

  /// Items already past their expiry date.
  final List<Ingredient> expired;

  /// Safe recipes that use the expiring items, one per item at most.
  final List<Recipe> suggestions;

  /// e.g. `Yogurt and sea bass expire soon. Try cacık or baked sea bass
  /// today.`
  String get message {
    final sentences = <String>[];
    if (expiringSoon.isNotEmpty) {
      final verb = expiringSoon.length == 1 ? 'expires' : 'expire';
      final names = _sentenceCase(
        _joinList(expiringSoon.map((i) => i.name.toLowerCase()), 'and'),
      );
      sentences.add('$names $verb soon.');
      if (suggestions.isNotEmpty) {
        final titles = _joinList(
          suggestions.map((r) => r.title.toLowerCase()),
          'or',
        );
        sentences.add('Try $titles today.');
      }
    }
    if (expired.isNotEmpty) {
      final verb = expired.length == 1 ? 'has' : 'have';
      final names = _sentenceCase(
        _joinList(expired.map((i) => i.name.toLowerCase()), 'and'),
      );
      sentences.add('$names $verb expired – check before using.');
    }
    return sentences.join(' ');
  }

  @override
  String toString() => 'ExpiryAlert($message)';
}

/// Builds the banner from the fridge and the ranked safe [matches].
///
/// For each expiring item (in fridge order) the suggested recipe is the one
/// using it that needs the fewest extra ingredients, then the quickest one,
/// then the best ranked. A recipe is suggested at most once.
ExpiryAlert? buildExpiryAlert({
  required List<Ingredient> fridge,
  required List<RecipeMatch> matches,
  required DateTime now,
}) {
  final expiringSoon = [
    for (final item in fridge)
      if (item.isExpiringSoon(now) && !item.isExpired(now)) item,
  ];
  final expired = [
    for (final item in fridge)
      if (item.isExpired(now)) item,
  ];
  if (expiringSoon.isEmpty && expired.isEmpty) return null;

  final suggestions = <Recipe>[];
  for (final item in expiringSoon) {
    final candidates = [
      for (final (rank, m) in matches.indexed)
        if (!suggestions.contains(m.recipe) &&
            m.expiringUses.any(
              (u) => RecipeMatcher.ingredientMatches(u.name, item.name),
            ))
          (rank, m),
    ];
    if (candidates.isEmpty) continue;
    candidates.sort((a, b) {
      final byMissing = a.$2.missing.length.compareTo(b.$2.missing.length);
      if (byMissing != 0) return byMissing;
      final byTime = a.$2.recipe.cookTime.compareTo(b.$2.recipe.cookTime);
      if (byTime != 0) return byTime;
      return a.$1.compareTo(b.$1);
    });
    suggestions.add(candidates.first.$2.recipe);
  }

  return ExpiryAlert(
    expiringSoon: expiringSoon,
    expired: expired,
    suggestions: suggestions,
  );
}

String _joinList(Iterable<String> words, String conjunction) {
  final list = words.toList();
  if (list.length <= 1) return list.join();
  return '${list.sublist(0, list.length - 1).join(', ')} $conjunction '
      '${list.last}';
}

String _sentenceCase(String text) =>
    text.isEmpty ? text : '${text[0].toUpperCase()}${text.substring(1)}';
