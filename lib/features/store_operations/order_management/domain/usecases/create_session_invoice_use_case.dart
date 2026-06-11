import '../entities/session_invoice.dart';
import '../repositories/order_management_repository.dart';

class CreateSessionInvoiceUseCase {
  final OrderManagementRepository _repository;

  const CreateSessionInvoiceUseCase(this._repository);

  Future<SessionInvoice> call({
    required int tableSessionId,
    required PaymentMethod method,
  }) {
    return _repository.createSessionInvoice(
      tableSessionId: tableSessionId,
      method: method,
    );
  }
}
