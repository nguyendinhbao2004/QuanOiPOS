import 'dart:convert';

import '../../domain/entities/store_access_context.dart';
import '../models/store_model.dart';
import '../models/store_permission_model.dart';

class StoreAccessContextCacheModel {
  final int accountId;
  final int storeId;
  final StoreModel store;
  final List<StorePermissionModel> permissions;
  final DateTime cachedAt;

  const StoreAccessContextCacheModel({
    required this.accountId,
    required this.storeId,
    required this.store,
    required this.permissions,
    required this.cachedAt,
  });

  factory StoreAccessContextCacheModel.fromEntity({
    required int accountId,
    required StoreAccessContext context,
    DateTime? cachedAt,
  }) {
    return StoreAccessContextCacheModel(
      accountId: accountId,
      storeId: context.store.id,
      store: StoreModel.fromEntity(context.store),
      permissions: context.permissions
          .map(StorePermissionModel.fromEntity)
          .toList(),
      cachedAt: cachedAt ?? DateTime.now(),
    );
  }

  factory StoreAccessContextCacheModel.fromJson(Object? json) {
    if (json is! Map<String, dynamic>) {
      throw const FormatException('Invalid store access cache data');
    }

    final permissionsJson = json['permissions'];
    if (permissionsJson is! List) {
      throw const FormatException('Invalid cached permissions data');
    }

    return StoreAccessContextCacheModel(
      accountId: _intValue(json['accountId']),
      storeId: _intValue(json['storeId']),
      store: StoreModel.fromJson(json['store']),
      permissions: permissionsJson.map(StorePermissionModel.fromJson).toList(),
      cachedAt:
          _dateValue(json['cachedAt']) ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }

  factory StoreAccessContextCacheModel.fromStorage(String value) {
    return StoreAccessContextCacheModel.fromJson(jsonDecode(value));
  }

  Map<String, dynamic> toJson() {
    return {
      'accountId': accountId,
      'storeId': storeId,
      'store': store.toJson(),
      'permissions': permissions
          .map((permission) => permission.toJson())
          .toList(),
      'cachedAt': cachedAt.toIso8601String(),
    };
  }

  String toStorage() => jsonEncode(toJson());

  StoreAccessContext toEntity() {
    return StoreAccessContext(
      store: store.toEntity(),
      permissions: permissions
          .map((permission) => permission.toEntity())
          .toList(),
    );
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

  static DateTime? _dateValue(Object? value) {
    if (value is DateTime) {
      return value;
    }

    if (value is String && value.trim().isNotEmpty) {
      return DateTime.tryParse(value);
    }

    return null;
  }
}
