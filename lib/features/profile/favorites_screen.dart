import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/router/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/frigo_widgets.dart';
import '../../providers/favorites_provider.dart';
import '../../providers/profile_provider.dart';

/// `8. Favorite recipes` — searchable 2-column grid of saved recipes.
class FavoritesScreen extends ConsumerStatefulWidget {
  const FavoritesScreen({super.key});

  @override
  ConsumerState<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends ConsumerState<FavoritesScreen> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final favorites = ref.watch(favoriteRecipesProvider);
    final visible = filterFavorites(favorites, _query);
    final textTheme = Theme.of(context).textTheme;

    final Widget body;
    if (favorites.isEmpty) {
      body = const _EmptyMessage(
        icon: Icons.favorite_border_rounded,
        message: 'No favorites yet. Tap the heart on a recipe to save it here.',
      );
    } else if (visible.isEmpty) {
      body = _EmptyMessage(
        icon: Icons.search_off_rounded,
        message: 'No favorites match "${_query.trim()}".',
      );
    } else {
      body = GridView.builder(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          mainAxisExtent: 236,
        ),
        itemCount: visible.length,
        itemBuilder: (context, index) =>
            _FavoriteCard(favorite: visible[index]),
      );
    }

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ScreenHeader(
              title: 'Favorite recipes',
              subtitle: favorites.length == 1
                  ? '1 recipe'
                  : '${favorites.length} recipes',
              showBack: true,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: TextField(
                key: const Key('favorites-search'),
                controller: _searchController,
                textInputAction: TextInputAction.search,
                onChanged: (value) => setState(() => _query = value),
                decoration: InputDecoration(
                  hintText: 'Search your favorites',
                  hintStyle: textTheme.bodyMedium?.copyWith(
                    color: AppColors.mutedText,
                  ),
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: _query.isEmpty
                      ? null
                      : IconButton(
                          tooltip: 'Clear search',
                          icon: const Icon(Icons.close_rounded),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _query = '');
                          },
                        ),
                ),
              ),
            ),
            Expanded(child: body),
          ],
        ),
      ),
    );
  }
}

class _FavoriteCard extends ConsumerWidget {
  const _FavoriteCard({required this.favorite});

  final FavoriteRecipe favorite;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final recipe = favorite.recipe;
    final cooked = favorite.timesCooked;

    return Card(
      key: Key('favorite-${recipe.id}'),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.pushRecipeDetail(recipe.id),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 112,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ColoredBox(
                    color: AppColors.mint.withValues(alpha: 0.35),
                    child: const Icon(
                      Icons.restaurant_rounded,
                      size: 40,
                      color: AppColors.charcoal,
                    ),
                  ),
                  if (favorite.isReady)
                    const Positioned(top: 8, left: 8, child: _ReadyPill()),
                  Positioned(
                    top: 2,
                    right: 2,
                    child: IconButton(
                      tooltip: 'Remove from favorites',
                      onPressed: () => ref
                          .read(profileProvider.notifier)
                          .toggleFavorite(recipe.id),
                      icon: const Icon(
                        Icons.favorite_rounded,
                        color: AppColors.coral,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    recipe.title,
                    style: textTheme.titleMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  _InfoRow(
                    icon: Icons.schedule_rounded,
                    text: '${recipe.cookMinutes} min',
                  ),
                  const SizedBox(height: 4),
                  _InfoRow(
                    icon: Icons.local_dining_rounded,
                    text: switch (cooked) {
                      0 => 'Not cooked yet',
                      1 => 'Cooked once',
                      _ => 'Cooked $cooked times',
                    },
                  ),
                  if (!favorite.isReady) ...[
                    const SizedBox(height: 4),
                    _InfoRow(
                      icon: Icons.shopping_basket_outlined,
                      text: 'Missing ${favorite.missingCount}',
                      color: AppColors.coral,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.text,
    this.color = AppColors.mutedText,
  });

  final IconData icon;
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 12, color: color),
          ),
        ),
      ],
    );
  }
}

/// Green `Ready` badge: every ingredient is already in the fridge.
class _ReadyPill extends StatelessWidget {
  const _ReadyPill();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.readyGreen,
        borderRadius: BorderRadius.circular(999),
      ),
      child: const Text(
        'Ready',
        style: TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _EmptyMessage extends StatelessWidget {
  const _EmptyMessage({required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 40, color: AppColors.mutedText),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.mutedText,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
