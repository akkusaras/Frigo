import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/router/app_router.dart';
import '../../core/router/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/date_format.dart';
import '../../core/widgets/frigo_widgets.dart';
import '../../models/models.dart';
import '../../providers/fridge_provider.dart';
import '../../providers/repository_providers.dart';
import '../../providers/service_providers.dart';

/// `4. Add ingredients` — photo, receipt or manual entry.
class AddIngredientsScreen extends ConsumerStatefulWidget {
  const AddIngredientsScreen({super.key});

  @override
  ConsumerState<AddIngredientsScreen> createState() =>
      _AddIngredientsScreenState();
}

class _AddIngredientsScreenState extends ConsumerState<AddIngredientsScreen> {
  final _nameController = TextEditingController();
  final _expiryController = TextEditingController();
  DateTime? _expiry;

  /// Shelf picked by the user; `null` means "use the catalog's guess".
  ShelfCategory? _shelfOverride;

  @override
  void initState() {
    super.initState();
    _nameController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _nameController.dispose();
    _expiryController.dispose();
    super.dispose();
  }

  String get _name => _nameController.text.trim();

  ShelfCategory get _shelf =>
      _shelfOverride ?? ref.read(ingredientCatalogProvider).shelfFor(_name);

  void _pickSuggestion(String name) {
    _nameController.value = TextEditingValue(
      text: name,
      selection: TextSelection.collapsed(offset: name.length),
    );
    setState(() => _shelfOverride = null);
    FocusScope.of(context).unfocus();
  }

  Future<void> _pickExpiry() async {
    final now = ref.read(clockProvider)();
    final today = DateTime(now.year, now.month, now.day);
    final picked = await showDatePicker(
      context: context,
      initialDate: _expiry ??
          ref.read(ingredientCatalogProvider).estimatedExpiry(_name, now) ??
          today.add(const Duration(days: 3)),
      firstDate: today,
      lastDate: today.add(const Duration(days: 365)),
      helpText: 'Expiry date',
    );
    if (picked == null || !mounted) return;
    setState(() {
      _expiry = picked;
      _expiryController.text = formatShortDate(picked);
    });
  }

  void _clearExpiry() => setState(() {
        _expiry = null;
        _expiryController.clear();
      });

  void _addToFridge() {
    if (_name.isEmpty) return;
    final catalog = ref.read(ingredientCatalogProvider);
    final notifier = ref.read(fridgeProvider.notifier);
    final name = catalog.canonicalName(_name);
    final now = ref.read(clockProvider)();
    final shelf = _shelf;
    notifier.add(
      Ingredient(
        id: notifier.newId(name),
        name: name,
        shelf: shelf,
        expiresOn: _expiry ?? catalog.estimatedExpiry(name, now),
      ),
    );
    final messenger = ScaffoldMessenger.of(context);
    context.goToFridge();
    messenger.showSnackBar(
      SnackBar(content: Text('$name added to ${shelf.displayName}')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final catalog = ref.watch(ingredientCatalogProvider);
    final suggestions = [
      for (final s in catalog.suggestions(_name))
        if (normalizeIngredientName(s) != normalizeIngredientName(_name)) s,
    ];
    final hasName = _name.isNotEmpty;
    final estimate = hasName
        ? catalog.estimatedExpiry(_name, ref.watch(clockProvider)())
        : null;

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.only(bottom: 24),
          children: [
            const ScreenHeader(title: 'Add ingredients', showBack: true),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _CaptureCard(
                          key: const Key('capture-photo'),
                          icon: Icons.photo_camera_outlined,
                          title: 'Take a photo',
                          subtitle: 'Of your fridge or groceries',
                          onTap: () =>
                              context.pushScanConfirmation(ScanSource.photo),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _CaptureCard(
                          key: const Key('capture-receipt'),
                          icon: Icons.receipt_long_outlined,
                          title: 'Scan a receipt',
                          subtitle: 'We read the items for you',
                          onTap: () =>
                              context.pushScanConfirmation(ScanSource.receipt),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),
                  const SectionLabel('Or type it in'),
                  const SizedBox(height: 12),
                  Text('Ingredient', style: textTheme.titleMedium),
                  const SizedBox(height: 8),
                  TextField(
                    key: const Key('ingredient-input'),
                    controller: _nameController,
                    textCapitalization: TextCapitalization.sentences,
                    textInputAction: TextInputAction.done,
                    onChanged: (_) => _shelfOverride = null,
                    onSubmitted: (_) => _addToFridge(),
                    decoration: const InputDecoration(
                      hintText: 'e.g. Spinach',
                      prefixIcon: Icon(Icons.search_rounded),
                    ),
                  ),
                  if (suggestions.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final s in suggestions)
                          ActionChip(
                            key: Key('suggestion-$s'),
                            label: Text(s),
                            onPressed: () => _pickSuggestion(s),
                          ),
                      ],
                    ),
                  ],
                  if (hasName) ...[
                    const SizedBox(height: 18),
                    Text('Shelf', style: textTheme.titleMedium),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final shelf in ShelfCategory.values)
                          ChoiceChip(
                            key: Key('shelf-choice-${shelf.name}'),
                            label: Text(shelf.displayName),
                            selected: _shelf == shelf,
                            onSelected: (_) =>
                                setState(() => _shelfOverride = shelf),
                          ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Text('Expiry date', style: textTheme.titleMedium),
                      const SizedBox(width: 6),
                      Text('(optional)', style: textTheme.bodySmall),
                    ],
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    key: const Key('expiry-input'),
                    controller: _expiryController,
                    readOnly: true,
                    onTap: _pickExpiry,
                    decoration: InputDecoration(
                      hintText: 'e.g. 20 Nov',
                      prefixIcon: const Icon(Icons.event_outlined),
                      suffixIcon: _expiry == null
                          ? null
                          : IconButton(
                              tooltip: 'Clear expiry date',
                              onPressed: _clearExpiry,
                              icon: const Icon(Icons.close_rounded),
                            ),
                    ),
                  ),
                  if (_expiry == null && estimate != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      'Leave empty and we will use ${formatShortDate(estimate)}.',
                      key: const Key('expiry-estimate'),
                      style: textTheme.bodySmall,
                    ),
                  ],
                  const SizedBox(height: 24),
                  FilledButton(
                    key: const Key('add-to-fridge'),
                    onPressed: hasName ? _addToFridge : null,
                    style: FilledButton.styleFrom(
                      disabledBackgroundColor: AppColors.border,
                      disabledForegroundColor: AppColors.mutedText,
                    ),
                    child: const Text('Add to fridge'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CaptureCard extends StatelessWidget {
  const _CaptureCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.mint.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: AppColors.charcoal),
              ),
              const SizedBox(height: 14),
              Text(title, style: textTheme.titleMedium),
              const SizedBox(height: 4),
              Text(subtitle, style: textTheme.bodySmall),
            ],
          ),
        ),
      ),
    );
  }
}
