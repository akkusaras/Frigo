import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/services/recipe_matcher.dart';
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

  /// Sticks a new hand-written note on the door. Blank item names are
  /// dropped and duplicates within the note collapsed. Returns the new note,
  /// or `null` when [title] is blank.
  ShoppingNote? addNote({
    required String title,
    required NoteColor color,
    Iterable<String> items = const [],
  }) {
    final trimmed = title.trim();
    if (trimmed.isEmpty) return null;
    final notes = [...state];
    final base = 'note-${_slug(trimmed).isEmpty ? 'custom' : _slug(trimmed)}';
    final taken = {for (final n in notes) n.id};
    var id = base;
    for (var i = 2; taken.contains(id); i++) {
      id = '$base-$i';
    }
    final takenItems = {
      for (final n in notes) ...n.items.map((i) => i.id),
    };
    final lines = <ShoppingItem>[];
    for (final raw in items) {
      final name = raw.trim();
      if (name.isEmpty ||
          lines.any((l) => RecipeMatcher.ingredientMatches(l.name, name))) {
        continue;
      }
      final itemId = _uniqueItemId(takenItems, id, name);
      takenItems.add(itemId);
      lines.add(ShoppingItem(id: itemId, name: name));
    }
    final note = ShoppingNote(id: id, title: trimmed, color: color, items: lines);
    _save([...notes, note]);
    return note;
  }

  /// Adds [name] to the note [noteId]. Re-opens a ticked-off duplicate on
  /// that note; returns `false` when nothing changed.
  bool addItem(String noteId, String name) {
    final trimmed = name.trim();
    final index = state.indexWhere((n) => n.id == noteId);
    if (trimmed.isEmpty || index < 0) return false;
    final note = state[index];
    final existing = note.items.indexWhere(
      (i) => RecipeMatcher.ingredientMatches(i.name, trimmed),
    );
    final List<ShoppingItem> items;
    if (existing >= 0) {
      if (!note.items[existing].isChecked) return false;
      items = [...note.items]
        ..[existing] = note.items[existing].copyWith(isChecked: false);
    } else {
      final taken = {
        for (final n in state) ...n.items.map((i) => i.id),
      };
      items = [
        ...note.items,
        ShoppingItem(id: _uniqueItemId(taken, noteId, trimmed), name: trimmed),
      ];
    }
    _save([...state]..[index] = note.copyWith(items: items));
    return true;
  }

  /// Puts back a previous snapshot of the door (used by `Undo`).
  void restore(List<ShoppingNote> notes) => _save([...notes]);

  /// Takes the note [noteId] off the door.
  void removeNote(String noteId) =>
      _save([for (final n in state) if (n.id != noteId) n]);

  /// Puts [names] on the yellow `For <recipe>` note of [recipe], creating
  /// the note when needed. Names already open on any note are skipped and
  /// ticked-off duplicates are re-opened. Returns how many names were added
  /// or re-opened.
  int addMissingForRecipe(Recipe recipe, Iterable<String> names) {
    final notes = [...state];
    var changed = 0;
    final pending = <String>[];

    for (final name in names) {
      if (isOpenOnList(notes, name) ||
          pending.any((p) => RecipeMatcher.ingredientMatches(p, name))) {
        continue;
      }
      final reopened = _reopen(notes, name);
      if (reopened) {
        changed++;
      } else {
        pending.add(name);
      }
    }

    if (pending.isNotEmpty) {
      final index = notes.indexWhere((n) => n.recipeId == recipe.id);
      final note = index >= 0
          ? notes[index]
          : ShoppingNote(
              id: _uniqueNoteId(notes, recipe.id),
              title: 'For ${recipe.title.toLowerCase()}',
              color: NoteColor.yellow,
              recipeId: recipe.id,
              items: const [],
            );
      final taken = {
        for (final n in notes) ...n.items.map((i) => i.id),
      };
      final items = [...note.items];
      for (final name in pending) {
        final id = _uniqueItemId(taken, recipe.id, name);
        taken.add(id);
        items.add(ShoppingItem(id: id, name: name));
      }
      final updated = note.copyWith(items: items);
      if (index >= 0) {
        notes[index] = updated;
      } else {
        notes.insert(0, updated);
      }
      changed += pending.length;
    }

    if (changed > 0) _save(notes);
    return changed;
  }

  /// Unticks the first checked item called [name]; `false` if none exists.
  bool _reopen(List<ShoppingNote> notes, String name) {
    for (var n = 0; n < notes.length; n++) {
      final items = notes[n].items;
      for (var i = 0; i < items.length; i++) {
        final item = items[i];
        if (item.isChecked &&
            RecipeMatcher.ingredientMatches(item.name, name)) {
          notes[n] = notes[n].copyWith(
            items: [...items]..[i] = item.copyWith(isChecked: false),
          );
          return true;
        }
      }
    }
    return false;
  }

  static String _slug(String text) => normalizeIngredientName(
    text,
  ).replaceAll(RegExp(r'[^a-z0-9]+'), '-').replaceAll(RegExp(r'^-+|-+$'), '');

  static String _uniqueNoteId(List<ShoppingNote> notes, String recipeId) {
    final taken = {for (final n in notes) n.id};
    var id = 'note-$recipeId';
    for (var i = 2; taken.contains(id); i++) {
      id = 'note-$recipeId-$i';
    }
    return id;
  }

  static String _uniqueItemId(Set<String> taken, String recipeId, String name) {
    final base = 'item-$recipeId-${_slug(name)}';
    var id = base;
    for (var i = 2; taken.contains(id); i++) {
      id = '$base-$i';
    }
    return id;
  }
}

/// Whether an unchecked item matching [name] is on any of [notes].
bool isOpenOnList(List<ShoppingNote> notes, String name) => notes.any(
  (note) => note.items.any(
    (item) =>
        !item.isChecked && RecipeMatcher.ingredientMatches(item.name, name),
  ),
);

/// Missing ingredients of [match] that are not yet open on the list.
List<String> missingNotOnList(List<ShoppingNote> notes, RecipeMatch match) => [
  for (final name in match.missingNames)
    if (!isOpenOnList(notes, name)) name,
];

/// Unchecked items across every note (shown on the Profile menu tile).
final shoppingOpenItemCountProvider = Provider<int>(
  (ref) => ref
      .watch(shoppingNotesProvider)
      .fold(0, (sum, note) => sum + note.openItemCount),
);
