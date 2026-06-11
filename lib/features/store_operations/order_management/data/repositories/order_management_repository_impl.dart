import '../../domain/entities/create_order_draft.dart';
import '../../domain/entities/order.dart';
import '../../domain/entities/session_invoice.dart';
import '../../domain/repositories/order_management_repository.dart';
import '../datasources/order_management_remote_data_source.dart';
import '../models/create_order_request_model.dart';

class OrderManagementRepositoryImpl implements OrderManagementRepository {
  final OrderManagementRemoteDataSource _remoteDataSource;

  const OrderManagementRepositoryImpl(this._remoteDataSource);

  @override
  Future<List<Order>> loadOrdersByTableSession(int tableSessionId) async {
    final models = await _remoteDataSource.getOrdersByTableSession(
      tableSessionId,
    );
    return models.map((model) => model.toEntity()).toList();
  }

  @override
  Future<Order> loadOrderDetail(int orderId) async {
    return (await _remoteDataSource.getOrderById(orderId)).toEntity();
  }

  @override
  Future<Order> createOrder(CreateOrderDraft draft) async {
    final model = await _remoteDataSource.createOrder(
      CreateOrderRequestModel(draft),
    );
    return model.toEntity();
  }

  @override
  Future<SessionInvoice> createSessionInvoice({
    required int tableSessionId,
    required PaymentMethod method,
  }) async {
    final model = await _remoteDataSource.createSessionInvoice(
      tableSessionId: tableSessionId,
      method: method.apiValue,
    );
    return model.toEntity();
  }

  @override
  Future<SessionInvoice> createOrderInvoice({
    required int orderId,
    required PaymentMethod method,
  }) async {
    final model = await _remoteDataSource.createOrderInvoice(
      orderId: orderId,
      method: method.apiValue,
    );
    return model.toEntity();
  }

  @override
  Future<void> confirmPayment(int paymentId) {
    return _remoteDataSource.confirmPayment(paymentId);
  }
}
