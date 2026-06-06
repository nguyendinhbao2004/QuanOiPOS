import '../../domain/entities/staff_role.dart';
import 'staff_model_helpers.dart';
import 'staff_permission_model.dart';

class StaffRoleModel {
  final int id;
  final int? storeId;
  final String name;
  final bool isSystemRole;
  final List<StaffPermissionModel> permissions;

  const StaffRoleModel({
    required this.id,
    required this.storeId,
    required this.name,
    required this.isSystemRole,
    required this.permissions,
  });

  factory StaffRoleModel.fromJson(Object? json) {
    if (json is! Map<String, dynamic>) {
      throw const FormatException('Invalid staff role data');
    }

    return StaffRoleModel(
      id: intValue(readJson(json, 'id', 'Id')),
      storeId: nullableIntValue(readJson(json, 'storeId', 'StoreId')),
      name: stringValue(readJson(json, 'name', 'Name')),
      isSystemRole: boolValue(readJson(json, 'isSystemRole', 'IsSystemRole')),
      permissions: StaffPermissionModel.listFromJson(
        readJson(json, 'permissions', 'Permissions'),
      ),
    );
  }

  static List<StaffRoleModel> listFromJson(Object? json) {
    if (json == null) {
      return const [];
    }

    if (json is List) {
      return json.map(StaffRoleModel.fromJson).toList();
    }

    throw const FormatException('Invalid staff role list data');
  }

  StaffRole toEntity() {
    return StaffRole(
      id: id,
      storeId: storeId,
      name: name,
      isSystemRole: isSystemRole,
      permissions: permissions
          .map((permission) => permission.toEntity())
          .toList(),
    );
  }
}
