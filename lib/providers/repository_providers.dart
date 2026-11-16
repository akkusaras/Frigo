import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/persistence/local_store.dart';
import '../data/repositories/fridge_repository.dart';
import '../data/repositories/profile_repository.dart';
import '../data/repositories/recipe_repository.dart';
import '../data/repositories/shopping_repository.dart';

/// Current time; override in tests for deterministic expiry badges.
final clockProvider = Provider<DateTime Function()>((ref) => DateTime.now);

/// Where the repositories persist their JSON. `main()` overrides this with
/// a loaded `SharedPreferences` instance; left as a throwaway in-memory
/// store otherwise, which is exactly what every test wants: a fresh demo
/// fridge every run with no platform setup.
final localStoreProvider = Provider<LocalStore>((ref) => InMemoryLocalStore());

final fridgeRepositoryProvider = Provider<FridgeRepository>(
  (ref) => PersistentFridgeRepository(
    ref.watch(localStoreProvider),
    today: ref.watch(clockProvider)(),
  ),
);

final recipeRepositoryProvider = Provider<RecipeRepository>(
  (ref) => InMemoryRecipeRepository(),
);

final profileRepositoryProvider = Provider<ProfileRepository>(
  (ref) => PersistentProfileRepository(ref.watch(localStoreProvider)),
);

final shoppingRepositoryProvider = Provider<ShoppingRepository>(
  (ref) => PersistentShoppingRepository(ref.watch(localStoreProvider)),
);
