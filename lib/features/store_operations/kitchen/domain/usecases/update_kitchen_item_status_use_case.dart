import '../entities/kitchen_order_item.dart';
import '../repositories/kitchen_repository.dart';

class UpdateKitchenItemStatusUseCase {
  final KitchenRepository _repository;

  const UpdateKitchenItemStatusUseCase(this._repository);

  Future<KitchenOrderItem> call({
    required int orderItemId,
    required KitchenOrderItemStatus status,
  }) {
    return _repository.updateItemStatus(
      orderItemId: orderItemId,
      status: status,
    );
  }
}
