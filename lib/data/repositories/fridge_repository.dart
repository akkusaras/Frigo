import 'dart:convert';

import '../../core/persistence/local_store.dart';
import '../../models/models.dart';
import '../seed/seed_data.dart';

/// Source of truth for fridge contents. Swap the in-memory implementation
/// for a Firebase / OCR-backed one without touching the UI.
abstract interface class FridgeRepository {
  List<Ingredient> loadIngredients();
  void saveIngredients(List<Ingredient> ingredients);

  /// Wipes any saved state and goes back to the mockup's demo fridge.
  void resetToDemo();
}

class InMemoryFridgeRepository implements FridgeRepository {
  InMemoryFridgeRepository({List<Ingredient>? seed, DateTime? today})
      : _today = today ?? DateTime.now(),
        _items = List.unmodifiable(
          seed ?? SeedData.fridgeIngredients(today ?? DateTime.now()),
        );

  final DateTime _today;
  List<Ingredient> _items;

  @override
  List<Ingredient> loadIngredients() => _items;

  @override
  void saveIngredients(List<Ingredient> ingredients) =>
      _items = List.unmodifiable(ingredients);

  @override
  void resetToDemo() => _items = List.unmodifiable(
        SeedData.fridgeIngredients(_today),
      );
}

/// Persists fridge contents as JSON in [LocalStore] (`shared_preferences`
/// on a device) so added ingredients and expiry dates survive app
/// restarts. Seeds the mockup's demo fridge the first time it is read.
class PersistentFridgeRepository implements FridgeRepository {
  PersistentFridgeRepository(this._store, {DateTime? today})
      : _today = today ?? DateTime.now();

  static const _key = 'frigo.fridge.ingredients.v1';

  final LocalStore _store;
  final DateTime _today;

  @override
  List<Ingredient> loadIngredients() {
    final raw = _store.getString(_key);
    if (raw == null) {
      final seeded = SeedData.fridgeIngredients(_today);
      saveIngredients(seeded);
      return seeded;
    }
    return _decode(raw);
  }

  @override
  void saveIngredients(List<Ingredient> ingredients) =>
      _store.setString(_key, _encode(ingredients));

  @override
  void resetToDemo() {
    _store.remove(_key);
    loadIngredients();
  }

  static String _encode(List<Ingredient> ingredients) => jsonEncode([
        for (final i in ingredients)
          {
            'id': i.id,
            'name': i.name,
            'shelf': i.shelf.name,
            'quantity': i.quantity,
            'expiresOn': i.expiresOn?.toIso8601String(),
          },
      ]);

  static List<Ingredient> _decode(String raw) {
    final list = jsonDecode(raw) as List<dynamic>;
    return [
      for (final entry in list)
        Ingredient(
          id: entry['id'] as String,
          name: entry['name'] as String,
          shelf: ShelfCategory.values.byName(entry['shelf'] as String),
          quantity: entry['quantity'] as String?,
          expiresOn: entry['expiresOn'] == null
              ? null
              : DateTime.parse(entry['expiresOn'] as String),
        ),
    ];
  }
}
