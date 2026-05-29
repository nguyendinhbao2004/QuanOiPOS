import 'table_status.dart';

class DiningTable {
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

  const DiningTable({
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
}
