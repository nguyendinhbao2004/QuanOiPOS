import '../entities/create_order_draft.dart';
import '../entities/order.dart';
import '../repositories/order_management_repository.dart';

class CreateOrderUseCase {
  final OrderManagementRepository _repository;

  const CreateOrderUseCase(this._repository);

  Future<Order> call(CreateOrderDraft draft) {
    if (draft.items.isEmpty) {
      throw Exception('Đơn hàng phải có ít nhất một món');
    }
    return _repository.createOrder(draft);
  }
}
