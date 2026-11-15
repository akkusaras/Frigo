import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/router/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/frigo_widgets.dart';
import '../../models/models.dart';
import '../../providers/profile_provider.dart';
import '../../providers/recipe_suggestions_provider.dart';
import 'recipe_widgets.dart';

/// Recipe detail: ingredients, steps and the `Start Cooking` entry point.
class RecipeDetailScreen extends ConsumerWidget {
  const RecipeDetailScreen({super.key, required this.recipeId});

  final String recipeId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final insight = ref.watch(recipeInsightProvider(recipeId));
    if (insight == null) return RecipeNotFound(recipeId: recipeId);

    final recipe = insight.recipe;
    final match = insight.match;
    final diet = ref.watch(profileProvider.select((p) => p.diet));
    final expiry = match.expiryNote;

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.only(bottom: 24),
          children: [
            ScreenHeader(
              title: recipe.title,
              subtitle:
                  '${recipe.cookMinutes} min · ${recipe.servings} servings',
              showBack: true,
              trailing: [FavoriteToggle(recipeId: recipe.id)],
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(
                    height: 180,
                    width: double.infinity,
                    child: RecipeThumbnail(
                      size: double.infinity,
                      iconSize: 56,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (!insight.isAllergySafe) ...[
                    AlertBanner(
                      key: const Key('recipe-allergy-warning'),
                      icon: Icons.warning_amber_rounded,
                      message:
                          'Contains ${insight.allergyTriggers.join(', ')} – '
                          'your allergy. This recipe is hidden from your '
                          'suggestions.',
                    ),
                    const SizedBox(height: 12),
                  ],
                  if (!insight.fitsDiet) ...[
                    AlertBanner(
                      icon: Icons.info_outline_rounded,
                      message:
                          'Not ${diet.label.toLowerCase()} – hidden from '
                          'your suggestions.',
                    ),
                    const SizedBox(height: 12),
                  ],
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      MatchBadge(match: match),
                      if (expiry != null) ExpiryBadge(label: expiry),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const SectionLabel('Ingredients'),
                  const SizedBox(height: 8),
                  Card(
                    child: Column(
                      children: [
                        for (final line in recipe.ingredients)
                          _IngredientRow(
                            line: line,
                            inFridge: insight.isAvailable(line),
                          ),
                      ],
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: AddMissingButton(match: match),
                  ),
                  const SizedBox(height: 12),
                  const SectionLabel('Steps'),
                  const SizedBox(height: 8),
                  for (final (index, step) in recipe.steps.indexed)
                    _StepTile(number: index + 1, step: step),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomActions(
        children: [
          FilledButton.icon(
            key: const Key('start-cooking'),
            onPressed: () => context.pushCookingMode(recipe.id),
            icon: const Icon(Icons.play_arrow_rounded),
            label: const Text('Start Cooking'),
          ),
        ],
      ),
    );
  }
}

class _IngredientRow extends StatelessWidget {
  const _IngredientRow({required this.line, required this.inFridge});

  final RecipeIngredient line;
  final bool inFridge;

  @override
  Widget build(BuildContext context) {
    final String status;
    final IconData icon;
    final Color color;
    if (line.isPantryStaple) {
      status = 'Pantry';
      icon = Icons.inventory_2_outlined;
      color = AppColors.mutedText;
    } else if (inFridge) {
      status = 'In fridge';
      icon = Icons.check_circle_rounded;
      color = AppColors.readyGreen;
    } else {
      status = 'Missing';
      icon = Icons.remove_circle_outline_rounded;
      color = AppColors.coral;
    }

    return ListTile(
      key: Key('ingredient-row-${line.name}'),
      dense: true,
      leading: Icon(icon, color: color, size: 22),
      title: Text(line.name, style: Theme.of(context).textTheme.titleMedium),
      subtitle: Text(line.amount),
      trailing: Text(
        status,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _StepTile extends StatelessWidget {
  const _StepTile({required this.number, required this.step});

  final int number;
  final RecipeStep step;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 14,
            backgroundColor: AppColors.charcoal,
            child: Text(
              '$number',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(step.instruction),
                const SizedBox(height: 4),
                RecipeInfoLine(
                  icon: Icons.timer_outlined,
                  text: '${step.duration.inMinutes} min timer',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Shown when a deep link points at a recipe id that does not exist.
class RecipeNotFound extends StatelessWidget {
  const RecipeNotFound({super.key, required this.recipeId});

  final String recipeId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const ScreenHeader(title: 'Recipe not found', showBack: true),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                'We could not find a recipe called "$recipeId".',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomActions(
        children: [
          FilledButton(
            onPressed: context.goToRecipeSuggestions,
            child: const Text('See what to cook'),
          ),
        ],
      ),
    );
  }
}
