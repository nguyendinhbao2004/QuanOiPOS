import '../entities/kitchen_order_item.dart';
import '../repositories/kitchen_repository.dart';

class BulkCancelKitchenItemsUseCase {
  final KitchenRepository _repository;

  const BulkCancelKitchenItemsUseCase(this._repository);

  Future<KitchenBulkUpdateResult> call(List<int> itemIds) {
    return _repository.bulkCancel(itemIds);
  }
}
