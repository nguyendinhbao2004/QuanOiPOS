import 'inventory_deduction_mode.dart';

class IngredientInventorySettings {
  final int ingredientId;
  final double minimumStock;
  final bool isTrackInventory;

  const IngredientInventorySettings({
    required this.ingredientId,
    required this.minimumStock,
    required this.isTrackInventory,
  });
}

class ProductInventorySettings {
  final int productId;
  final double minimumStock;
  final bool isTrackInventory;
  final InventoryDeductionMode inventoryDeductionMode;
  final double quantity;
  final double averageUnitCost;
  final double lastImportUnitCost;
  final bool isLowStock;
  final bool isOutOfStock;

  const ProductInventorySettings({
    required this.productId,
    required this.minimumStock,
    required this.isTrackInventory,
    required this.inventoryDeductionMode,
    required this.quantity,
    required this.averageUnitCost,
    required this.lastImportUnitCost,
    required this.isLowStock,
    required this.isOutOfStock,
  });
}
