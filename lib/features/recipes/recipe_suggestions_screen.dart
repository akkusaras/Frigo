import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/app_router.dart';
import '../../core/router/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/frigo_widgets.dart';
import '../../data/services/recipe_matcher.dart';
import '../../providers/recipe_suggestions_provider.dart';
import 'recipe_widgets.dart';

/// `6. What to cook` — ranked recipe suggestions.
class RecipeSuggestionsScreen extends ConsumerWidget {
  const RecipeSuggestionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final result = ref.watch(recipeSuggestionsProvider);
    final visible = ref.watch(filteredRecipeMatchesProvider);
    final footers = [
      ?result.hiddenAllergySummary,
      ?result.hiddenDietSummary,
    ];

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ScreenHeader(
              title: 'What to cook',
              subtitle: 'Ranked by what is in your fridge',
              showBack: true,
              trailing: [FrigoAvatar(onTap: context.pushProfile)],
            ),
            const _FilterBar(),
            const SizedBox(height: 8),
            Expanded(
              child: ListView(
                key: const Key('recipe-list'),
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                children: [
                  if (visible.isEmpty)
                    _NoResults(hasRecipes: result.matches.isNotEmpty)
                  else
                    for (final match in visible) ...[
                      _RecipeCard(match: match),
                      const SizedBox(height: 12),
                    ],
                  for (final text in footers)
                    _HiddenFooter(text: text, onEdit: context.pushAllergies),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterBar extends ConsumerWidget {
  const _FilterBar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filters = ref.watch(recipeFiltersProvider);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final filter in RecipeFilter.values)
            _chip(context, ref, filter, filters.contains(filter)),
        ],
      ),
    );
  }

  Widget _chip(
    BuildContext context,
    WidgetRef ref,
    RecipeFilter filter,
    bool selected,
  ) {
    return FilterChip(
      key: Key('filter-${filter.name}'),
      label: Text(
        filter.label,
        style: TextStyle(
          color: selected ? Colors.white : AppColors.charcoal,
          fontWeight: FontWeight.w500,
        ),
      ),
      selected: selected,
      onSelected: (_) {
        if (filter.isLocked) {
          _explainLocked(context);
        } else {
          ref.read(recipeFiltersProvider.notifier).toggle(filter);
        }
      },
    );
  }

  void _explainLocked(BuildContext context) {
    final router = GoRouter.of(context);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: const Text(
            'Recipes with your allergens are always hidden.',
          ),
          action: SnackBarAction(
            label: 'Edit',
            textColor: AppColors.mint,
            onPressed: () => router.pushNamed(AppRoutes.allergies),
          ),
        ),
      );
  }
}

class _RecipeCard extends StatelessWidget {
  const _RecipeCard({required this.match});

  final RecipeMatch match;

  @override
  Widget build(BuildContext context) {
    final recipe = match.recipe;
    final textTheme = Theme.of(context).textTheme;
    final expiry = match.expiryNote;

    return Card(
      key: Key('recipe-card-${recipe.id}'),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.pushRecipeDetail(recipe.id),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 4, 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const RecipeThumbnail(),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(recipe.title, style: textTheme.titleMedium),
                        const SizedBox(height: 4),
                        RecipeInfoLine(
                          icon: Icons.schedule_rounded,
                          text: '${recipe.cookMinutes} min',
                        ),
                        if (expiry != null) ...[
                          const SizedBox(height: 3),
                          RecipeInfoLine(
                            icon: Icons.priority_high_rounded,
                            text: expiry,
                            color: AppColors.coral,
                          ),
                        ],
                        const SizedBox(height: 8),
                        MatchBadge(match: match),
                      ],
                    ),
                  ),
                  FavoriteToggle(recipeId: recipe.id),
                ],
              ),
              if (!match.isFullMatch)
                Align(
                  alignment: Alignment.centerRight,
                  child: AddMissingButton(match: match),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HiddenFooter extends StatelessWidget {
  const _HiddenFooter({required this.text, required this.onEdit});

  final String text;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        children: [
          const Icon(
            Icons.visibility_off_outlined,
            size: 16,
            color: AppColors.mutedText,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(text, style: Theme.of(context).textTheme.bodySmall),
          ),
          TextButton(onPressed: onEdit, child: const Text('Edit')),
        ],
      ),
    );
  }
}

class _NoResults extends ConsumerWidget {
  const _NoResults({required this.hasRecipes});

  /// `true` when recipes exist but the filters exclude all of them.
  final bool hasRecipes;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Column(
        children: [
          const Icon(
            Icons.search_off_rounded,
            size: 40,
            color: AppColors.mutedText,
          ),
          const SizedBox(height: 12),
          Text(
            hasRecipes
                ? 'No recipes match these filters.'
                : 'No safe recipes for your allergies and diet yet.',
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppColors.mutedText),
          ),
          if (hasRecipes) ...[
            const SizedBox(height: 8),
            TextButton(
              key: const Key('clear-filters'),
              onPressed: ref.read(recipeFiltersProvider.notifier).clear,
              child: const Text('Clear filters'),
            ),
          ],
        ],
      ),
    );
  }
}
