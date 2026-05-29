class Area {
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

  const Area({
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
}
