class ProductIngredient {
  final int id;
  final int storeId;
  final String name;
  final int itemType;
  final String unit;
  final int quantity;
  final int capacity;
  final int currentCapacity;
  final bool isActive;
  final bool isDeleted;

  const ProductIngredient({
    required this.id,
    required this.storeId,
    required this.name,
    required this.itemType,
    required this.unit,
    required this.quantity,
    required this.capacity,
    required this.currentCapacity,
    required this.isActive,
    required this.isDeleted,
  });
}
