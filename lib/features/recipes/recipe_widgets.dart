import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/app_router.dart';
import '../../core/router/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../data/services/recipe_matcher.dart';
import '../../models/models.dart';
import '../../providers/profile_provider.dart';
import '../../providers/shopping_provider.dart';

/// Formats a duration as `mm:ss` (or `h:mm:ss` past an hour).
String formatClock(Duration d) {
  final total = d.isNegative ? 0 : d.inSeconds;
  final h = total ~/ 3600;
  final m = (total % 3600) ~/ 60;
  final s = total % 60;
  String two(int v) => v.toString().padLeft(2, '0');
  return h > 0 ? '$h:${two(m)}:${two(s)}' : '${two(m)}:${two(s)}';
}

/// Mint placeholder used until recipe photos exist.
class RecipeThumbnail extends StatelessWidget {
  const RecipeThumbnail({super.key, this.size = 72, this.iconSize = 32});

  final double size;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.mint.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Icon(
        Icons.restaurant_rounded,
        size: iconSize,
        color: AppColors.charcoal,
      ),
    );
  }
}

/// Pill showing `100% match` or `80% match – missing garlic`.
class MatchBadge extends StatelessWidget {
  const MatchBadge({super.key, required this.match});

  final RecipeMatch match;

  @override
  Widget build(BuildContext context) {
    final full = match.isFullMatch;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: full ? AppColors.mint.withValues(alpha: 0.45) : AppColors.background,
        borderRadius: BorderRadius.circular(999),
        border: full ? null : Border.all(color: AppColors.border),
      ),
      child: Text(
        match.matchLabel,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: AppColors.charcoal,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

/// Heart toggle backed by the profile's favorites.
class FavoriteToggle extends ConsumerWidget {
  const FavoriteToggle({super.key, required this.recipeId});

  final String recipeId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isFavorite = ref.watch(
      profileProvider.select((p) => p.isFavorite(recipeId)),
    );
    return IconButton(
      key: Key('favorite-toggle-$recipeId'),
      tooltip: isFavorite ? 'Remove from favorites' : 'Add to favorites',
      onPressed: () =>
          ref.read(profileProvider.notifier).toggleFavorite(recipeId),
      icon: Icon(
        isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
        color: isFavorite ? AppColors.coral : AppColors.mutedText,
      ),
    );
  }
}

/// One-tap action that sends a recipe's missing ingredients to the
/// shopping list. Renders nothing when the recipe is a full match.
class AddMissingButton extends ConsumerWidget {
  const AddMissingButton({super.key, required this.match});

  final RecipeMatch match;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (match.isFullMatch) return const SizedBox.shrink();
    final recipe = match.recipe;
    final toAdd = missingNotOnList(ref.watch(shoppingNotesProvider), match);
    final key = Key('add-missing-${recipe.id}');

    if (toAdd.isEmpty) {
      return TextButton.icon(
        key: key,
        onPressed: context.pushShoppingList,
        icon: const Icon(Icons.check_rounded, size: 18),
        label: const Text('On your shopping list'),
        style: TextButton.styleFrom(foregroundColor: AppColors.readyGreen),
      );
    }

    final label = toAdd.length == 1
        ? 'Add ${toAdd.single.toLowerCase()} to shopping list'
        : 'Add ${toAdd.length} missing to shopping list';
    return TextButton.icon(
      key: key,
      onPressed: () => _add(context, ref, recipe, toAdd),
      icon: const Icon(Icons.add_shopping_cart_rounded, size: 18),
      label: Text(label),
    );
  }

  void _add(
    BuildContext context,
    WidgetRef ref,
    Recipe recipe,
    List<String> names,
  ) {
    final added = ref
        .read(shoppingNotesProvider.notifier)
        .addMissingForRecipe(recipe, names);
    if (added == 0) return;
    final message = added == 1
        ? '${names.single} added to your shopping list'
        : '$added items added to your shopping list';
    // The card may be gone by the time the action is tapped.
    final router = GoRouter.of(context);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          action: SnackBarAction(
            label: 'View',
            textColor: AppColors.mint,
            onPressed: () => router.pushNamed(AppRoutes.shoppingList),
          ),
        ),
      );
  }
}

/// Small icon + text line (cook time, expiry note...).
class RecipeInfoLine extends StatelessWidget {
  const RecipeInfoLine({
    super.key,
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
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 1),
          child: Icon(icon, size: 15, color: color),
        ),
        const SizedBox(width: 5),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 13,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}
