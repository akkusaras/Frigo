import 'package:flutter/foundation.dart';

/// Pastel colour of a sticky note on the fridge door.
enum NoteColor { yellow, pink }

/// A single checkable line on a sticky note.
@immutable
class ShoppingItem {
  const ShoppingItem({
    required this.id,
    required this.name,
    this.isChecked = false,
  });

  final String id;
  final String name;
  final bool isChecked;

  ShoppingItem copyWith({String? name, bool? isChecked}) => ShoppingItem(
        id: id,
        name: name ?? this.name,
        isChecked: isChecked ?? this.isChecked,
      );

  @override
  bool operator ==(Object other) =>
      other is ShoppingItem &&
      other.id == id &&
      other.name == name &&
      other.isChecked == isChecked;

  @override
  int get hashCode => Object.hash(id, name, isChecked);

  @override
  String toString() => 'ShoppingItem($name${isChecked ? ', checked' : ''})';
}

/// A sticky note grouping shopping items by recipe (`For cacık`) or by
/// category (`Weekly`).
@immutable
class ShoppingNote {
  ShoppingNote({
    required this.id,
    required this.title,
    required this.color,
    required List<ShoppingItem> items,
    this.recipeId,
  }) : items = List.unmodifiable(items);

  final String id;
  final String title;
  final NoteColor color;
  final List<ShoppingItem> items;

  /// Recipe that produced this note, when it was filled automatically.
  final String? recipeId;

  int get openItemCount => items.where((i) => !i.isChecked).length;

  ShoppingNote copyWith({
    String? title,
    NoteColor? color,
    List<ShoppingItem>? items,
  }) {
    return ShoppingNote(
      id: id,
      title: title ?? this.title,
      color: color ?? this.color,
      items: items ?? this.items,
      recipeId: recipeId,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is ShoppingNote &&
      other.id == id &&
      other.title == title &&
      other.color == color &&
      listEquals(other.items, items) &&
      other.recipeId == recipeId;

  @override
  int get hashCode =>
      Object.hash(id, title, color, Object.hashAll(items), recipeId);

  @override
  String toString() => 'ShoppingNote($title, ${items.length} items)';
}
