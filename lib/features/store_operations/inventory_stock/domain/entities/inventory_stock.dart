enum InventoryStockItemType {
  product('Product', 'Sản phẩm'),
  ingredient('Ingredient', 'Nguyên liệu');

  final String apiValue;
  final String label;

  const InventoryStockItemType(this.apiValue, this.label);
}

enum InventoryStockStatus {
  all('all', 'Tất cả'),
  low('low', 'Sắp hết'),
  out('out', 'Hết hàng');

  final String apiValue;
  final String label;

  const InventoryStockStatus(this.apiValue, this.label);
}

class InventoryStockItem {
  final InventoryStockItemType type;
  final int id;
  final int storeId;
  final String name;
  final String unit;
  final double quantity;
  final double minimumStock;
  final double averageUnitCost;
  final double lastImportUnitCost;
  final bool isTrackInventory;
  final String? inventoryDeductionMode;
  final bool isLowStock;
  final bool isOutOfStock;

  const InventoryStockItem({
    required this.type,
    required this.id,
    required this.storeId,
    required this.name,
    required this.unit,
    required this.quantity,
    required this.minimumStock,
    required this.averageUnitCost,
    required this.lastImportUnitCost,
    required this.isTrackInventory,
    required this.inventoryDeductionMode,
    required this.isLowStock,
    required this.isOutOfStock,
  });

  double get inventoryValue => quantity * averageUnitCost;

  String get displayUnit => unit.trim().isEmpty ? 'sp' : unit.trim();
}

class InventoryMovement {
  final int id;
  final int? ingredientId;
  final int? productId;
  final String type;
  final String reason;
  final double quantity;
  final double requestedQuantity;
  final double shortageQuantity;
  final double unitCost;
  final double totalCost;
  final int? orderId;
  final int? orderItemId;
  final String? note;
  final String? destinationName;
  final DateTime? occurredAt;

  const InventoryMovement({
    required this.id,
    required this.ingredientId,
    required this.productId,
    required this.type,
    required this.reason,
    required this.quantity,
    required this.requestedQuantity,
    required this.shortageQuantity,
    required this.unitCost,
    required this.totalCost,
    required this.orderId,
    required this.orderItemId,
    required this.note,
    required this.destinationName,
    required this.occurredAt,
  });
}
