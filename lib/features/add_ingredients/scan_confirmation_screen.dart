import 'package:flutter/material.dart';

import '../../core/router/app_router.dart';
import '../../core/router/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/frigo_widgets.dart';

/// `5. Check what we found` — confirm ingredients detected from a scan.
class ScanConfirmationScreen extends StatelessWidget {
  const ScanConfirmationScreen({super.key, required this.source});

  final ScanSource source;

  @override
  Widget build(BuildContext context) {
    final isReceipt = source == ScanSource.receipt;
    return Scaffold(
      body: SafeArea(
        child: ListView(
          children: [
            const ScreenHeader(title: 'Check what we found', showBack: true),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                key: const Key('scan-preview'),
                height: 180,
                decoration: BoxDecoration(
                  color: AppColors.mint.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      isReceipt
                          ? Icons.receipt_long_outlined
                          : Icons.photo_outlined,
                      size: 48,
                      color: AppColors.charcoal,
                    ),
                    const SizedBox(height: 8),
                    Text(isReceipt ? 'Receipt scan' : 'Fridge photo'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomActions(
        children: [
          FilledButton(
            onPressed: context.goToFridge,
            child: const Text('Back to my fridge'),
          ),
        ],
      ),
    );
  }
}
