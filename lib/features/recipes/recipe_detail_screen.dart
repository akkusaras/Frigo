import 'package:flutter/material.dart';

import '../../core/router/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/frigo_widgets.dart';

/// Turns a route id like `baked-sea-bass` into `Baked sea bass`.
String recipeTitleFromId(String id) {
  final words = id.replaceAll(RegExp(r'[-_]+'), ' ').trim();
  if (words.isEmpty) return id;
  return words[0].toUpperCase() + words.substring(1);
}

/// Recipe detail: ingredients, steps and the `Start Cooking` entry point.
class RecipeDetailScreen extends StatelessWidget {
  const RecipeDetailScreen({super.key, required this.recipeId});

  final String recipeId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListView(
          children: [
            ScreenHeader(title: recipeTitleFromId(recipeId), showBack: true),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                height: 180,
                decoration: BoxDecoration(
                  color: AppColors.mint.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.restaurant_rounded,
                  size: 56,
                  color: AppColors.charcoal,
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomActions(
        children: [
          FilledButton.icon(
            onPressed: () => context.pushCookingMode(recipeId),
            icon: const Icon(Icons.play_arrow_rounded),
            label: const Text('Start Cooking'),
          ),
        ],
      ),
    );
  }
}
