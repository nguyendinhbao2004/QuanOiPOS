import '../../domain/entities/inventory_stock.dart';
import '../../domain/repositories/inventory_stock_repository.dart';
import '../datasources/inventory_stock_remote_data_source.dart';

class InventoryStockRepositoryImpl implements InventoryStockRepository {
  final InventoryStockRemoteDataSource _remote;

  InventoryStockRepositoryImpl(this._remote);

  @override
  Future<List<InventoryStockItem>> loadItems({
    required int storeId,
    required InventoryStockItemType type,
    required InventoryStockStatus status,
  }) async => (await _remote.getItems(
    storeId: storeId,
    type: type,
    status: status,
  )).map((model) => model.toEntity()).toList();

  @override
  Future<List<InventoryMovement>> loadMovements({
    required InventoryStockItemType type,
    required int itemId,
    DateTime? from,
    DateTime? to,
  }) async => (await _remote.getMovements(
    type: type,
    itemId: itemId,
    from: from,
    to: to,
  )).map((model) => model.toEntity()).toList();
}
