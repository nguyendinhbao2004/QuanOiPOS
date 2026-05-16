/// Hằng số dùng chung toàn ứng dụng QuanOi POS.
abstract final class AppConstants {
  // ─── App info ──────────────────────────────────────────────────────────────
  static const String appName = 'QuanOi POS';
  static const String appVersion = '1.0.0';
  static const String supportPhone = '1900 xxxx';
  static const String branchName = 'QUANOI-01';

  // ─── Spacing ───────────────────────────────────────────────────────────────
  static const double spacingXs = 4.0;
  static const double spacingSm = 8.0;
  static const double spacingMd = 16.0;
  static const double spacingLg = 24.0;
  static const double spacingXl = 32.0;
  static const double spacingXxl = 48.0;

  // ─── Avatar ────────────────────────────────────────────────────────────────
  static const double avatarSizeSm = 36.0;
  static const double avatarSizeMd = 72.0;
  static const double avatarSizeLg = 80.0;

  // ─── Animation duration ────────────────────────────────────────────────────
  static const Duration animFast = Duration(milliseconds: 150);
  static const Duration animNormal = Duration(milliseconds: 250);
  static const Duration animSlow = Duration(milliseconds: 400);
}
