import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Hệ thống typography của QuanOi POS — căn theo heading styles trong theme.css.
///
/// Font family: Inter (Google Fonts) — cần thêm package `google_fonts`.
/// Nếu chưa có, fallback về system font.
abstract final class AppTextStyles {
  static const String _fontFamily = 'Inter';

  // ─── Display / Heading ─────────────────────────────────────────────────────

  /// H1 — 2xl (32px), weight 500
  static const TextStyle h1 = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 32,
    fontWeight: FontWeight.w500,
    height: 1.5,
    color: AppColors.textPrimary,
  );

  /// H2 — xl (24px), weight 500
  static const TextStyle h2 = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 24,
    fontWeight: FontWeight.w500,
    height: 1.5,
    color: AppColors.textPrimary,
  );

  /// H3 — lg (20px), weight 500
  static const TextStyle h3 = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 20,
    fontWeight: FontWeight.w500,
    height: 1.5,
    color: AppColors.textPrimary,
  );

  /// H4 — base (16px), weight 500
  static const TextStyle h4 = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w500,
    height: 1.5,
    color: AppColors.textPrimary,
  );

  // ─── Body ──────────────────────────────────────────────────────────────────

  /// Body base — 16px, weight 400
  static const TextStyle bodyBase = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 1.5,
    color: AppColors.textPrimary,
  );

  /// Body sm — 14px, weight 400
  static const TextStyle bodySm = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.5,
    color: AppColors.textSecondary,
  );

  /// Body xs — 12px, weight 400
  static const TextStyle bodyXs = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 1.5,
    color: AppColors.textMuted,
  );

  // ─── Label ─────────────────────────────────────────────────────────────────

  /// Label — 16px, weight 500 (giống element <label> trong CSS)
  static const TextStyle label = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w500,
    height: 1.5,
    color: AppColors.textPrimary,
  );

  /// Label sm — 14px, weight 500
  static const TextStyle labelSm = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w500,
    height: 1.5,
    color: AppColors.textPrimary,
  );

  /// Label xs — 13px, weight 600 (dùng cho badge/tag)
  static const TextStyle labelXs = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 13,
    fontWeight: FontWeight.w600,
    height: 1.4,
    color: AppColors.textPrimary,
  );

  // ─── Button ────────────────────────────────────────────────────────────────

  /// Button text — 16px, weight 500
  static const TextStyle button = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w500,
    height: 1.5,
    color: AppColors.surface,
  );

  /// Button text sm — 15px, weight 600
  static const TextStyle buttonSm = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 15,
    fontWeight: FontWeight.w600,
    height: 1.5,
    color: AppColors.surface,
  );

  // ─── Input / Caption ───────────────────────────────────────────────────────

  /// Input value — 16px, weight 400
  static const TextStyle input = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 1.5,
    color: AppColors.textPrimary,
  );

  /// Placeholder — 16px, weight 400, muted color
  static const TextStyle placeholder = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 1.5,
    color: AppColors.textMuted,
  );

  /// Caption / footer — 12px, weight 400, disabled color
  static const TextStyle caption = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 1.5,
    color: AppColors.textDisabled,
  );
}
