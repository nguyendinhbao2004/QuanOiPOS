import 'staff_permission.dart';

class StaffRole {
  final int id;
  final int? storeId;
  final String name;
  final bool isSystemRole;
  final List<StaffPermission> permissions;

  const StaffRole({
    required this.id,
    required this.storeId,
    required this.name,
    required this.isSystemRole,
    this.permissions = const [],
  });

  List<int> get permissionIds {
    return permissions.map((permission) => permission.id).toList();
  }
}
