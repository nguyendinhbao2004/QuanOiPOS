import '../../domain/entities/store_permission.dart';

class StorePermissionModel {
  final int permissionId;
  final String code;

  const StorePermissionModel({required this.permissionId, required this.code});

  factory StorePermissionModel.fromEntity(StorePermission permission) {
    return StorePermissionModel(
      permissionId: permission.permissionId,
      code: permission.code,
    );
  }

  factory StorePermissionModel.fromJson(Object? json) {
    if (json is! Map<String, dynamic>) {
      throw const FormatException('Invalid store permission data');
    }

    return StorePermissionModel(
      permissionId: _intValue(json['permissionId']),
      code: _stringValue(json['code']),
    );
  }

  static List<StorePermissionModel> listFromJson(Object? json) {
    if (json == null) {
      return const [];
    }

    if (json is List) {
      return json.map(StorePermissionModel.fromJson).toList();
    }

    if (json is Map<String, dynamic>) {
      final items = json['items'] ?? json['permissions'] ?? json['data'];
      if (items is List) {
        return items.map(StorePermissionModel.fromJson).toList();
      }
    }

    throw const FormatException('Invalid store permission list data');
  }

  StorePermission toEntity() {
    return StorePermission(permissionId: permissionId, code: code);
  }

  Map<String, dynamic> toJson() {
    return {'permissionId': permissionId, 'code': code};
  }

  static int _intValue(Object? value) {
    if (value is num) {
      return value.toInt();
    }

    if (value is String) {
      return int.tryParse(value) ?? 0;
    }

    return 0;
  }

  static String _stringValue(Object? value, {String fallback = ''}) {
    if (value == null) {
      return fallback;
    }

    final text = value.toString().trim();
    return text.isEmpty ? fallback : text;
  }
}
