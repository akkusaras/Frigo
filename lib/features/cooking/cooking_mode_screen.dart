import 'package:flutter/material.dart';

import '../../core/router/app_router.dart';
import '../../core/widgets/frigo_widgets.dart';
import '../recipes/recipe_detail_screen.dart';

/// Cooking Mode — guided, step-by-step view of a recipe.
class CookingModeScreen extends StatelessWidget {
  const CookingModeScreen({super.key, required this.recipeId});

  final String recipeId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            ScreenHeader(
              title: 'Cooking mode',
              subtitle: recipeTitleFromId(recipeId),
              showBack: true,
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomActions(
        children: [
          FilledButton(
            onPressed: context.goToFridge,
            child: const Text('Finish cooking'),
          ),
        ],
      ),
    );
  }
}
