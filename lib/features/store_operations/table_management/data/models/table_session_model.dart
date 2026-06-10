import '../../domain/entities/table_session.dart';

class TableSessionModel {
  final int id;
  final int tableId;
  final DateTime? openTime;
  final DateTime? closeTime;
  final TableSessionStatus status;
  final DateTime? createdAt;
  final String? createdBy;
  final DateTime? updatedAt;
  final String? updatedBy;
  final bool isDeleted;

  const TableSessionModel({
    required this.id,
    required this.tableId,
    this.openTime,
    this.closeTime,
    required this.status,
    this.createdAt,
    this.createdBy,
    this.updatedAt,
    this.updatedBy,
    required this.isDeleted,
  });

  factory TableSessionModel.fromJson(Object? json) {
    if (json is! Map<String, dynamic>) {
      throw const FormatException('Invalid table session data');
    }

    return TableSessionModel(
      id: _intValue(json['id']),
      tableId: _intValue(json['tableId']),
      openTime: _dateValue(json['openTime']),
      closeTime: _dateValue(json['closeTime']),
      status: statusFromJson(json['status']),
      createdAt: _dateValue(json['createdAt']),
      createdBy: _nullableString(json['createdBy']),
      updatedAt: _dateValue(json['updatedAt']),
      updatedBy: _nullableString(json['updatedBy']),
      isDeleted: _boolValue(json['isDeleted']),
    );
  }

  static List<TableSessionModel> listFromJson(Object? json) {
    if (json == null) {
      return const [];
    }

    if (json is List) {
      return json.map(TableSessionModel.fromJson).toList();
    }

    if (json is Map<String, dynamic>) {
      final items = json['items'] ?? json['sessions'] ?? json['data'];
      if (items is List) {
        return items.map(TableSessionModel.fromJson).toList();
      }
    }

    throw const FormatException('Invalid table session list data');
  }

  static TableSessionStatus statusFromJson(Object? value) {
    if (value is num) {
      return switch (value.toInt()) {
        1 => TableSessionStatus.open,
        2 => TableSessionStatus.closed,
        3 => TableSessionStatus.cancelled,
        _ => TableSessionStatus.unknown,
      };
    }

    final text = value?.toString().trim().toLowerCase();
    return switch (text) {
      '1' || 'open' => TableSessionStatus.open,
      '2' || 'closed' || 'close' => TableSessionStatus.closed,
      '3' ||
      'cancelled' ||
      'canceled' ||
      'cancel' => TableSessionStatus.cancelled,
      _ => TableSessionStatus.unknown,
    };
  }

  TableSession toEntity() {
    return TableSession(
      id: id,
      tableId: tableId,
      openTime: openTime,
      closeTime: closeTime,
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
