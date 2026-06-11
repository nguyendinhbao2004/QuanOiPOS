import '../../../../../core/network/dio/dio_client.dart';
import '../models/create_order_request_model.dart';
import '../models/order_model.dart';
import '../models/session_invoice_model.dart';

class OrderManagementRemoteDataSource {
  final DioClient _dioClient;

  const OrderManagementRemoteDataSource(this._dioClient);

  Future<List<OrderModel>> getOrdersByTableSession(int tableSessionId) async {
    final response = await _dioClient.getResponse<List<OrderModel>>(
      '/orders/table-session/$tableSessionId',
      dataFromJson: OrderModel.listFromJson,
    );
    if (!response.succeeded || response.data == null) {
      _throwFailure(
        response.message,
        response.errors,
        'Không thể tải đơn hàng',
      );
    }
    return response.data!;
  }

  Future<OrderModel> getOrderById(int orderId) async {
    final response = await _dioClient.getResponse<OrderModel>(
      '/orders/$orderId',
      dataFromJson: OrderModel.fromJson,
    );
    if (!response.succeeded || response.data == null) {
      _throwFailure(
        response.message,
        response.errors,
        'Không thể tải chi tiết đơn hàng',
      );
    }
    return response.data!;
  }

  Future<OrderModel> createOrder(CreateOrderRequestModel request) async {
    final response = await _dioClient.postResponse<OrderModel>(
      '/orders',
      data: request.toJson(),
      dataFromJson: OrderModel.fromJson,
    );
    if (!response.succeeded || response.data == null) {
      _throwFailure(
        response.message,
        response.errors,
        'Không thể tạo đơn hàng',
      );
    }
    return response.data!;
  }

  Future<SessionInvoiceModel> createSessionInvoice({
    required int tableSessionId,
    required int method,
  }) {
    return _createInvoice(
      orderId: null,
      tableSessionId: tableSessionId,
      method: method,
    );
  }

  Future<SessionInvoiceModel> createOrderInvoice({
    required int orderId,
    required int method,
  }) {
    return _createInvoice(
      orderId: orderId,
      tableSessionId: null,
      method: method,
    );
  }

  Future<SessionInvoiceModel> _createInvoice({
    required int? orderId,
    required int? tableSessionId,
    required int method,
  }) async {
    final response = await _dioClient.postResponse<SessionInvoiceModel>(
      '/invoices',
      data: {
        'orderId': orderId,
        'tableSessionId': tableSessionId,
        'method': method,
        'discountAmount': 0,
        'taxAmount': 0,
        'serviceCharge': 0,
      },
      dataFromJson: SessionInvoiceModel.fromJson,
    );
    if (!response.succeeded || response.data == null) {
      _throwFailure(response.message, response.errors, 'Không thể tạo hóa đơn');
    }
    return response.data!;
  }

  Future<void> confirmPayment(int paymentId) async {
    final response = await _dioClient.postResponse<Object?>(
      '/payments/$paymentId/confirm',
    );
    if (!response.succeeded) {
      _throwFailure(
        response.message,
        response.errors,
        'Không thể xác nhận thanh toán',
      );
    }
  }

  Never _throwFailure(String? message, List<String> errors, String fallback) {
    final cleanMessage = message?.trim();
    throw Exception(
      cleanMessage?.isNotEmpty == true
          ? cleanMessage
          : (errors.isNotEmpty ? errors.first : fallback),
    );
  }
}
