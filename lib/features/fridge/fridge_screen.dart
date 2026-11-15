import 'package:flutter/material.dart';

import '../../core/router/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/frigo_widgets.dart';

/// `2. My Fridge` — the visual fridge home screen.
class FridgeScreen extends StatelessWidget {
  const FridgeScreen({super.key});

  static const shelves = ['DAIRY', 'MEAT AND LEFTOVERS', 'VEGETABLE DRAWER'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            ScreenHeader(
              title: 'My Fridge',
              trailing: [
                IconButton.outlined(
                  tooltip: 'Shopping list',
                  onPressed: context.pushShoppingList,
                  icon: const Icon(Icons.sticky_note_2_outlined),
                ),
                FrigoAvatar(onTap: context.pushProfile),
              ],
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  key: const Key('fridge-container'),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.mint,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: AppColors.charcoal, width: 2),
                  ),
                  child: Column(
                    children: [
                      for (final shelf in shelves)
                        Expanded(child: _Shelf(label: shelf)),
                    ],
                  ),
                ),
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
  const _Shelf({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.all(10),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppColors.charcoal, width: 2),
        ),
      ),
      alignment: Alignment.topLeft,
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppColors.charcoal,
            ),
      ),
    );
  }
}
