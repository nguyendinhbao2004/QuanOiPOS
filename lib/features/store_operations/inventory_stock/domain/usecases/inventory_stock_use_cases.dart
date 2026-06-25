import '../entities/inventory_stock.dart';
import '../repositories/inventory_stock_repository.dart';

class LoadInventoryStockItemsUseCase {
  final InventoryStockRepository _repository;

  const LoadInventoryStockItemsUseCase(this._repository);

  Future<List<InventoryStockItem>> call({
    required int storeId,
    required InventoryStockItemType type,
    required InventoryStockStatus status,
  }) => _repository.loadItems(storeId: storeId, type: type, status: status);
}

class LoadInventoryMovementsUseCase {
  final InventoryStockRepository _repository;

  const LoadInventoryMovementsUseCase(this._repository);

  Future<List<InventoryMovement>> call({
    required InventoryStockItemType type,
    required int itemId,
    DateTime? from,
    DateTime? to,
  }) =>
      _repository.loadMovements(type: type, itemId: itemId, from: from, to: to);
}
