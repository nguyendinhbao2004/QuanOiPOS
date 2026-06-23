import '../entities/kitchen_order_item.dart';
import '../repositories/kitchen_repository.dart';

class LoadKitchenItemsUseCase {
  final KitchenRepository _repository;

  const LoadKitchenItemsUseCase(this._repository);

  Future<List<KitchenOrderItem>> call({
    required int storeId,
    KitchenItemFilter filter = const KitchenItemFilter(),
  }) {
    return _repository.loadItems(storeId: storeId, filter: filter);
  }
}
