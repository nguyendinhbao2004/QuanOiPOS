import '../entities/order.dart';
import '../repositories/order_management_repository.dart';

class LoadOrdersByTableSessionUseCase {
  final OrderManagementRepository _repository;

  const LoadOrdersByTableSessionUseCase(this._repository);

  Future<List<Order>> call(int tableSessionId) {
    return _repository.loadOrdersByTableSession(tableSessionId);
  }
}
