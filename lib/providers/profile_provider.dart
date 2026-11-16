import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/models.dart';
import 'repository_providers.dart';

/// The signed-in user's profile, allergies, diet and favorites.
final profileProvider = NotifierProvider<ProfileNotifier, UserProfile>(
  ProfileNotifier.new,
);

class ProfileNotifier extends Notifier<UserProfile> {
  @override
  UserProfile build() => ref.watch(profileRepositoryProvider).loadProfile();

  void _save(UserProfile profile) {
    ref.read(profileRepositoryProvider).saveProfile(profile);
    state = profile;
  }

  void toggleFavorite(String recipeId) {
    final favorites = {...state.favoriteRecipeIds};
    if (!favorites.remove(recipeId)) favorites.add(recipeId);
    _save(state.copyWith(favoriteRecipeIds: favorites));
  }

  /// Counts a finished Cooking Mode session towards `Meals cooked`, and
  /// [expiringItemsUsed] fridge items that were about to go off towards the
  /// `Items saved` impact counter.
  void recordCooked(String recipeId, {int expiringItemsUsed = 0}) {
    _save(
      state.copyWith(
        cookedCounts: {
          ...state.cookedCounts,
          recipeId: state.timesCooked(recipeId) + 1,
        },
        itemsSaved: state.itemsSaved + expiringItemsUsed,
      ),
    );
  }

  /// Restores the mockup's demo profile, discarding whatever is saved.
  void resetToDemo() {
    final repository = ref.read(profileRepositoryProvider);
    repository.resetToDemo();
    state = repository.loadProfile();
  }

  /// Replaces the allergy and diet settings from `9. Allergies and diet`.
  void updateDietary({
    required Set<Allergen> allergies,
    required List<String> customAllergies,
    required Diet diet,
  }) {
    _save(
      state.copyWith(
        allergies: allergies,
        customAllergies: customAllergies,
        diet: diet,
      ),
    );
  }
}
