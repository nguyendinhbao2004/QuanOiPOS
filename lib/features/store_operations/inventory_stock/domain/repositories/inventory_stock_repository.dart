import '../entities/inventory_stock.dart';

abstract class InventoryStockRepository {
  Future<List<InventoryStockItem>> loadItems({
    required int storeId,
    required InventoryStockItemType type,
    required InventoryStockStatus status,
  });

  Future<List<InventoryMovement>> loadMovements({
    required InventoryStockItemType type,
    required int itemId,
    DateTime? from,
    DateTime? to,
  });
}
