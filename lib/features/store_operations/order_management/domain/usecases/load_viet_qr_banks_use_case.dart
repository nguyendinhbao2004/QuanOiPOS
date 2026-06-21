import '../entities/session_invoice.dart';
import '../repositories/order_management_repository.dart';

class LoadVietQrBanksUseCase {
  final OrderManagementRepository _repository;

  const LoadVietQrBanksUseCase(this._repository);

  Future<List<VietQrBank>> call() {
    return _repository.loadVietQrBanks();
  }
}
