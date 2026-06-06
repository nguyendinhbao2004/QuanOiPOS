import '../../domain/entities/permission_group.dart';
import 'staff_model_helpers.dart';
import 'staff_permission_model.dart';

class PermissionGroupModel {
  final int groupId;
  final String groupName;
  final String description;
  final List<StaffPermissionModel> permissions;

  const PermissionGroupModel({
    required this.groupId,
    required this.groupName,
    required this.description,
    required this.permissions,
  });

  factory PermissionGroupModel.fromJson(Object? json) {
    if (json is! Map<String, dynamic>) {
      throw const FormatException('Invalid permission group data');
    }

    return PermissionGroupModel(
      groupId: intValue(readJson(json, 'groupId', 'GroupId')),
      groupName: stringValue(readJson(json, 'groupName', 'GroupName')),
      description: stringValue(readJson(json, 'description', 'Description')),
      permissions: StaffPermissionModel.listFromJson(
        readJson(json, 'permissions', 'Permissions'),
      ),
    );
  }

  static List<PermissionGroupModel> listFromJson(Object? json) {
    if (json == null) {
      return const [];
    }

    if (json is List) {
      return json.map(PermissionGroupModel.fromJson).toList();
    }

    throw const FormatException('Invalid permission group list data');
  }

  PermissionGroup toEntity() {
    return PermissionGroup(
      groupId: groupId,
      groupName: groupName,
      description: description,
      permissions: permissions
          .map((permission) => permission.toEntity())
          .toList(),
    );
  }
}
