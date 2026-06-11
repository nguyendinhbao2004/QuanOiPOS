import '../repositories/order_management_repository.dart';

class ConfirmPaymentUseCase {
  final OrderManagementRepository _repository;

  const ConfirmPaymentUseCase(this._repository);

  Future<void> call(int paymentId) {
    return _repository.confirmPayment(paymentId);
  }
}
