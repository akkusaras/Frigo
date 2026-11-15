import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/router/app_router.dart';
import '../../core/router/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/frigo_widgets.dart';
import '../../models/models.dart';
import '../../providers/fridge_provider.dart';
import '../../providers/repository_providers.dart';
import '../../providers/service_providers.dart';

/// `5. Check what we found` — confirm ingredients detected from a scan.
class ScanConfirmationScreen extends ConsumerStatefulWidget {
  const ScanConfirmationScreen({super.key, required this.source});

  final ScanSource source;

  @override
  ConsumerState<ScanConfirmationScreen> createState() =>
      _ScanConfirmationScreenState();
}

class _ScanRow {
  _ScanRow({required this.name, required this.shelf, required this.checked});

  final String name;
  ShelfCategory shelf;
  bool checked;
}

class _ScanConfirmationScreenState
    extends ConsumerState<ScanConfirmationScreen> {
  final _missedController = TextEditingController();
  late final List<_ScanRow> _rows;
  late final int _foundCount;

  @override
  void initState() {
    super.initState();
    final scanner = ref.read(ingredientScannerProvider);
    final detected = widget.source == ScanSource.receipt
        ? scanner.scanReceipt()
        : scanner.scanPhoto();
    _foundCount = detected.length;
    _rows = [
      for (final d in detected)
        _ScanRow(name: d.name, shelf: d.shelf, checked: d.confident),
    ];
  }

  @override
  void dispose() {
    _missedController.dispose();
    super.dispose();
  }

  int get _selectedCount => _rows.where((r) => r.checked).length;

  void _addMissed() {
    final catalog = ref.read(ingredientCatalogProvider);
    final name = catalog.canonicalName(_missedController.text);
    if (name.isEmpty) return;
    final key = normalizeIngredientName(name);
    setState(() {
      _missedController.clear();
      for (final row in _rows) {
        if (normalizeIngredientName(row.name) == key) {
          row.checked = true;
          return;
        }
      }
      _rows.add(
        _ScanRow(name: name, shelf: catalog.shelfFor(name), checked: true),
      );
    });
  }

  void _save() {
    final selected = _rows.where((r) => r.checked).toList();
    if (selected.isEmpty) return;
    final catalog = ref.read(ingredientCatalogProvider);
    final notifier = ref.read(fridgeProvider.notifier);
    final now = ref.read(clockProvider)();
    final reserved = <String>{};
    final items = <Ingredient>[];
    for (final row in selected) {
      final id = notifier.newId(row.name, reserved: reserved);
      reserved.add(id);
      items.add(
        Ingredient(
          id: id,
          name: row.name,
          shelf: row.shelf,
          expiresOn: catalog.estimatedExpiry(row.name, now),
        ),
      );
    }
    notifier.addAll(items);
    final messenger = ScaffoldMessenger.of(context);
    context.goToFridge();
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          items.length == 1
              ? '${items.single.name} added to your fridge'
              : '${items.length} items added to your fridge',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final isReceipt = widget.source == ScanSource.receipt;
    final selected = _selectedCount;

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.only(bottom: 16),
          children: [
            const ScreenHeader(title: 'Check what we found', showBack: true),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    key: const Key('scan-preview'),
                    height: 160,
                    decoration: BoxDecoration(
                      color: AppColors.mint.withValues(alpha: 0.35),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          isReceipt
                              ? Icons.receipt_long_outlined
                              : Icons.photo_outlined,
                          size: 48,
                          color: AppColors.charcoal,
                        ),
                        const SizedBox(height: 8),
                        Text(isReceipt ? 'Receipt scan' : 'Fridge photo'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '$_foundCount ingredients found. Untick anything that is '
                    'wrong.',
                    style: textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 12),
                  Card(
                    child: Column(
                      children: [
                        for (var i = 0; i < _rows.length; i++) ...[
                          if (i > 0) const Divider(height: 1),
                          _ScanTile(
                            row: _rows[i],
                            onChanged: (value) =>
                                setState(() => _rows[i].checked = value),
                            onShelfChanged: (shelf) =>
                                setState(() => _rows[i].shelf = shelf),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          key: const Key('scan-missed-input'),
                          controller: _missedController,
                          textCapitalization: TextCapitalization.sentences,
                          textInputAction: TextInputAction.done,
                          onSubmitted: (_) => _addMissed(),
                          decoration: const InputDecoration(
                            hintText: 'Add something we missed',
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      IconButton.filled(
                        key: const Key('scan-missed-add'),
                        tooltip: 'Add ingredient',
                        style: IconButton.styleFrom(
                          backgroundColor: AppColors.charcoal,
                          foregroundColor: Colors.white,
                          minimumSize: const Size(52, 52),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        onPressed: _addMissed,
                        icon: const Icon(Icons.add_rounded),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomActions(
        children: [
          FilledButton(
            key: const Key('scan-save'),
            onPressed: selected == 0 ? null : _save,
            style: FilledButton.styleFrom(
              disabledBackgroundColor: AppColors.border,
              disabledForegroundColor: AppColors.mutedText,
            ),
            child: Text('Save $selected to my fridge'),
          ),
        ],
      ),
    );
  }
}

class _ScanTile extends StatelessWidget {
  const _ScanTile({
    required this.row,
    required this.onChanged,
    required this.onShelfChanged,
  });

  final _ScanRow row;
  final ValueChanged<bool> onChanged;
  final ValueChanged<ShelfCategory> onShelfChanged;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return InkWell(
      key: Key('scan-row-${row.name}'),
      onTap: () => onChanged(!row.checked),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(6, 4, 8, 4),
        child: Row(
          children: [
            Checkbox(
              value: row.checked,
              onChanged: (value) => onChanged(value ?? false),
            ),
            Expanded(
              child: Text(
                row.name,
                style: textTheme.titleMedium?.copyWith(
                  color: row.checked ? AppColors.charcoal : AppColors.mutedText,
                  decoration: row.checked ? null : TextDecoration.lineThrough,
                ),
              ),
            ),
            if (row.checked)
              PopupMenuButton<ShelfCategory>(
                key: Key('scan-shelf-${row.name}'),
                tooltip: 'Change shelf',
                initialValue: row.shelf,
                onSelected: onShelfChanged,
                itemBuilder: (_) => [
                  for (final shelf in ShelfCategory.values)
                    PopupMenuItem(value: shelf, child: Text(shelf.displayName)),
                ],
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(row.shelf.displayName, style: textTheme.bodySmall),
                      const Icon(
                        Icons.expand_more_rounded,
                        size: 18,
                        color: AppColors.mutedText,
                      ),
                    ],
                  ),
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.only(right: 18),
                child: Text(
                  'Not added',
                  style: textTheme.bodySmall?.copyWith(color: AppColors.coral),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
