class StaffInvitation {
  final int invitationId;
  final int storeId;
  final String invitedEmail;
  final String displayName;
  final int? invitedAccountId;
  final int roleId;
  final int invitedByAccountId;
  final int status;
  final DateTime? createdAt;
  final DateTime? expiresAt;
  final DateTime? respondedAt;
  final List<int> permissionIds;
  final int? notificationId;

  const StaffInvitation({
    required this.invitationId,
    required this.storeId,
    required this.invitedEmail,
    required this.displayName,
    required this.invitedAccountId,
    required this.roleId,
    required this.invitedByAccountId,
    required this.status,
    required this.createdAt,
    required this.expiresAt,
    required this.respondedAt,
    required this.permissionIds,
    required this.notificationId,
  });
}
