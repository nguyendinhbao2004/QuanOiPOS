import '../../domain/entities/dining_table.dart';
import '../../domain/entities/table_status.dart';

class DiningTableModel {
  final int id;
  final int storeId;
  final int areaId;
  final String name;
  final int capacity;
  final TableStatus status;
  final DateTime? createdAt;
  final String? createdBy;
  final DateTime? updatedAt;
  final String? updatedBy;
  final bool isDeleted;

  const DiningTableModel({
    required this.id,
    required this.storeId,
    required this.areaId,
    required this.name,
    required this.capacity,
    required this.status,
    this.createdAt,
    this.createdBy,
    this.updatedAt,
    this.updatedBy,
    required this.isDeleted,
  });

  factory DiningTableModel.fromJson(Object? json) {
    if (json is! Map<String, dynamic>) {
      throw const FormatException('Invalid table data');
    }

    return DiningTableModel(
      id: _intValue(json['id']),
      storeId: _intValue(json['storeId']),
      areaId: _intValue(json['areaId']),
      name: _stringValue(json['name'], fallback: 'Bàn'),
      capacity: _intValue(json['capacity']),
      status: statusFromJson(json['status']),
      createdAt: _dateValue(json['createdAt']),
      createdBy: _nullableString(json['createdBy']),
      updatedAt: _dateValue(json['updatedAt']),
      updatedBy: _nullableString(json['updatedBy']),
      isDeleted: _boolValue(json['isDeleted']),
    );
  }

  static List<DiningTableModel> listFromJson(Object? json) {
    if (json == null) {
      return const [];
    }

    if (json is List) {
      return json.map(DiningTableModel.fromJson).toList();
    }

    if (json is Map<String, dynamic>) {
      final items = json['items'] ?? json['tables'] ?? json['data'];
      if (items is List) {
        return items.map(DiningTableModel.fromJson).toList();
      }
    }

    throw const FormatException('Invalid table list data');
  }

  static TableStatus statusFromJson(Object? value) {
    final text = value?.toString().trim().toLowerCase();
    return switch (text) {
      'available' => TableStatus.available,
      'occupied' => TableStatus.occupied,
      'reserved' => TableStatus.reserved,
      _ => TableStatus.unknown,
    };
  }

  DiningTable toEntity() {
    return DiningTable(
      id: id,
      storeId: storeId,
      areaId: areaId,
      name: name,
      capacity: capacity,
      status: status,
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

  static bool _boolValue(Object? value) {
    if (value is bool) {
      return value;
    }

    if (value is String) {
      return value.toLowerCase() == 'true';
    }

    if (value is num) {
      return value != 0;
    }

    return false;
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
