import '../entities/kitchen_order_item.dart';
import '../repositories/kitchen_repository.dart';

class BulkUpdateKitchenItemsUseCase {
  final KitchenRepository _repository;

  const BulkUpdateKitchenItemsUseCase(this._repository);

  Future<KitchenBulkUpdateResult> call({
    required List<int> itemIds,
    required KitchenOrderItemStatus status,
  }) {
    return _repository.bulkUpdateStatus(itemIds: itemIds, status: status);
  }
}
