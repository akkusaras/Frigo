import 'dart:convert';

import '../../core/persistence/local_store.dart';
import '../../models/models.dart';
import '../seed/seed_data.dart';

/// Persists the sticky notes on the fridge door.
abstract interface class ShoppingRepository {
  List<ShoppingNote> loadNotes();
  void saveNotes(List<ShoppingNote> notes);

  /// Wipes any saved state and goes back to the mockup's demo notes.
  void resetToDemo();
}

class InMemoryShoppingRepository implements ShoppingRepository {
  InMemoryShoppingRepository({List<ShoppingNote>? seed})
      : _notes = List.unmodifiable(seed ?? SeedData.shoppingNotes);

  List<ShoppingNote> _notes;

  @override
  List<ShoppingNote> loadNotes() => _notes;

  @override
  void saveNotes(List<ShoppingNote> notes) =>
      _notes = List.unmodifiable(notes);

  @override
  void resetToDemo() => _notes = List.unmodifiable(SeedData.shoppingNotes);
}

/// Persists sticky notes (including their checked state) as JSON in
/// [LocalStore] so the fridge door survives app restarts. Seeds the
/// mockup's demo notes the first time it is read.
class PersistentShoppingRepository implements ShoppingRepository {
  PersistentShoppingRepository(this._store);

  static const _key = 'frigo.shopping.notes.v1';

  final LocalStore _store;

  @override
  List<ShoppingNote> loadNotes() {
    final raw = _store.getString(_key);
    if (raw == null) {
      final seeded = SeedData.shoppingNotes;
      saveNotes(seeded);
      return seeded;
    }
    return _decode(raw);
  }

  @override
  void saveNotes(List<ShoppingNote> notes) =>
      _store.setString(_key, _encode(notes));

  @override
  void resetToDemo() {
    _store.remove(_key);
    loadNotes();
  }

  static String _encode(List<ShoppingNote> notes) => jsonEncode([
        for (final n in notes)
          {
            'id': n.id,
            'title': n.title,
            'color': n.color.name,
            'recipeId': n.recipeId,
            'items': [
              for (final i in n.items)
                {'id': i.id, 'name': i.name, 'isChecked': i.isChecked},
            ],
          },
      ]);

  static List<ShoppingNote> _decode(String raw) {
    final list = jsonDecode(raw) as List<dynamic>;
    return [
      for (final entry in list)
        ShoppingNote(
          id: entry['id'] as String,
          title: entry['title'] as String,
          color: NoteColor.values.byName(entry['color'] as String),
          recipeId: entry['recipeId'] as String?,
          items: [
            for (final item in entry['items'] as List<dynamic>)
              ShoppingItem(
                id: item['id'] as String,
                name: item['name'] as String,
                isChecked: item['isChecked'] as bool,
              ),
          ],
        ),
    ];
  }
}
