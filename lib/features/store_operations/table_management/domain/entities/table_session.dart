enum TableSessionStatus { open, closed, cancelled, unknown }

extension TableSessionStatusX on TableSessionStatus {
  String get label {
    return switch (this) {
      TableSessionStatus.open => 'Đang mở',
      TableSessionStatus.closed => 'Đã đóng',
      TableSessionStatus.cancelled => 'Đã hủy',
      TableSessionStatus.unknown => 'Không rõ',
    };
  }
}

class TableSession {
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

  const TableSession({
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
}
