class ProductTopping {
  final int id;
  final int storeId;
  final String name;
  final int price;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final bool isDeleted;

  const ProductTopping({
    required this.id,
    required this.storeId,
    required this.name,
    required this.price,
    this.createdAt,
    this.updatedAt,
    required this.isDeleted,
  });
}
