import 'staff_permission.dart';

class PermissionGroup {
  final int groupId;
  final String groupName;
  final String description;
  final List<StaffPermission> permissions;

  const PermissionGroup({
    required this.groupId,
    required this.groupName,
    required this.description,
    required this.permissions,
  });
}
