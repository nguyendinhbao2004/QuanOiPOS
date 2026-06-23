class ProductIngredient {
  final int id;
  final int storeId;
  final String name;
  final int itemType;
  final String unit;
  final double quantity;
  final double minimumStock;
  final double averageUnitCost;
  final double lastImportUnitCost;
  final bool isTrackInventory;
  final bool isLowStock;
  final bool isOutOfStock;
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
    this.minimumStock = 0,
    this.averageUnitCost = 0,
    this.lastImportUnitCost = 0,
    this.isTrackInventory = false,
    this.isLowStock = false,
    this.isOutOfStock = false,
    required this.capacity,
    required this.currentCapacity,
    required this.isActive,
    required this.isDeleted,
  });

  ProductIngredient copyWith({
    String? name,
    String? unit,
    int? itemType,
    int? capacity,
    double? minimumStock,
    bool? isTrackInventory,
    bool? isLowStock,
    bool? isOutOfStock,
  }) {
    return ProductIngredient(
      id: id,
      storeId: storeId,
      name: name ?? this.name,
      itemType: itemType ?? this.itemType,
      unit: unit ?? this.unit,
      quantity: quantity,
      minimumStock: minimumStock ?? this.minimumStock,
      averageUnitCost: averageUnitCost,
      lastImportUnitCost: lastImportUnitCost,
      isTrackInventory: isTrackInventory ?? this.isTrackInventory,
      isLowStock: isLowStock ?? this.isLowStock,
      isOutOfStock: isOutOfStock ?? this.isOutOfStock,
      capacity: capacity ?? this.capacity,
      currentCapacity: currentCapacity,
      isActive: isActive,
      isDeleted: isDeleted,
    );
  }
}
