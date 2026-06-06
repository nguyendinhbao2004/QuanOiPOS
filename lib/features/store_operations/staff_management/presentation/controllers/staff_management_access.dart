class StaffManagementAccess {
  final int storeId;
  final bool canViewStaff;
  final bool canInviteStaff;
  final bool canUpdateStaff;
  final bool canRemoveStaff;
  final bool canManageRoles;

  const StaffManagementAccess({
    required this.storeId,
    required this.canViewStaff,
    required this.canInviteStaff,
    required this.canUpdateStaff,
    required this.canRemoveStaff,
    required this.canManageRoles,
  });

  bool get canOpenStaffModule {
    return canViewStaff || canInviteStaff || canUpdateStaff || canRemoveStaff;
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is StaffManagementAccess &&
            storeId == other.storeId &&
            canViewStaff == other.canViewStaff &&
            canInviteStaff == other.canInviteStaff &&
            canUpdateStaff == other.canUpdateStaff &&
            canRemoveStaff == other.canRemoveStaff &&
            canManageRoles == other.canManageRoles;
  }

  @override
  int get hashCode => Object.hash(
    storeId,
    canViewStaff,
    canInviteStaff,
    canUpdateStaff,
    canRemoveStaff,
    canManageRoles,
  );
}
