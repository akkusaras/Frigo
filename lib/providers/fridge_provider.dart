import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/models.dart';
import 'repository_providers.dart';

/// Everything currently in the fridge.
final fridgeProvider = NotifierProvider<FridgeNotifier, List<Ingredient>>(
  FridgeNotifier.new,
);

class FridgeNotifier extends Notifier<List<Ingredient>> {
  int _idCounter = 0;

  @override
  List<Ingredient> build() =>
      ref.watch(fridgeRepositoryProvider).loadIngredients();

  void _save(List<Ingredient> items) {
    ref.read(fridgeRepositoryProvider).saveIngredients(items);
    state = List.unmodifiable(items);
  }

  void add(Ingredient ingredient) => _save([...state, ingredient]);

  void addAll(Iterable<Ingredient> ingredients) =>
      _save([...state, ...ingredients]);

  void remove(String ingredientId) =>
      _save([for (final i in state) if (i.id != ingredientId) i]);

  /// Restores the mockup's demo fridge, discarding whatever is saved.
  void resetToDemo() {
    final repository = ref.read(fridgeRepositoryProvider);
    repository.resetToDemo();
    state = List.unmodifiable(repository.loadIngredients());
  }

  /// Builds a fridge-unique id such as `ing-spinach-3`.
  String newId(String name, {Set<String> reserved = const {}}) {
    final slug = normalizeIngredientName(name)
        .replaceAll(RegExp(r'[^a-z0-9ğüşıöç]+'), '-')
        .replaceAll(RegExp(r'^-+|-+$'), '');
    final taken = {for (final i in state) i.id, ...reserved};
    String id;
    do {
      id = 'ing-${slug.isEmpty ? 'item' : slug}-${++_idCounter}';
    } while (taken.contains(id));
    return id;
  }
}
