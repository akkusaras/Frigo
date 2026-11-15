import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Builds the Frigo [ThemeData].
abstract final class AppTheme {
  static const double buttonRadius = 14;

  static ThemeData light() {
    final colorScheme =
        ColorScheme.fromSeed(
          seedColor: AppColors.mint,
          brightness: Brightness.light,
        ).copyWith(
          primary: AppColors.charcoal,
          onPrimary: Colors.white,
          secondary: AppColors.mint,
          onSecondary: AppColors.charcoal,
          error: AppColors.coral,
          onError: Colors.white,
          errorContainer: AppColors.coralSurface,
          onErrorContainer: AppColors.coral,
          surface: AppColors.card,
          onSurface: AppColors.charcoal,
          outline: AppColors.border,
          outlineVariant: AppColors.border,
        );

    final buttonShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(buttonRadius),
    );
    const buttonPadding = EdgeInsets.symmetric(horizontal: 20, vertical: 16);
    const buttonText = TextStyle(fontSize: 16, fontWeight: FontWeight.w600);

    final inputBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(buttonRadius),
      borderSide: const BorderSide(color: AppColors.border),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.background,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.charcoal,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: AppColors.charcoal,
          fontSize: 22,
          fontWeight: FontWeight.w700,
        ),
      ),
      textTheme: const TextTheme(
        headlineMedium: TextStyle(
          color: AppColors.charcoal,
          fontWeight: FontWeight.w700,
        ),
        titleLarge: TextStyle(
          color: AppColors.charcoal,
          fontWeight: FontWeight.w700,
        ),
        titleMedium: TextStyle(
          color: AppColors.charcoal,
          fontWeight: FontWeight.w600,
        ),
        bodyLarge: TextStyle(color: AppColors.charcoal),
        bodyMedium: TextStyle(color: AppColors.charcoal),
        bodySmall: TextStyle(color: AppColors.mutedText),
        labelSmall: TextStyle(
          color: AppColors.mutedText,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.1,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.charcoal,
          foregroundColor: Colors.white,
          shape: buttonShape,
          padding: buttonPadding,
          textStyle: buttonText,
          minimumSize: const Size(0, 52),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.charcoal,
          backgroundColor: AppColors.card,
          side: const BorderSide(color: AppColors.border, width: 1.2),
          shape: buttonShape,
          padding: buttonPadding,
          textStyle: buttonText,
          minimumSize: const Size(0, 52),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.charcoal,
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.card,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.border),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.card,
        selectedColor: AppColors.charcoal,
        disabledColor: AppColors.border,
        // Selected chips sit on charcoal, so their label must flip to white.
        labelStyle: TextStyle(
          color: WidgetStateColor.resolveWith(
            (states) => states.contains(WidgetState.selected)
                ? Colors.white
                : AppColors.charcoal,
          ),
          fontWeight: FontWeight.w500,
        ),
        secondaryLabelStyle: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w500,
        ),
        checkmarkColor: Colors.white,
        side: const BorderSide(color: AppColors.border),
        shape: const StadiumBorder(),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.card,
        hintStyle: const TextStyle(color: AppColors.mutedText),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        border: inputBorder,
        enabledBorder: inputBorder,
        focusedBorder: inputBorder.copyWith(
          borderSide: const BorderSide(color: AppColors.charcoal, width: 1.4),
        ),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? AppColors.charcoal
              : Colors.transparent,
        ),
        checkColor: const WidgetStatePropertyAll(Colors.white),
        side: const BorderSide(color: AppColors.charcoal, width: 1.4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.border,
        thickness: 1,
      ),
      snackBarTheme: const SnackBarThemeData(
        backgroundColor: AppColors.charcoal,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
