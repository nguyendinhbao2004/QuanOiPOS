import '../../domain/entities/staff_permission.dart';
import 'staff_model_helpers.dart';

class StaffPermissionModel {
  final int id;
  final String code;
  final String name;
  final int groupId;
  final String groupName;

  const StaffPermissionModel({
    required this.id,
    required this.code,
    required this.name,
    required this.groupId,
    required this.groupName,
  });

  factory StaffPermissionModel.fromJson(Object? json) {
    if (json is! Map<String, dynamic>) {
      throw const FormatException('Invalid staff permission data');
    }

    return StaffPermissionModel(
      id: intValue(readJson(json, 'id', 'Id')),
      code: stringValue(readJson(json, 'code', 'Code')),
      name: stringValue(readJson(json, 'name', 'Name')),
      groupId: intValue(readJson(json, 'groupId', 'GroupId')),
      groupName: stringValue(readJson(json, 'groupName', 'GroupName')),
    );
  }

  static List<StaffPermissionModel> listFromJson(Object? json) {
    if (json == null) {
      return const [];
    }

    if (json is List) {
      return json.map(StaffPermissionModel.fromJson).toList();
    }

    throw const FormatException('Invalid staff permission list data');
  }

  StaffPermission toEntity() {
    return StaffPermission(
      id: id,
      code: code,
      name: name,
      groupId: groupId,
      groupName: groupName,
    );
  }
}
