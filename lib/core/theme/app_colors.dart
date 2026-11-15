import 'package:flutter/material.dart';

/// Frigo design system palette.
abstract final class AppColors {
  /// App background — Soft Pale Sage.
  static const Color background = Color(0xFFF4F7F4);

  /// Fridge interior & brand accent — Mint Green.
  static const Color mint = Color(0xFF95C5B1);

  /// Primary text & dark CTA buttons — Deep Forest Charcoal.
  static const Color charcoal = Color(0xFF1A2421);

  /// Expiry alert text & badges — Soft Coral Red.
  static const Color coral = Color(0xFFE05A47);

  /// Expiry alert surface.
  static const Color coralSurface = Color(0xFFFDECEC);

  /// Fridge door sticky notes.
  static const Color noteYellow = Color(0xFFFFF3B0);
  static const Color notePink = Color(0xFFFAD2D8);

  /// Cards & chips.
  static const Color card = Color(0xFFFFFFFF);
  static const Color border = Color(0xFFE2E8E4);

  /// `Ready` badge on favorite recipes (all ingredients in the fridge).
  static const Color readyGreen = Color(0xFF3F8F6B);

  /// Secondary text.
  static const Color mutedText = Color(0xFF5F6B66);

  // ---- Appliance surfaces (fridge cabinet & door) ----

  /// Darker mint used for cabinet shading, hinges and door edges.
  static const Color mintDeep = Color(0xFF7DB09B);

  /// Lighter mint used for the door's specular sheen.
  static const Color mintLight = Color(0xFFB4D8C9);

  /// Off-white rubber door seal (gasket).
  static const Color gasket = Color(0xFFF1F0EA);

  /// Bottom of the interior LED glow (top is pure white).
  static const Color interiorGlow = Color(0xFFE8F4F0);

  /// Brushed-metal handle tones.
  static const Color handleLight = Color(0xFF5A6661);
  static const Color handleDark = Color(0xFF1A2421);
}
