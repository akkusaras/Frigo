import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/router/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/frigo_widgets.dart';
import '../../models/models.dart';
import '../../providers/auth_provider.dart';
import '../../providers/profile_provider.dart';
import '../../providers/shopping_provider.dart';

/// `7. Profile` — user summary, stats and settings menu.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileProvider);
    final openItems = ref.watch(shoppingOpenItemCountProvider);
    final textTheme = Theme.of(context).textTheme;

    final tags = [
      ...profile.allergyLabels,
      if (profile.diet != Diet.none) profile.diet.label,
    ];

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.only(bottom: 24),
          children: [
            const ScreenHeader(title: 'Profile', showBack: true),
            const SizedBox(height: 8),
            Center(child: FrigoAvatar(initials: profile.initials, size: 84)),
            const SizedBox(height: 12),
            Center(child: Text(profile.name, style: textTheme.titleLarge)),
            Center(child: Text(profile.email, style: textTheme.bodySmall)),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      key: const Key('stat-favorites'),
                      value: profile.favoritesCount,
                      label: 'Favorites',
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _StatCard(
                      key: const Key('stat-meals-cooked'),
                      value: profile.mealsCooked,
                      label: 'Meals cooked',
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _StatCard(
                      key: const Key('stat-items-saved'),
                      value: profile.itemsSaved,
                      label: 'Items saved',
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Card(
                clipBehavior: Clip.antiAlias,
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.favorite_border_rounded),
                      title: const Text('Favorite recipes'),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: context.pushFavorites,
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.health_and_safety_outlined),
                      title: const Text('Allergies and diet'),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: tags.isEmpty
                            ? Text('None set', style: textTheme.bodySmall)
                            : Wrap(
                                spacing: 6,
                                runSpacing: 6,
                                children: [
                                  for (final tag in tags) _Tag(label: tag),
                                ],
                              ),
                      ),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: context.pushAllergies,
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.sticky_note_2_outlined),
                      title: const Text('Shopping list'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            openItems == 1 ? '1 item' : '$openItems items',
                            style: textTheme.bodySmall,
                          ),
                          const Icon(Icons.chevron_right_rounded),
                        ],
                      ),
                      onTap: context.pushShoppingList,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.coral,
                ),
                onPressed: () {
                  ref.read(authProvider.notifier).signOut();
                  context.goToLogin();
                },
                child: const Text('Log out'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({super.key, required this.value, required this.label});

  final int value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        child: Column(
          children: [
            Text('$value', style: textTheme.titleLarge),
            const SizedBox(height: 4),
            Text(label, style: textTheme.bodySmall, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

/// Small coral pill for an active allergy / diet tag.
class _Tag extends StatelessWidget {
  const _Tag({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.coralSurface,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: AppColors.coral,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
