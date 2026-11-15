import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/models.dart';
import 'repository_providers.dart';

/// Everything currently in the fridge.
final fridgeProvider = NotifierProvider<FridgeNotifier, List<Ingredient>>(
  FridgeNotifier.new,
);

class FridgeNotifier extends Notifier<List<Ingredient>> {
  @override
  List<Ingredient> build() =>
      ref.watch(fridgeRepositoryProvider).loadIngredients();

  void _save(List<Ingredient> items) {
    ref.read(fridgeRepositoryProvider).saveIngredients(items);
    state = List.unmodifiable(items);
  }

  void add(Ingredient ingredient) => _save([...state, ingredient]);

  void remove(String ingredientId) =>
      _save([for (final i in state) if (i.id != ingredientId) i]);
}
