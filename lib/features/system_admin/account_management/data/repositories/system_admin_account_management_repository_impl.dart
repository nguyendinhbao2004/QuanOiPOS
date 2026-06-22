import '../../domain/entities/system_admin_account.dart';
import '../../domain/repositories/system_admin_account_management_repository.dart';
import '../datasources/system_admin_account_management_remote_data_source.dart';

class SystemAdminAccountManagementRepositoryImpl
    implements SystemAdminAccountManagementRepository {
  final SystemAdminAccountManagementRemoteDataSource _remote;
  const SystemAdminAccountManagementRepositoryImpl(this._remote);
  @override
  Future<SystemAdminAccountSummary> loadSummary() async =>
      (await _remote.loadSummary()).value;
  @override
  Future<SystemAdminPage<SystemAdminAccount>> loadAccounts(
    SystemAdminAccountQuery q, {
    required int pageIndex,
    required int pageSize,
  }) async {
    final p = await _remote.loadAccounts(_accountQuery(q, pageIndex, pageSize));
    return SystemAdminPage(
      items: p.value.items.map((x) => x.value).toList(),
      pageIndex: p.value.pageIndex,
      pageSize: p.value.pageSize,
      totalItems: p.value.totalItems,
      totalPages: p.value.totalPages,
    );
  }

  @override
  Future<SystemAdminAccountDetail> loadAccount(int id) async =>
      (await _remote.loadAccount(id)).value;
  @override
  Future<void> updateStatus(
    int id, {
    required SystemAdminAccountStatus status,
    String? reason,
  }) => _remote.updateStatus(id, {
    'status': status == SystemAdminAccountStatus.suspended
        ? 'Suspended'
        : 'Active',
    if (reason != null && reason.trim().isNotEmpty) 'reason': reason.trim(),
  });
  @override
  Future<SystemAdminPage<PendingRegistration>> loadPendingRegistrations({
    required String keyword,
    required int pageIndex,
    required int pageSize,
  }) async {
    final p = await _remote.loadPending({
      'keyword': keyword,
      'sortBy': 'createdAt',
      'sortDirection': 'desc',
      'pageIndex': pageIndex,
      'pageSize': pageSize,
    });
    return SystemAdminPage(
      items: p.value.items.map((x) => x.value).toList(),
      pageIndex: p.value.pageIndex,
      pageSize: p.value.pageSize,
      totalItems: p.value.totalItems,
      totalPages: p.value.totalPages,
    );
  }

  Map<String, dynamic> _accountQuery(
    SystemAdminAccountQuery q,
    int page,
    int size,
  ) => {
    'keyword': q.keyword,
    if (q.accountType != SystemAdminAccountType.all)
      'accountType': q.accountType == SystemAdminAccountType.systemAdmin
          ? 'SystemAdmin'
          : 'StoreUser',
    if (q.status != SystemAdminAccountStatus.all) 'status': _status(q.status),
    if (q.createdFrom != null) 'createdFrom': _day(q.createdFrom!),
    if (q.createdTo != null) 'createdTo': _day(q.createdTo!),
    if (q.lastLoginFrom != null) 'lastLoginFrom': _day(q.lastLoginFrom!),
    if (q.lastLoginTo != null) 'lastLoginTo': _day(q.lastLoginTo!),
    'sortBy': q.sort.name,
    'sortDirection': q.direction.name,
    'pageIndex': page,
    'pageSize': size,
  };
  String _status(SystemAdminAccountStatus s) =>
      s == SystemAdminAccountStatus.active
      ? 'Active'
      : s == SystemAdminAccountStatus.inactive
      ? 'Inactive'
      : 'Suspended';
  String _day(DateTime d) =>
      '${d.toUtc().year.toString().padLeft(4, '0')}-${d.toUtc().month.toString().padLeft(2, '0')}-${d.toUtc().day.toString().padLeft(2, '0')}';
}
