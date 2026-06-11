import '../entities/session_invoice.dart';
import '../repositories/order_management_repository.dart';

class CreateOrderInvoiceUseCase {
  final OrderManagementRepository _repository;

  const CreateOrderInvoiceUseCase(this._repository);

  Future<SessionInvoice> call({
    required int orderId,
    required PaymentMethod method,
  }) {
    return _repository.createOrderInvoice(orderId: orderId, method: method);
  }
}
