import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// The open refrigerator: a thick mint cabinet frame with side hinges, an
/// off-white rubber gasket and a lit interior with shadowed side walls.
class FridgeCabinet extends StatelessWidget {
  const FridgeCabinet({super.key, required this.child});

  /// The interior contents (shelves and crisper drawer).
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Outer cabinet body.
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            gradient: const LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                AppColors.mintDeep,
                AppColors.mint,
                AppColors.mintLight,
                AppColors.mint,
                AppColors.mintDeep,
              ],
              stops: [0, 0.08, 0.5, 0.92, 1],
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x261A2421),
                blurRadius: 18,
                offset: Offset(0, 10),
              ),
              BoxShadow(
                color: Color(0x141A2421),
                blurRadius: 3,
                offset: Offset(0, 1),
              ),
            ],
          ),
          // Rubber door seal.
          child: Container(
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              color: AppColors.gasket,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: const Color(0xFFDAD8CF)),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x1F1A2421),
                  blurRadius: 2,
                  offset: Offset(0, 1),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(17),
              child: CustomPaint(
                painter: const _InteriorPainter(),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 22, 14, 12),
                  child: child,
                ),
              ),
            ),
          ),
        ),
        // Door hinges on the left side of the cabinet.
        const Positioned(left: -3, top: 36, child: _Hinge()),
        const Positioned(left: -3, bottom: 36, child: _Hinge()),
      ],
    );
  }
}

class _Hinge extends StatelessWidget {
  const _Hinge();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 8,
      height: 34,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4),
        gradient: const LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [Color(0xFF9AA39F), Color(0xFFE3E7E5), Color(0xFF7D8783)],
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x331A2421),
            blurRadius: 3,
            offset: Offset(1, 1),
          ),
        ],
      ),
    );
  }
}

/// Paints the lit interior: a top-down LED glow, a light strip and darker
/// inner cabinet walls so the inside reads as a recessed box.
class _InteriorPainter extends CustomPainter {
  const _InteriorPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;

    // Base LED glow: white at the top fading into pale mint.
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.white, AppColors.interiorGlow],
        ).createShader(rect),
    );

    // Soft elliptical light pool under the LED strip.
    final glowRect = Rect.fromCenter(
      center: Offset(size.width / 2, 0),
      width: size.width * 1.2,
      height: 220,
    );
    canvas.drawOval(
      glowRect,
      Paint()
        ..shader = RadialGradient(
          colors: [Colors.white, Colors.white.withValues(alpha: 0)],
        ).createShader(glowRect),
    );

    // Side walls: shade towards the left and right edges.
    const wall = 18.0;
    final leftWall = Rect.fromLTWH(0, 0, wall, size.height);
    canvas.drawRect(
      leftWall,
      Paint()
        ..shader = const LinearGradient(
          colors: [Color(0x241A2421), Color(0x001A2421)],
        ).createShader(leftWall),
    );
    final rightWall = Rect.fromLTWH(size.width - wall, 0, wall, size.height);
    canvas.drawRect(
      rightWall,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.centerRight,
          end: Alignment.centerLeft,
          colors: [Color(0x241A2421), Color(0x001A2421)],
        ).createShader(rightWall),
    );

    // Back of the cabinet floor gets a touch darker.
    final floor = Rect.fromLTWH(0, size.height - 28, size.width, 28);
    canvas.drawRect(
      floor,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [Color(0x1A1A2421), Color(0x001A2421)],
        ).createShader(floor),
    );

    // LED strip with a bloom.
    final strip = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(size.width / 2, 7),
        width: size.width * 0.4,
        height: 4,
      ),
      const Radius.circular(2),
    );
    canvas.drawRRect(
      strip.inflate(3),
      Paint()
        ..color = Colors.white
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
    );
    canvas.drawRRect(strip, Paint()..color = Colors.white);
    canvas.drawRRect(
      strip,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.8
        ..color = const Color(0x22000000),
    );
  }

  @override
  bool shouldRepaint(covariant _InteriorPainter oldDelegate) => false;
}

/// A translucent tempered-glass shelf: crisp white specular top edge, a
/// greenish glass body and a soft drop shadow beneath it.
class GlassShelf extends StatelessWidget {
  const GlassShelf({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 10,
      margin: const EdgeInsets.symmetric(horizontal: 2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(3),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.white.withValues(alpha: 0.95),
            AppColors.mint.withValues(alpha: 0.45),
            AppColors.mintDeep.withValues(alpha: 0.55),
          ],
          stops: const [0, 0.35, 1],
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x2E1A2421),
            blurRadius: 10,
            offset: Offset(0, 6),
          ),
        ],
      ),
      // Crisp specular highlight along the front top edge of the glass.
      alignment: Alignment.topCenter,
      child: Container(
        height: 1.5,
        margin: const EdgeInsets.symmetric(horizontal: 1),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(1),
          boxShadow: [
            BoxShadow(
              color: Colors.white.withValues(alpha: 0.9),
              blurRadius: 2,
            ),
          ],
        ),
      ),
    );
  }
}

/// The enclosed frosted-plastic crisper bin, with a top rim and a sculpted
/// recessed pull-handle.
class CrisperDrawer extends StatelessWidget {
  const CrisperDrawer({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    const radius = BorderRadius.only(
      topLeft: Radius.circular(10),
      topRight: Radius.circular(10),
      bottomLeft: Radius.circular(16),
      bottomRight: Radius.circular(16),
    );
    return Container(
      decoration: BoxDecoration(
        borderRadius: radius,
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.white.withValues(alpha: 0.75),
            AppColors.mint.withValues(alpha: 0.28),
          ],
        ),
        border: Border.all(color: Colors.white, width: 1.5),
        boxShadow: const [
          BoxShadow(
            color: Color(0x221A2421),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Top rim with the recessed pull-handle.
          Container(
            height: 22,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(9),
              ),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.white,
                  AppColors.interiorGlow.withValues(alpha: 0.9),
                ],
              ),
            ),
            child: const _PullHandle(),
          ),
          // Seam where the rim meets the frosted bin.
          Container(
            height: 1,
            color: AppColors.mintDeep.withValues(alpha: 0.45),
          ),
          Padding(padding: const EdgeInsets.all(10), child: child),
        ],
      ),
    );
  }
}

class _PullHandle extends StatelessWidget {
  const _PullHandle();

  @override
  Widget build(BuildContext context) {
    // Recessed: dark at the top lip, light at the bottom where the finger
    // scoop curves back out.
    return Container(
      width: 72,
      height: 11,
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(3),
          bottom: Radius.circular(8),
        ),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.mintDeep.withValues(alpha: 0.75),
            AppColors.mint.withValues(alpha: 0.35),
            Colors.white,
          ],
          stops: const [0, 0.55, 1],
        ),
        boxShadow: [
          // Inner lip shadow at the top of the recess.
          BoxShadow(
            color: AppColors.charcoal.withValues(alpha: 0.18),
            blurRadius: 0,
            offset: const Offset(0, -1),
          ),
        ],
      ),
    );
  }
}
