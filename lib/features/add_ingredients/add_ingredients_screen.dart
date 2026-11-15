import 'package:flutter/material.dart';

import '../../core/router/app_router.dart';
import '../../core/router/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/frigo_widgets.dart';

/// `4. Add ingredients` — photo, receipt or manual entry.
class AddIngredientsScreen extends StatelessWidget {
  const AddIngredientsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.only(bottom: 24),
          children: [
            const ScreenHeader(title: 'Add ingredients', showBack: true),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Expanded(
                    child: _CaptureCard(
                      icon: Icons.photo_camera_outlined,
                      title: 'Take a photo',
                      subtitle: 'Of your fridge or groceries',
                      onTap: () =>
                          context.pushScanConfirmation(ScanSource.photo),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _CaptureCard(
                      icon: Icons.receipt_long_outlined,
                      title: 'Scan a receipt',
                      subtitle: 'We read the items for you',
                      onTap: () =>
                          context.pushScanConfirmation(ScanSource.receipt),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CaptureCard extends StatelessWidget {
  const _CaptureCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.mint.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: AppColors.charcoal),
              ),
              const SizedBox(height: 14),
              Text(title, style: textTheme.titleMedium),
              const SizedBox(height: 4),
              Text(subtitle, style: textTheme.bodySmall),
            ],
          ),
        ),
      ),
    );
  }
}
