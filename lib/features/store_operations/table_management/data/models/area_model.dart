import '../../domain/entities/area.dart';

class AreaModel {
  final int id;
  final int storeId;
  final String name;
  final String description;
  final int displayOrder;
  final bool isActive;
  final DateTime? createdAt;
  final String? createdBy;
  final DateTime? updatedAt;
  final String? updatedBy;
  final bool isDeleted;

  const AreaModel({
    required this.id,
    required this.storeId,
    required this.name,
    required this.description,
    required this.displayOrder,
    required this.isActive,
    this.createdAt,
    this.createdBy,
    this.updatedAt,
    this.updatedBy,
    required this.isDeleted,
  });

  factory AreaModel.fromJson(Object? json) {
    if (json is! Map<String, dynamic>) {
      throw const FormatException('Invalid area data');
    }

    return AreaModel(
      id: _intValue(json['id']),
      storeId: _intValue(json['storeId']),
      name: _stringValue(json['name'], fallback: 'Khu vực'),
      description: _stringValue(json['description']),
      displayOrder: _intValue(json['displayOrder']),
      isActive: _boolValue(json['isActive'], fallback: true),
      createdAt: _dateValue(json['createdAt']),
      createdBy: _nullableString(json['createdBy']),
      updatedAt: _dateValue(json['updatedAt']),
      updatedBy: _nullableString(json['updatedBy']),
      isDeleted: _boolValue(json['isDeleted']),
    );
  }

  static List<AreaModel> listFromJson(Object? json) {
    if (json == null) {
      return const [];
    }

    if (json is List) {
      return json.map(AreaModel.fromJson).toList();
    }

    if (json is Map<String, dynamic>) {
      final items = json['items'] ?? json['areas'] ?? json['data'];
      if (items is List) {
        return items.map(AreaModel.fromJson).toList();
      }
    }

    throw const FormatException('Invalid area list data');
  }

  Area toEntity() {
    return Area(
      id: id,
      storeId: storeId,
      name: name,
      description: description,
      displayOrder: displayOrder,
      isActive: isActive,
      createdAt: createdAt,
      createdBy: createdBy,
      updatedAt: updatedAt,
      updatedBy: updatedBy,
      isDeleted: isDeleted,
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

  static String _stringValue(Object? value, {String fallback = ''}) {
    if (value == null) {
      return fallback;
    }

    final text = value.toString().trim();
    return text.isEmpty ? fallback : text;
  }

  static String? _nullableString(Object? value) {
    final text = _stringValue(value);
    return text.isEmpty ? null : text;
  }

  static bool _boolValue(Object? value, {bool fallback = false}) {
    if (value is bool) {
      return value;
    }

    if (value is String) {
      return value.toLowerCase() == 'true';
    }

    if (value is num) {
      return value != 0;
    }

    return fallback;
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
