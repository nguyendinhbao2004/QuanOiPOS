import '../../domain/entities/kitchen_order_item.dart';
import '../../domain/repositories/kitchen_repository.dart';
import '../datasources/kitchen_remote_data_source.dart';

class KitchenRepositoryImpl implements KitchenRepository {
  final KitchenRemoteDataSource _remoteDataSource;

  const KitchenRepositoryImpl(this._remoteDataSource);

  @override
  Future<List<KitchenOrderItem>> loadItems({
    required int storeId,
    KitchenItemFilter filter = const KitchenItemFilter(),
  }) async {
    final models = await _remoteDataSource.getItems(
      storeId: storeId,
      filter: filter,
    );
    return models.map((model) => model.toEntity()).toList();
  }

  @override
  Future<KitchenOrderItem> updateItemStatus({
    required int orderItemId,
    required KitchenOrderItemStatus status,
  }) async {
    return (await _remoteDataSource.updateItemStatus(
      orderItemId: orderItemId,
      status: status,
    )).toEntity();
  }

  @override
  Future<KitchenOrderItem> cancelItem(int orderItemId) async {
    return (await _remoteDataSource.cancelItem(orderItemId)).toEntity();
  }

  @override
  Future<KitchenBulkUpdateResult> bulkUpdateStatus({
    required List<int> itemIds,
    required KitchenOrderItemStatus status,
  }) async {
    return (await _remoteDataSource.bulkUpdateStatus(
      itemIds: itemIds,
      status: status,
    )).toEntity();
  }

  @override
  Future<KitchenBulkUpdateResult> bulkCancel(List<int> itemIds) async {
    return (await _remoteDataSource.bulkCancel(itemIds)).toEntity();
  }
}
