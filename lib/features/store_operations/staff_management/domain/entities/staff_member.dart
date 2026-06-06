import 'staff_permission.dart';
import 'staff_role.dart';
import 'staff_status.dart';

class StaffMember {
  final StaffStatus status;
  final int? storeUserId;
  final int? invitationId;
  final int? accountId;
  final int? invitedAccountId;
  final String displayName;
  final String accountFullName;
  final String email;
  final String phone;
  final StaffRole? role;
  final List<StaffPermission> permissions;
  final DateTime? joinedAt;
  final DateTime? createdAt;
  final DateTime? expiresAt;
  final bool isOwner;

  const StaffMember({
    required this.status,
    required this.storeUserId,
    required this.invitationId,
    required this.accountId,
    required this.invitedAccountId,
    required this.displayName,
    required this.accountFullName,
    required this.email,
    required this.phone,
    required this.role,
    required this.permissions,
    required this.joinedAt,
    required this.createdAt,
    required this.expiresAt,
    required this.isOwner,
  });

  String get primaryName {
    final display = displayName.trim();
    if (display.isNotEmpty) {
      return display;
    }

    final accountName = accountFullName.trim();
    if (accountName.isNotEmpty) {
      return accountName;
    }

    final emailText = email.trim();
    if (emailText.isNotEmpty) {
      return emailText;
    }

    return phone.trim().isEmpty ? 'Nhân viên' : phone.trim();
  }

  String get contactText {
    final phoneText = phone.trim();
    if (phoneText.isNotEmpty) {
      return phoneText;
    }

    return email.trim();
  }
}
