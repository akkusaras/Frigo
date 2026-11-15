import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/router/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/frigo_widgets.dart';
import '../../models/models.dart';
import '../../providers/fridge_overview_provider.dart';
import '../../providers/fridge_provider.dart';
import '../../providers/profile_provider.dart';
import '../../providers/repository_providers.dart';

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
                  Container(
                    key: const Key('fridge-container'),
                    padding: const EdgeInsets.fromLTRB(14, 8, 14, 14),
                    decoration: BoxDecoration(
                      color: AppColors.mint,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: AppColors.charcoal, width: 2),
                    ),
                    child: Column(
                      children: [
                        for (final shelf in ShelfCategory.values)
                          _Shelf(
                            shelf: shelf,
                            items: shelves[shelf] ?? const [],
                            isLast: shelf == ShelfCategory.values.last,
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
  const _Shelf({
    required this.shelf,
    required this.items,
    required this.isLast,
  });

  final ShelfCategory shelf;
  final List<Ingredient> items;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final isDrawer = shelf == ShelfCategory.vegetableDrawer;
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          shelf.shelfLabel,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: AppColors.charcoal,
              ),
        ),
        const SizedBox(height: 8),
        if (items.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Text(
              'Nothing here yet',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.charcoal.withValues(alpha: 0.6),
                  ),
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

    return Container(
      key: Key('shelf-${shelf.name}'),
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 96),
      margin: EdgeInsets.only(top: isDrawer ? 12 : 6),
      padding: isDrawer
          ? const EdgeInsets.all(10)
          : const EdgeInsets.fromLTRB(4, 6, 4, 12),
      decoration: isDrawer
          ? BoxDecoration(
              color: AppColors.card.withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.charcoal, width: 2),
            )
          : BoxDecoration(
              border: isLast
                  ? null
                  : const Border(
                      bottom: BorderSide(color: AppColors.charcoal, width: 2),
                    ),
            ),
      child: content,
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
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: badge != null ? AppColors.coral : AppColors.border,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _showDetails(context, ref, item, badge),
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

  static Future<void> _showDetails(
    BuildContext context,
    WidgetRef ref,
    Ingredient item,
    String? badge,
  ) {
    final now = ref.read(clockProvider)();
    final days = item.daysUntilExpiry(now);
    final expiryText = switch (days) {
      null => 'No expiry date',
      < 0 => 'Expired ${-days} ${-days == 1 ? 'day' : 'days'} ago',
      0 => 'Expires today',
      1 => 'Expires tomorrow',
      _ => 'Expires in $days days',
    };
    final textTheme = Theme.of(context).textTheme;

    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.card,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(item.name, style: textTheme.titleLarge),
                  ),
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
              Text(
                expiryText,
                style: TextStyle(
                  color: badge != null ? AppColors.coral : AppColors.charcoal,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.coral,
                  ),
                  onPressed: () {
                    ref.read(fridgeProvider.notifier).remove(item.id);
                    Navigator.of(sheetContext).pop();
                    ScaffoldMessenger.of(context)
                      ..hideCurrentSnackBar()
                      ..showSnackBar(
                        SnackBar(content: Text('${item.name} removed')),
                      );
                  },
                  icon: const Icon(Icons.delete_outline_rounded),
                  label: const Text('Remove from fridge'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
