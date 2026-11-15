import '../../models/models.dart';
import '../seed/seed_data.dart';

/// Source of truth for fridge contents. Swap the in-memory implementation
/// for a Firebase / OCR-backed one without touching the UI.
abstract interface class FridgeRepository {
  List<Ingredient> loadIngredients();
  void saveIngredients(List<Ingredient> ingredients);
}

class InMemoryFridgeRepository implements FridgeRepository {
  InMemoryFridgeRepository({List<Ingredient>? seed, DateTime? today})
      : _items = List.unmodifiable(
          seed ?? SeedData.fridgeIngredients(today ?? DateTime.now()),
        );

  List<Ingredient> _items;

  @override
  List<Ingredient> loadIngredients() => _items;

  @override
  void saveIngredients(List<Ingredient> ingredients) =>
      _items = List.unmodifiable(ingredients);
}
