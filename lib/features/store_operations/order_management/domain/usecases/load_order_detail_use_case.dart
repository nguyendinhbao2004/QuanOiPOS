import '../entities/order.dart';
import '../repositories/order_management_repository.dart';

class LoadOrderDetailUseCase {
  final OrderManagementRepository _repository;

  const LoadOrderDetailUseCase(this._repository);

  Future<Order> call(int orderId) {
    return _repository.loadOrderDetail(orderId);
  }
}
