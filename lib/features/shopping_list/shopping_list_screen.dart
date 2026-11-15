import 'package:flutter/material.dart';

import '../../core/router/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/frigo_widgets.dart';

/// `3. Shopping list` — sticky notes on the fridge door.
class ShoppingListScreen extends StatelessWidget {
  const ShoppingListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            ScreenHeader(
              title: 'Shopping list',
              subtitle: 'Notes on your fridge door',
              showBack: true,
              trailing: [FrigoAvatar(onTap: context.pushProfile)],
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: [
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: AppColors.noteYellow,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'Missing ingredients from recipes land here automatically.',
                      style: TextStyle(color: AppColors.charcoal),
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
          FilledButton(
            onPressed: context.goToFridge,
            child: const Text('Open the fridge'),
          ),
        ],
      ),
    );
  }
}
