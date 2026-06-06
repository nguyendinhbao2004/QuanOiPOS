class InviteStaffRequestModel {
  final int storeId;
  final String invitedEmail;
  final String displayName;
  final int roleId;
  final List<int> permissionIds;

  const InviteStaffRequestModel({
    required this.storeId,
    required this.invitedEmail,
    required this.displayName,
    required this.roleId,
    required this.permissionIds,
  });

  Map<String, dynamic> toJson() {
    return {
      'StoreId': storeId,
      'InvitedEmail': invitedEmail,
      'DisplayName': displayName,
      'RoleId': roleId,
      'PermissionIds': permissionIds,
    };
  }
}

class UpdateStaffDisplayNameRequestModel {
  final String displayName;

  const UpdateStaffDisplayNameRequestModel({required this.displayName});

  Map<String, dynamic> toJson() {
    return {'DisplayName': displayName};
  }
}

class UpdateStaffAccessRequestModel {
  final int roleId;
  final List<int> permissionIds;

  const UpdateStaffAccessRequestModel({
    required this.roleId,
    required this.permissionIds,
  });

  Map<String, dynamic> toJson() {
    return {'RoleId': roleId, 'PermissionIds': permissionIds};
  }
}

class StaffRoleRequestModel {
  final String name;
  final List<int> permissionIds;

  const StaffRoleRequestModel({
    required this.name,
    required this.permissionIds,
  });

  Map<String, dynamic> toJson() {
    return {'Name': name, 'PermissionIds': permissionIds};
  }
}
