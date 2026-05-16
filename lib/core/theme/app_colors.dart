import 'package:flutter/material.dart';

/// Bảng màu chính của QuanOi POS — dịch từ theme.css của EXE101.
abstract final class AppColors {
  // ─── Brand / Primary ───────────────────────────────────────────────────────
  /// Màu cam chủ đạo (#F96D3A)
  static const Color primary = Color(0xFFF96D3A);

  /// Màu cam nhạt hơn dùng cho hover / ripple
  static const Color primaryLight = Color(0xFFFFF3EE);

  /// Màu cam đậm hơn dùng cho pressed state
  static const Color primaryDark = Color(0xFFD95A2B);

  // ─── Background ────────────────────────────────────────────────────────────
  /// Nền ứng dụng — trắng kem (#FAF5F0)
  static const Color background = Color(0xFFFAF5F0);

  /// Nền card / surface trắng tinh (#FFFFFF)
  static const Color surface = Color(0xFFFFFFFF);

  /// Nền sidebar (#F7F2ED)
  static const Color sidebar = Color(0xFFF7F2ED);

  // ─── Text ──────────────────────────────────────────────────────────────────
  /// Màu chữ chính (#333333)
  static const Color textPrimary = Color(0xFF333333);

  /// Màu chữ phụ (#666666)
  static const Color textSecondary = Color(0xFF666666);

  /// Màu chữ mờ / placeholder (#999999)
  static const Color textMuted = Color(0xFF999999);

  /// Màu chữ rất mờ (#BBBBBB)
  static const Color textDisabled = Color(0xFFBBBBBB);

  // ─── Border / Divider ──────────────────────────────────────────────────────
  /// Đường viền nhẹ (#F0EBE5)
  static const Color border = Color(0xFFF0EBE5);

  /// Đường viền đậm hơn (#E8E2DC)
  static const Color borderStrong = Color(0xFFE8E2DC);

  /// Đường viền dashed (#D8D0C8)
  static const Color borderDashed = Color(0xFFD8D0C8);

  // ─── Input ─────────────────────────────────────────────────────────────────
  /// Nền input (#F3F3F5)
  static const Color inputBackground = Color(0xFFF3F3F5);

  /// Đường viền input (#E8E2DC)
  static const Color inputBorder = Color(0xFFE8E2DC);

  // ─── Muted / Accent ────────────────────────────────────────────────────────
  /// Nền muted (#ECECF0)
  static const Color muted = Color(0xFFECECF0);

  /// Màu accent nhẹ (#E9EBEF)
  static const Color accent = Color(0xFFE9EBEF);

  /// Màu accent avatar / badge (#E0D5CA)
  static const Color accentWarm = Color(0xFFE0D5CA);

  // ─── Semantic ──────────────────────────────────────────────────────────────
  /// Màu lỗi / destructive (#D4183D)
  static const Color error = Color(0xFFD4183D);

  /// Màu thành công
  static const Color success = Color(0xFF22C55E);

  /// Màu cảnh báo
  static const Color warning = Color(0xFFF59E0B);

  /// Màu thông tin
  static const Color info = Color(0xFF3B82F6);

  // ─── Overlay ───────────────────────────────────────────────────────────────
  /// Lớp overlay tối (backdrop của modal)
  static const Color overlay = Color(0x80000000);

  // ─── Chart / Data Viz (từ theme.css) ───────────────────────────────────────
  static const Color chart1 = Color(0xFFE8622A); // oklch(0.646 0.222 41.116)
  static const Color chart2 = Color(0xFF3BA89B); // oklch(0.6 0.118 184.704)
  static const Color chart3 = Color(0xFF3A5E80); // oklch(0.398 0.07 227.392)
  static const Color chart4 = Color(0xFFE8C84A); // oklch(0.828 0.189 84.429)
  static const Color chart5 = Color(0xFFD4A832); // oklch(0.769 0.188 70.08)
}
