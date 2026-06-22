import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/di/injection.dart';
import '../../domain/entities/system_admin_account.dart';
import '../../domain/usecases/system_admin_account_management_use_cases.dart';
import 'system_admin_account_management_state.dart';

class SystemAdminAccountManagementNotifier
    extends Notifier<SystemAdminAccountManagementState> {
  static const _size = 20;
  bool _started = false;
  @override
  SystemAdminAccountManagementState build() {
    if (!_started) {
      _started = true;
      Future.microtask(load);
    }
    return const SystemAdminAccountManagementState.initial();
  }

  Future<void> load({int? pageIndex}) async {
    final hasData = state.summary != null;
    state = state.copyWith(
      status: SystemAdminAccountManagementStatus.loading,
      isMutating: false,
      clearError: true,
    );
    final page =
        pageIndex ??
        (state.view == SystemAdminAccountView.accounts
            ? state.accounts?.pageIndex
            : state.pending?.pageIndex) ??
        1;
    try {
      final summaryFuture = locator<LoadSystemAdminAccountSummaryUseCase>()();
      if (state.view == SystemAdminAccountView.accounts) {
        final results = await Future.wait<Object>([
          summaryFuture,
          locator<LoadSystemAdminAccountsUseCase>()(
            state.query,
            pageIndex: page,
            pageSize: _size,
          ),
        ]);
        state = state.copyWith(
          status: SystemAdminAccountManagementStatus.ready,
          summary: results[0] as SystemAdminAccountSummary,
          accounts: results[1] as SystemAdminPage<SystemAdminAccount>,
          clearError: true,
        );
      } else {
        final results = await Future.wait<Object>([
          summaryFuture,
          locator<LoadPendingRegistrationsUseCase>()(
            keyword: state.query.keyword,
            pageIndex: page,
            pageSize: _size,
          ),
        ]);
        state = state.copyWith(
          status: SystemAdminAccountManagementStatus.ready,
          summary: results[0] as SystemAdminAccountSummary,
          pending: results[1] as SystemAdminPage<PendingRegistration>,
          clearError: true,
        );
      }
    } catch (e) {
      state = state.copyWith(
        status: hasData
            ? SystemAdminAccountManagementStatus.ready
            : SystemAdminAccountManagementStatus.error,
        errorMessage: _error(e),
      );
    }
  }

  Future<void> openAccounts({
    SystemAdminAccountType type = SystemAdminAccountType.all,
    SystemAdminAccountStatus status = SystemAdminAccountStatus.all,
  }) async {
    state = state.copyWith(
      view: SystemAdminAccountView.accounts,
      query: state.query.copyWith(accountType: type, status: status),
    );
    await load(pageIndex: 1);
  }

  Future<void> openPending() async {
    state = state.copyWith(view: SystemAdminAccountView.pendingRegistrations);
    await load(pageIndex: 1);
  }

  Future<void> updateQuery(SystemAdminAccountQuery query) async {
    state = state.copyWith(query: query);
    await load(pageIndex: 1);
  }

  Future<void> previousPage() async {
    final page = state.view == SystemAdminAccountView.accounts
        ? state.accounts
        : state.pending;
    if (page != null && page.pageIndex > 1) {
      await load(pageIndex: page.pageIndex - 1);
    }
  }

  Future<void> nextPage() async {
    final page = state.view == SystemAdminAccountView.accounts
        ? state.accounts
        : state.pending;
    if (page != null && page.pageIndex < page.totalPages) {
      await load(pageIndex: page.pageIndex + 1);
    }
  }

  Future<SystemAdminAccountDetail> loadDetail(int id) =>
      locator<LoadSystemAdminAccountUseCase>()(id);
  Future<void> updateStatus(
    int id, {
    required SystemAdminAccountStatus status,
    String? reason,
  }) async {
    state = state.copyWith(isMutating: true, clearError: true);
    try {
      await locator<UpdateSystemAdminAccountStatusUseCase>()(
        id,
        status: status,
        reason: reason,
      );
      await load();
    } catch (e) {
      state = state.copyWith(isMutating: false, errorMessage: _error(e));
      rethrow;
    }
  }

  String _error(Object e) => e.toString().replaceFirst('Exception: ', '');
}
