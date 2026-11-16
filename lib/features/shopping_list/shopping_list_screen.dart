import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/router/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/frigo_widgets.dart';
import '../../models/models.dart';
import '../../providers/shopping_provider.dart';
import 'fridge_door.dart';

Color noteColor(NoteColor color) => switch (color) {
  NoteColor.yellow => AppColors.noteYellow,
  NoteColor.pink => AppColors.notePink,
};

/// `3. Shopping list` — sticky notes on the fridge door.
class ShoppingListScreen extends ConsumerWidget {
  const ShoppingListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notes = ref.watch(shoppingNotesProvider);
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            ScreenHeader(
              title: 'Shopping list',
              subtitle: 'Notes on your fridge door',
              showBack: true,
              trailing: [FrigoAvatar(onTap: context.pushProfile)],
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: FridgeDoor(
                  key: const Key('fridge-door'),
                  child: ListView(
                    key: const Key('shopping-list'),
                    padding: const EdgeInsets.fromLTRB(20, 24, 52, 24),
                    children: [
                      if (notes.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 24),
                          child: Text(
                            'Your fridge door is clear. Add a note to start '
                            'a list.',
                            key: const Key('shopping-empty'),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: AppColors.charcoal.withValues(alpha: 0.7),
                            ),
                          ),
                        ),
                      for (var i = 0; i < notes.length; i++) ...[
                        StickyNoteCard(
                          note: notes[i],
                          tilt: i.isEven ? -1.2 : 1,
                        ),
                        const SizedBox(height: 20),
                      ],
                      OutlinedButton(
                        key: const Key('add-note'),
                        style: OutlinedButton.styleFrom(
                          backgroundColor: Colors.white.withValues(alpha: 0.85),
                          side: BorderSide(
                            color: AppColors.charcoal.withValues(alpha: 0.2),
                          ),
                        ),
                        onPressed: () => showAddNoteDialog(context, ref),
                        child: const Text('+ Add a note'),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Missing ingredients from recipes land here '
                        'automatically.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppColors.charcoal.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomActions(
        children: [
          FilledButton(
            key: const Key('open-fridge'),
            onPressed: context.goToFridge,
            child: const Text('Open the fridge'),
          ),
        ],
      ),
    );
  }
}

/// A pastel sticky note with checkable lines.
class StickyNoteCard extends ConsumerWidget {
  const StickyNoteCard({super.key, required this.note, this.tilt = 0});

  final ShoppingNote note;

  /// Slight rotation (in degrees) so the notes look hand-stuck.
  final double tilt;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(shoppingNotesProvider.notifier);
    final textTheme = Theme.of(context).textTheme;
    void toggle(String itemId) {
      HapticFeedback.lightImpact();
      notifier.toggleItem(note.id, itemId);
    }
    return Transform.rotate(
      angle: tilt * math.pi / 180,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            key: Key('note-${note.id}'),
            padding: const EdgeInsets.fromLTRB(16, 14, 8, 10),
            decoration: BoxDecoration(
              color: noteColor(note.color),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(3),
                topRight: Radius.circular(3),
                bottomLeft: Radius.circular(4),
                bottomRight: Radius.circular(14),
              ),
              boxShadow: const [
                // Contact shadow where the paper meets the door.
                BoxShadow(
                  color: Color(0x1F1A2421),
                  blurRadius: 2,
                  offset: Offset(0, 1),
                ),
                // Lifted, curling bottom edge.
                BoxShadow(
                  color: Color(0x2E1A2421),
                  blurRadius: 14,
                  spreadRadius: -4,
                  offset: Offset(2, 10),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        note.title,
                        style: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    IconButton(
                      key: Key('note-add-item-${note.id}'),
                      tooltip: 'Add item',
                      visualDensity: VisualDensity.compact,
                      icon: const Icon(Icons.add_rounded, size: 20),
                      onPressed: () => _addItem(context, ref),
                    ),
                    IconButton(
                      key: Key('note-remove-${note.id}'),
                      tooltip: 'Remove note',
                      visualDensity: VisualDensity.compact,
                      icon: const Icon(Icons.close_rounded, size: 20),
                      onPressed: () => _remove(context, ref),
                    ),
                  ],
                ),
                if (note.items.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      'Nothing on this note yet.',
                      style: TextStyle(color: AppColors.mutedText),
                    ),
                  ),
                for (final item in note.items)
                  InkWell(
                    key: Key('shopping-item-${item.id}'),
                    onTap: () => toggle(item.id),
                    child: Row(
                      children: [
                        Checkbox(
                          key: Key('shopping-check-${item.id}'),
                          value: item.isChecked,
                          activeColor: AppColors.charcoal,
                          side: const BorderSide(
                            color: AppColors.charcoal,
                            width: 1.5,
                          ),
                          onChanged: (_) => toggle(item.id),
                        ),
                        Expanded(
                          child: Text(
                            item.name,
                            style: TextStyle(
                              color: item.isChecked
                                  ? AppColors.mutedText
                                  : AppColors.charcoal,
                              decoration: item.isChecked
                                  ? TextDecoration.lineThrough
                                  : null,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          Positioned(
            top: -7,
            left: 0,
            right: 0,
            child: Center(child: _Magnet(color: note.color)),
          ),
        ],
      ),
    );
  }

  Future<void> _addItem(BuildContext context, WidgetRef ref) async {
    final name = await showDialog<String>(
      context: context,
      builder: (_) => _AddItemDialog(noteTitle: note.title),
    );
    if (name == null || name.trim().isEmpty) return;
    final added = ref
        .read(shoppingNotesProvider.notifier)
        .addItem(note.id, name);
    if (!added && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${name.trim()} is already on this note')),
      );
    }
  }

  void _remove(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(shoppingNotesProvider.notifier);
    final before = ref.read(shoppingNotesProvider);
    notifier.removeNote(note.id);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text('"${note.title}" removed'),
          action: SnackBarAction(
            label: 'Undo',
            onPressed: () => notifier.restore(before),
          ),
        ),
      );
  }
}

