import 'package:flutter/material.dart';

import '../../core/router/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/frigo_widgets.dart';

/// `7. Profile` — user summary, stats and settings menu.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.only(bottom: 24),
          children: [
            const ScreenHeader(title: 'Profile', showBack: true),
            const SizedBox(height: 8),
            const Center(child: FrigoAvatar(size: 84)),
            const SizedBox(height: 12),
            Center(child: Text('Elif Yılmaz', style: textTheme.titleLarge)),
            Center(child: Text('elif@example.com', style: textTheme.bodySmall)),
            const SizedBox(height: 24),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Expanded(child: _StatCard(label: 'Favorites')),
                  SizedBox(width: 10),
                  Expanded(child: _StatCard(label: 'Meals cooked')),
                  SizedBox(width: 10),
                  Expanded(child: _StatCard(label: 'Items saved')),
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
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: context.pushAllergies,
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.sticky_note_2_outlined),
                      title: const Text('Shopping list'),
                      trailing: const Icon(Icons.chevron_right_rounded),
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
                onPressed: context.goToLogin,
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
  const _StatCard({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        child: Column(
          children: [
            Text('0', style: textTheme.titleLarge),
            const SizedBox(height: 4),
            Text(label, style: textTheme.bodySmall, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
