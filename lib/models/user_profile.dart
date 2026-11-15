import 'package:flutter/foundation.dart';

import 'dietary.dart';

/// The signed-in user, their dietary settings and cooking stats.
@immutable
class UserProfile {
  UserProfile({
    required this.name,
    required this.email,
    Set<Allergen> allergies = const {},
    List<String> customAllergies = const [],
    this.diet = Diet.none,
    Set<String> favoriteRecipeIds = const {},
    Map<String, int> cookedCounts = const {},
    this.itemsSaved = 0,
  })  : allergies = Set.unmodifiable(allergies),
        customAllergies = List.unmodifiable(customAllergies),
        favoriteRecipeIds = Set.unmodifiable(favoriteRecipeIds),
        cookedCounts = Map.unmodifiable(cookedCounts);

  final String name;
  final String email;
  final Set<Allergen> allergies;

  /// Free-text allergies added via `Add your own ingredient`.
  final List<String> customAllergies;
  final Diet diet;
  final Set<String> favoriteRecipeIds;

  /// How many times each recipe (by id) has been cooked.
  final Map<String, int> cookedCounts;

  /// Ingredients rescued before they expired.
  final int itemsSaved;

  /// Avatar initials, e.g. `EY` for `Elif Yılmaz`.
  String get initials {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty);
    return parts.take(2).map((p) => p[0].toUpperCase()).join();
  }

  int get mealsCooked => cookedCounts.values.fold(0, (sum, n) => sum + n);

  int get favoritesCount => favoriteRecipeIds.length;

  /// Labels of every active allergy tag (standard + custom).
  List<String> get allergyLabels => [
        for (final a in Allergen.values)
          if (allergies.contains(a)) a.label,
        ...customAllergies,
      ];

  bool isFavorite(String recipeId) => favoriteRecipeIds.contains(recipeId);

  int timesCooked(String recipeId) => cookedCounts[recipeId] ?? 0;

  UserProfile copyWith({
    String? name,
    String? email,
    Set<Allergen>? allergies,
    List<String>? customAllergies,
    Diet? diet,
    Set<String>? favoriteRecipeIds,
    Map<String, int>? cookedCounts,
    int? itemsSaved,
  }) {
    return UserProfile(
      name: name ?? this.name,
      email: email ?? this.email,
      allergies: allergies ?? this.allergies,
      customAllergies: customAllergies ?? this.customAllergies,
      diet: diet ?? this.diet,
      favoriteRecipeIds: favoriteRecipeIds ?? this.favoriteRecipeIds,
      cookedCounts: cookedCounts ?? this.cookedCounts,
      itemsSaved: itemsSaved ?? this.itemsSaved,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is UserProfile &&
      other.name == name &&
      other.email == email &&
      setEquals(other.allergies, allergies) &&
      listEquals(other.customAllergies, customAllergies) &&
      other.diet == diet &&
      setEquals(other.favoriteRecipeIds, favoriteRecipeIds) &&
      mapEquals(other.cookedCounts, cookedCounts) &&
      other.itemsSaved == itemsSaved;

  @override
  int get hashCode => Object.hash(
        name,
        email,
        Object.hashAllUnordered(allergies),
        Object.hashAll(customAllergies),
        diet,
        Object.hashAllUnordered(favoriteRecipeIds),
        Object.hashAllUnordered(
          cookedCounts.entries.map((e) => Object.hash(e.key, e.value)),
        ),
        itemsSaved,
      );

  @override
  String toString() => 'UserProfile($name)';
}