/// A round fridge magnet pinning a sticky note to the door.
class _Magnet extends StatelessWidget {
  const _Magnet({required this.color});

  final NoteColor color;

  @override
  Widget build(BuildContext context) {
    final base = switch (color) {
      NoteColor.yellow => AppColors.coral,
      NoteColor.pink => AppColors.charcoal,
    };
    return Container(
      width: 16,
      height: 16,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          center: const Alignment(-0.35, -0.4),
          colors: [Color.lerp(base, Colors.white, 0.55)!, base],
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x401A2421),
            blurRadius: 3,
            offset: Offset(1, 2),
          ),
        ],
      ),
    );
  }
}

class _AddItemDialog extends StatefulWidget {
  const _AddItemDialog({required this.noteTitle});

  final String noteTitle;

  @override
  State<_AddItemDialog> createState() => _AddItemDialogState();
}

class _AddItemDialogState extends State<_AddItemDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() => Navigator.of(context).pop(_controller.text);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Add to "${widget.noteTitle}"'),
      content: TextField(
        key: const Key('add-item-field'),
        controller: _controller,
        autofocus: true,
        textCapitalization: TextCapitalization.sentences,
        decoration: const InputDecoration(hintText: 'e.g. Lemons'),
        onSubmitted: (_) => _submit(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          key: const Key('add-item-confirm'),
          onPressed: _submit,
          child: const Text('Add'),
        ),
      ],
    );
  }
}

/// Opens the `+ Add a note` dialog and sticks the result on the door.
Future<void> showAddNoteDialog(BuildContext context, WidgetRef ref) async {
  final draft = await showDialog<_NoteDraft>(
    context: context,
    builder: (_) => const _AddNoteDialog(),
  );
  if (draft == null) return;
  ref
      .read(shoppingNotesProvider.notifier)
      .addNote(title: draft.title, color: draft.color, items: draft.items);
}

class _NoteDraft {
  const _NoteDraft(this.title, this.color, this.items);

  final String title;
  final NoteColor color;
  final List<String> items;
}

class _AddNoteDialog extends StatefulWidget {
  const _AddNoteDialog();

  @override
  State<_AddNoteDialog> createState() => _AddNoteDialogState();
}

class _AddNoteDialogState extends State<_AddNoteDialog> {
  final _title = TextEditingController();
  final _items = TextEditingController();
  var _color = NoteColor.pink;
  String? _error;

  @override
  void dispose() {
    _title.dispose();
    _items.dispose();
    super.dispose();
  }

  void _submit() {
    if (_title.text.trim().isEmpty) {
      setState(() => _error = 'Give your note a title');
      return;
    }
    Navigator.of(
      context,
    ).pop(_NoteDraft(_title.text, _color, _items.text.split(RegExp(r'[,\n]'))));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add a note'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              key: const Key('note-title-field'),
              controller: _title,
              autofocus: true,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                labelText: 'Title',
                hintText: 'e.g. Weekly',
                errorText: _error,
              ),
              onChanged: (_) {
                if (_error != null) setState(() => _error = null);
              },
            ),
            const SizedBox(height: 12),
            TextField(
              key: const Key('note-items-field'),
              controller: _items,
              minLines: 1,
              maxLines: 4,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Items',
                hintText: 'Milk, Bread',
                helperText: 'Separate items with commas',
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                for (final color in NoteColor.values) ...[
                  _ColorSwatch(
                    color: color,
                    selected: color == _color,
                    onTap: () => setState(() => _color = color),
                  ),
                  const SizedBox(width: 12),
                ],
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          key: const Key('note-save'),
          onPressed: _submit,
          child: const Text('Stick it on'),
        ),
      ],
    );
  }
}

class _ColorSwatch extends StatelessWidget {
  const _ColorSwatch({
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final NoteColor color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '${color.name} note',
      selected: selected,
      button: true,
      child: InkWell(
        key: Key('note-color-${color.name}'),
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: noteColor(color),
            shape: BoxShape.circle,
            border: Border.all(
              color: selected ? AppColors.charcoal : AppColors.border,
              width: selected ? 2 : 1,
            ),
          ),
          child: selected ? const Icon(Icons.check_rounded, size: 18) : null,
        ),
      ),
    );
  }
}
