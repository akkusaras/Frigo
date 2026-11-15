import '../../models/models.dart';
import '../seed/seed_data.dart';

/// Persists the sticky notes on the fridge door.
abstract interface class ShoppingRepository {
  List<ShoppingNote> loadNotes();
  void saveNotes(List<ShoppingNote> notes);
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
}
