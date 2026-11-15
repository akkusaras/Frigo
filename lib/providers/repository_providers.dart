import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/repositories/fridge_repository.dart';
import '../data/repositories/profile_repository.dart';
import '../data/repositories/recipe_repository.dart';
import '../data/repositories/shopping_repository.dart';

/// Current time; override in tests for deterministic expiry badges.
final clockProvider = Provider<DateTime Function()>((ref) => DateTime.now);

final fridgeRepositoryProvider = Provider<FridgeRepository>(
  (ref) => InMemoryFridgeRepository(today: ref.watch(clockProvider)()),
);

final recipeRepositoryProvider = Provider<RecipeRepository>(
  (ref) => InMemoryRecipeRepository(),
);

final profileRepositoryProvider = Provider<ProfileRepository>(
  (ref) => InMemoryProfileRepository(),
);

final shoppingRepositoryProvider = Provider<ShoppingRepository>(
  (ref) => InMemoryShoppingRepository(),
);
