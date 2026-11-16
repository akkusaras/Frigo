import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/router/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/date_format.dart';
import '../../core/widgets/frigo_widgets.dart';
import '../../models/models.dart';
import '../../providers/fridge_overview_provider.dart';
import '../../providers/fridge_provider.dart';
import '../../providers/profile_provider.dart';
import '../../providers/repository_providers.dart';
import 'fridge_cabinet.dart';

/// `2. My Fridge` — the visual fridge home screen.
class FridgeScreen extends ConsumerWidget {
  const FridgeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final count = ref.watch(fridgeProvider).length;
    final shelves = ref.watch(fridgeShelvesProvider);
    final alert = ref.watch(fridgeExpiryAlertProvider);
    final initials = ref.watch(profileProvider).initials;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            ScreenHeader(
              title: 'My Fridge',
              subtitle: count == 1 ? '1 item' : '$count items',
              trailing: [
                IconButton.outlined(
                  tooltip: 'Shopping list',
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.card,
                    side: const BorderSide(color: AppColors.border),
                  ),
                  onPressed: context.pushShoppingList,
                  icon: const Icon(Icons.door_front_door_outlined),
                ),
                FrigoAvatar(initials: initials, onTap: context.pushProfile),
              ],
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                children: [
                  if (alert != null) ...[
                    AlertBanner(
                      key: const Key('expiry-banner'),
                      message: alert.message,
                    ),
                    const SizedBox(height: 16),
                  ],
                  FridgeCabinet(
                    key: const Key('fridge-container'),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        for (final shelf in ShelfCategory.values)
                          _Shelf(
                            shelf: shelf,
                            items: shelves[shelf] ?? const [],
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomActions(
        children: [
          OutlinedButton(
            onPressed: context.pushAddIngredients,
            child: const Text('+ Add ingredients'),
          ),
          FilledButton(
            onPressed: context.pushRecipeSuggestions,
            child: const Text('Suggest recipes'),
          ),
        ],
      ),
    );
  }
}

class _Shelf extends StatelessWidget {
  const _Shelf({required this.shelf, required this.items});

  final ShelfCategory shelf;
  final List<Ingredient> items;

  @override
  Widget build(BuildContext context) {
    final isDrawer = shelf == ShelfCategory.vegetableDrawer;
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          shelf.shelfLabel,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: AppColors.charcoal.withValues(alpha: 0.75),
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 8),
        if (items.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Text(
              'Nothing here yet',
              style: Theme.of(context).textTheme.bodySmall
                  ?.copyWith(color: AppColors.charcoal.withValues(alpha: 0.6)),
            ),
          )
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [for (final item in items) _ItemTile(item: item)],
          ),
      ],
    );

    if (isDrawer) {
      return Padding(
        padding: const EdgeInsets.only(top: 14),
        child: CrisperDrawer(
          key: Key('shelf-${shelf.name}'),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 72),
            child: content,
          ),
        ),
      );
    }

    // Items rest directly on a tempered-glass shelf.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          key: Key('shelf-${shelf.name}'),
          constraints: const BoxConstraints(minHeight: 84),
          padding: const EdgeInsets.fromLTRB(4, 6, 4, 6),
          alignment: Alignment.bottomLeft,
          child: content,
        ),
        const GlassShelf(),
        const SizedBox(height: 10),
      ],
    );
  }
}

class _ItemTile extends ConsumerWidget {
  const _ItemTile({required this.item});

  final Ingredient item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = ref.watch(clockProvider)();
    final badge = item.expiryBadge(now);

    return Material(
      key: Key('fridge-item-${item.id}'),
      color: AppColors.card,
      elevation: 2,
      shadowColor: const Color(0x551A2421),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: badge != null ? AppColors.coral : AppColors.border,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          HapticFeedback.lightImpact();
          _showDetails(context, item);
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                item.name,
                style: const TextStyle(
                  color: AppColors.charcoal,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (badge != null) ...[
                const SizedBox(width: 6),
                ExpiryBadge(label: badge),
              ],
            ],
          ),
        ),
      ),
    );
  }

  static Future<void> _showDetails(BuildContext context, Ingredient item) {
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.card,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetContext) => IngredientDetailsSheet(
        ingredientId: item.id,
        onRemoved: (name) => ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text('$name removed'))),
      ),
    );
  }
}

