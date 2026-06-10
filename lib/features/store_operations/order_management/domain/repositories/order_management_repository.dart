import '../entities/create_order_draft.dart';
import '../entities/order.dart';

abstract class OrderManagementRepository {
  Future<List<Order>> loadOrdersByTableSession(int tableSessionId);

  Future<Order> loadOrderDetail(int orderId);

  Future<Order> createOrder(CreateOrderDraft draft);
}
