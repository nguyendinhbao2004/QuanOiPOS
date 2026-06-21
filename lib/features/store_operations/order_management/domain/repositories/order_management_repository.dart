import '../entities/create_order_draft.dart';
import '../entities/order.dart';
import '../entities/session_invoice.dart';

abstract class OrderManagementRepository {
  Future<List<Order>> loadOrdersByTableSession(int tableSessionId);

  Future<Order> loadOrderDetail(int orderId);

  Future<Order> createOrder(CreateOrderDraft draft);

  Future<SessionInvoice> createSessionInvoice({
    required int tableSessionId,
    required PaymentMethod method,
  });

  Future<SessionInvoice> createOrderInvoice({
    required int orderId,
    required PaymentMethod method,
  });

  Future<void> confirmPayment(int paymentId);

  Future<List<VietQrBank>> loadVietQrBanks();
}
