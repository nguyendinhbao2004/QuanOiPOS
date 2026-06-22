import '../entities/system_admin_account.dart';
import '../repositories/system_admin_account_management_repository.dart';

class LoadSystemAdminAccountSummaryUseCase {
  final SystemAdminAccountManagementRepository _repository;
  const LoadSystemAdminAccountSummaryUseCase(this._repository);
  Future<SystemAdminAccountSummary> call() => _repository.loadSummary();
}

class LoadSystemAdminAccountsUseCase {
  final SystemAdminAccountManagementRepository _repository;
  const LoadSystemAdminAccountsUseCase(this._repository);
  Future<SystemAdminPage<SystemAdminAccount>> call(
    SystemAdminAccountQuery query, {
    required int pageIndex,
    required int pageSize,
  }) =>
      _repository.loadAccounts(query, pageIndex: pageIndex, pageSize: pageSize);
}

class LoadSystemAdminAccountUseCase {
  final SystemAdminAccountManagementRepository _repository;
  const LoadSystemAdminAccountUseCase(this._repository);
  Future<SystemAdminAccountDetail> call(int id) => _repository.loadAccount(id);
}

class UpdateSystemAdminAccountStatusUseCase {
  final SystemAdminAccountManagementRepository _repository;
  const UpdateSystemAdminAccountStatusUseCase(this._repository);
  Future<void> call(
    int id, {
    required SystemAdminAccountStatus status,
    String? reason,
  }) => _repository.updateStatus(id, status: status, reason: reason);
}

class LoadPendingRegistrationsUseCase {
  final SystemAdminAccountManagementRepository _repository;
  const LoadPendingRegistrationsUseCase(this._repository);
  Future<SystemAdminPage<PendingRegistration>> call({
    required String keyword,
    required int pageIndex,
    required int pageSize,
  }) => _repository.loadPendingRegistrations(
    keyword: keyword,
    pageIndex: pageIndex,
    pageSize: pageSize,
  );
}
