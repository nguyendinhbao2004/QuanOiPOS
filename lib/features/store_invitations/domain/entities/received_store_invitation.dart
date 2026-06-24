class ReceivedStoreInvitation {
  final int invitationId;
  final int storeId;
  final String storeName;
  final String invitedEmail;
  final String displayName;
  final int? invitedAccountId;
  final int roleId;
  final String roleName;
  final int invitedByAccountId;
  final String invitedByFullName;
  final String invitedByEmail;
  final int status;
  final DateTime? createdAt;
  final DateTime? expiresAt;
  final DateTime? respondedAt;
  final List<int> permissionIds;

  const ReceivedStoreInvitation({
    required this.invitationId,
    required this.storeId,
    required this.storeName,
    required this.invitedEmail,
    required this.displayName,
    required this.invitedAccountId,
    required this.roleId,
    required this.roleName,
    required this.invitedByAccountId,
    required this.invitedByFullName,
    required this.invitedByEmail,
    required this.status,
    required this.createdAt,
    required this.expiresAt,
    required this.respondedAt,
    required this.permissionIds,
  });

  bool get isPending => status == 1;

  String get inviterDisplayName {
    final fullName = invitedByFullName.trim();
    if (fullName.isNotEmpty) {
      return fullName;
    }

    final email = invitedByEmail.trim();
    if (email.isNotEmpty) {
      return email;
    }

    return 'Quản trị cửa hàng';
  }
}
