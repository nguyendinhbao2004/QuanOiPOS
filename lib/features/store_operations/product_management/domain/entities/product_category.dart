class ProductCategory {
  final int id;
  final int storeId;
  final String name;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final bool isDeleted;

  const ProductCategory({
    required this.id,
    required this.storeId,
    required this.name,
    this.createdAt,
    this.updatedAt,
    required this.isDeleted,
  });
}
