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
