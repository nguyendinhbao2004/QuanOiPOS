import '../entities/system_admin_account.dart';

abstract class SystemAdminAccountManagementRepository {
  Future<SystemAdminAccountSummary> loadSummary();
  Future<SystemAdminPage<SystemAdminAccount>> loadAccounts(
    SystemAdminAccountQuery query, {
    required int pageIndex,
    required int pageSize,
  });
  Future<SystemAdminAccountDetail> loadAccount(int id);
  Future<void> updateStatus(
    int id, {
    required SystemAdminAccountStatus status,
    String? reason,
  });
  Future<SystemAdminPage<PendingRegistration>> loadPendingRegistrations({
    required String keyword,
    required int pageIndex,
    required int pageSize,
  });
}
