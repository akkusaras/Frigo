import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/models.dart';
import 'repository_providers.dart';

/// Sticky notes on the fridge door.
final shoppingNotesProvider =
    NotifierProvider<ShoppingNotesNotifier, List<ShoppingNote>>(
  ShoppingNotesNotifier.new,
);

class ShoppingNotesNotifier extends Notifier<List<ShoppingNote>> {
  @override
  List<ShoppingNote> build() =>
      ref.watch(shoppingRepositoryProvider).loadNotes();

  void _save(List<ShoppingNote> notes) {
    ref.read(shoppingRepositoryProvider).saveNotes(notes);
    state = List.unmodifiable(notes);
  }

  void toggleItem(String noteId, String itemId) {
    _save([
      for (final note in state)
        if (note.id == noteId)
          note.copyWith(
            items: [
              for (final item in note.items)
                item.id == itemId
                    ? item.copyWith(isChecked: !item.isChecked)
                    : item,
            ],
          )
        else
          note,
    ]);
  }
}

/// Unchecked items across every note (shown on the Profile menu tile).
final shoppingOpenItemCountProvider = Provider<int>(
  (ref) => ref
      .watch(shoppingNotesProvider)
      .fold(0, (sum, note) => sum + note.openItemCount),
);
