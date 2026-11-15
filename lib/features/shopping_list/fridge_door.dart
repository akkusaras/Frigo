import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// The closed exterior door of the refrigerator: a rounded mint appliance
/// panel with subtle vertical surface shading, a door seam and a vertical
/// metallic handle casting a shadow onto the door.
class FridgeDoor extends StatelessWidget {
  const FridgeDoor({super.key, required this.child});

  /// Content stuck to the door (sticky notes, actions).
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(28);
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: const [
          BoxShadow(
            color: Color(0x2E1A2421),
            blurRadius: 20,
            offset: Offset(0, 12),
          ),
          BoxShadow(
            color: Color(0x1A1A2421),
            blurRadius: 3,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: Stack(
          children: [
            // Vertical surface shading: darker rolled edges, a soft sheen
            // left of centre.
            const Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [
                      AppColors.mintDeep,
                      AppColors.mint,
                      AppColors.mintLight,
                      AppColors.mint,
                      AppColors.mintDeep,
                    ],
                    stops: [0, 0.07, 0.38, 0.85, 1],
                  ),
                ),
              ),
            ),
            // Faint top-to-bottom falloff so the panel reads as tall metal.
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.white.withValues(alpha: 0.18),
                      Colors.white.withValues(alpha: 0),
                      AppColors.charcoal.withValues(alpha: 0.06),
                    ],
                  ),
                ),
              ),
            ),
            // Door seam just inside the edge.
            Positioned.fill(
              child: IgnorePointer(
                child: Container(
                  margin: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(23),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.35),
                    ),
                  ),
                ),
              ),
            ),
            Positioned.fill(child: child),
            const Positioned(
              right: 14,
              top: 28,
              child: IgnorePointer(child: _DoorHandle()),
            ),
          ],
        ),
      ),
    );
  }
}

class _DoorHandle extends StatelessWidget {
  const _DoorHandle();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 22,
      height: 190,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Mounting standoffs.
          for (final y in const [-1.0, 1.0])
            Align(
              alignment: Alignment(0, y * 0.92),
              child: Container(
                width: 16,
                height: 12,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  color: AppColors.handleDark.withValues(alpha: 0.8),
                ),
              ),
            ),
          // The bar itself, with brushed-metal shading and a cast shadow.
          Container(
            width: 12,
            height: 190,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(6),
              gradient: const LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                  AppColors.handleDark,
                  AppColors.handleLight,
                  Color(0xFF9AA5A0),
                  AppColors.handleLight,
                  AppColors.handleDark,
                ],
                stops: [0, 0.25, 0.45, 0.7, 1],
              ),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x591A2421),
                  blurRadius: 8,
                  offset: Offset(-5, 6),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