/// Bottom sheet for a single fridge item: shows its shelf, quantity and
/// expiry, lets the user change the expiry date (quick day offsets or a
/// calendar picker) and remove the item. Watches [fridgeProvider] so every
/// edit is reflected in place.
class IngredientDetailsSheet extends ConsumerWidget {
  const IngredientDetailsSheet({
    super.key,
    required this.ingredientId,
    this.onRemoved,
  });

  final String ingredientId;

  /// Called with the item's name after it is removed from the fridge.
  final ValueChanged<String>? onRemoved;

  static const _quickOffsets = [
    (label: 'Today', days: 0),
    (label: 'Tomorrow', days: 1),
    (label: 'In 3 days', days: 3),
    (label: 'In 1 week', days: 7),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final item = ref
        .watch(fridgeProvider)
        .where((i) => i.id == ingredientId)
        .firstOrNull;
    if (item == null) return const SizedBox.shrink();

    final now = ref.watch(clockProvider)();
    final today = DateTime(now.year, now.month, now.day);
    final badge = item.expiryBadge(now);
    final days = item.daysUntilExpiry(now);
    final expiryText = switch (days) {
      null => 'No expiry date',
      < 0 => 'Expired ${-days} ${-days == 1 ? 'day' : 'days'} ago',
      0 => 'Expires today',
      1 => 'Expires tomorrow',
      _ => 'Expires in $days days',
    };
    final textTheme = Theme.of(context).textTheme;
    final notifier = ref.read(fridgeProvider.notifier);

    void setExpiry(DateTime? date) {
      HapticFeedback.lightImpact();
      notifier.updateExpiry(item.id, date);
    }

    Future<void> pickDate() async {
      final current = item.expiresOn;
      final first = today.subtract(const Duration(days: 365));
      final last = today.add(const Duration(days: 365 * 3));
      var initial = current == null
          ? today
          : DateTime(current.year, current.month, current.day);
      if (initial.isBefore(first)) initial = first;
      if (initial.isAfter(last)) initial = last;
      final picked = await showDatePicker(
        context: context,
        initialDate: initial,
        firstDate: first,
        lastDate: last,
        helpText: 'Expiry date',
        confirmText: 'Save',
      );
      if (picked != null) setExpiry(picked);
    }

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: Text(item.name, style: textTheme.titleLarge)),
                if (badge != null) ExpiryBadge(label: badge),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              [
                item.shelf.displayName,
                if (item.quantity != null) item.quantity!,
              ].join(' · '),
              style: textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            InkWell(
              key: const Key('expiry-edit'),
              borderRadius: BorderRadius.circular(8),
              onTap: pickDate,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    Expanded(
                      child: Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: expiryText,
                              style: TextStyle(
                                color: badge != null
                                    ? AppColors.coral
                                    : AppColors.charcoal,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            if (item.expiresOn != null)
                              TextSpan(
                                text: ' · ${formatShortDate(item.expiresOn!)}',
                                style: textTheme.bodySmall,
                              ),
                          ],
                        ),
                      ),
                    ),
                    const Icon(
                      Icons.edit_calendar_outlined,
                      size: 20,
                      color: AppColors.charcoal,
                      semanticLabel: 'Edit expiry date',
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'CHANGE EXPIRY DATE',
              style: textTheme.labelSmall?.copyWith(
                color: AppColors.charcoal.withValues(alpha: 0.75),
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final offset in _quickOffsets)
                  ActionChip(
                    key: Key('expiry-offset-${offset.days}'),
                    label: Text(offset.label),
                    onPressed: () =>
                        setExpiry(today.add(Duration(days: offset.days))),
                  ),
                ActionChip(
                  key: const Key('expiry-pick-date'),
                  avatar: const Icon(Icons.calendar_today_outlined, size: 16),
                  label: const Text('Pick a date'),
                  onPressed: pickDate,
                ),
                if (item.expiresOn != null)
                  ActionChip(
                    key: const Key('expiry-clear'),
                    label: const Text('No expiry'),
                    onPressed: () => setExpiry(null),
                  ),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.coral,
                ),
                onPressed: () {
                  Navigator.of(context).pop();
                  notifier.remove(item.id);
                  onRemoved?.call(item.name);
                },
                icon: const Icon(Icons.delete_outline_rounded),
                label: const Text('Remove from fridge'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
