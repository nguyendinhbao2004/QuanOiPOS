import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_text_styles.dart';

/// ThemeData chính của QuanOi POS (chỉ light theme, theo EXE101 web).
abstract final class AppTheme {
  /// Radius cơ sở — 10px (0.625rem × 16)
  static const double radiusBase = 10.0;
  static const double radiusSm = 6.0; // calc(var(--radius) - 4px)
  static const double radiusMd = 8.0; // calc(var(--radius) - 2px)
  static const double radiusLg = 10.0;
  static const double radiusXl = 14.0; // calc(var(--radius) + 4px)

  static ThemeData get light {
    final colorScheme = ColorScheme(
      brightness: Brightness.light,
      // Primary
      primary: AppColors.primary,
      onPrimary: AppColors.surface,
      primaryContainer: AppColors.primaryLight,
      onPrimaryContainer: AppColors.primaryDark,
      // Secondary
      secondary: AppColors.accent,
      onSecondary: AppColors.textPrimary,
      secondaryContainer: AppColors.muted,
      onSecondaryContainer: AppColors.textPrimary,
      // Surface
      surface: AppColors.surface,
      onSurface: AppColors.textPrimary,
      surfaceContainerHighest: AppColors.background,
      // Error
      error: AppColors.error,
      onError: AppColors.surface,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.background,
      fontFamily: 'Inter',

      // ── AppBar ──────────────────────────────────────────────────────────────
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        shadowColor: AppColors.border,
        titleTextStyle: AppTextStyles.h4,
        centerTitle: false,
      ),

      // ── Card ────────────────────────────────────────────────────────────────
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLg),
          side: const BorderSide(color: AppColors.border),
        ),
        margin: EdgeInsets.zero,
      ),

      // ── ElevatedButton ──────────────────────────────────────────────────────
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.surface,
          disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.5),
          disabledForegroundColor: AppColors.surface,
          elevation: 0,
          shadowColor: Colors.transparent,
          textStyle: AppTextStyles.button,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusXl),
          ),
          minimumSize: const Size(double.infinity, 52),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        ),
      ),

      // ── OutlinedButton ──────────────────────────────────────────────────────
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.textPrimary,
          side: const BorderSide(color: AppColors.border),
          textStyle: AppTextStyles.button,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusXl),
          ),
          minimumSize: const Size(double.infinity, 52),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        ),
      ),

      // ── TextButton ──────────────────────────────────────────────────────────
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          textStyle: AppTextStyles.labelSm,
        ),
      ),

      // ── InputDecoration ─────────────────────────────────────────────────────
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.inputBackground,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        hintStyle: AppTextStyles.placeholder,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusLg),
          borderSide: const BorderSide(color: AppColors.inputBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusLg),
          borderSide: const BorderSide(color: AppColors.inputBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusLg),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusLg),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusLg),
          borderSide: const BorderSide(color: AppColors.error, width: 1.5),
        ),
      ),

      // ── Divider ─────────────────────────────────────────────────────────────
      dividerTheme: const DividerThemeData(
        color: AppColors.border,
        thickness: 1,
        space: 1,
      ),

      // ── Text ────────────────────────────────────────────────────────────────
      textTheme: const TextTheme(
        displayLarge: AppTextStyles.h1,
        displayMedium: AppTextStyles.h2,
        displaySmall: AppTextStyles.h3,
        headlineMedium: AppTextStyles.h4,
        bodyLarge: AppTextStyles.bodyBase,
        bodyMedium: AppTextStyles.bodySm,
        bodySmall: AppTextStyles.bodyXs,
        labelLarge: AppTextStyles.button,
        labelMedium: AppTextStyles.labelSm,
        labelSmall: AppTextStyles.caption,
      ),

      // ── Snackbar ────────────────────────────────────────────────────────────
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.textPrimary,
        contentTextStyle: AppTextStyles.bodySm.copyWith(color: AppColors.surface),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusMd)),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
