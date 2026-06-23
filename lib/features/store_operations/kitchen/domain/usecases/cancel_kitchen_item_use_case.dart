import '../entities/kitchen_order_item.dart';
import '../repositories/kitchen_repository.dart';

class CancelKitchenItemUseCase {
  final KitchenRepository _repository;

  const CancelKitchenItemUseCase(this._repository);

  Future<KitchenOrderItem> call(int orderItemId) {
    return _repository.cancelItem(orderItemId);
  }
}
