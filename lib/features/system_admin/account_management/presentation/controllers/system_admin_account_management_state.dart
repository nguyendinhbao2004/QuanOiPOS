import '../../domain/entities/system_admin_account.dart';

enum SystemAdminAccountManagementStatus { initial, loading, ready, error }

class SystemAdminAccountManagementState {
  final SystemAdminAccountManagementStatus status;
  final SystemAdminAccountSummary? summary;
  final SystemAdminPage<SystemAdminAccount>? accounts;
  final SystemAdminPage<PendingRegistration>? pending;
  final SystemAdminAccountQuery query;
  final SystemAdminAccountView view;
  final String? errorMessage;
  final bool isMutating;
  const SystemAdminAccountManagementState({
    required this.status,
    required this.summary,
    required this.accounts,
    required this.pending,
    required this.query,
    required this.view,
    required this.errorMessage,
    required this.isMutating,
  });
  const SystemAdminAccountManagementState.initial()
    : status = SystemAdminAccountManagementStatus.initial,
      summary = null,
      accounts = null,
      pending = null,
      query = const SystemAdminAccountQuery(),
      view = SystemAdminAccountView.accounts,
      errorMessage = null,
      isMutating = false;
  SystemAdminAccountManagementState copyWith({
    SystemAdminAccountManagementStatus? status,
    SystemAdminAccountSummary? summary,
    SystemAdminPage<SystemAdminAccount>? accounts,
    SystemAdminPage<PendingRegistration>? pending,
    SystemAdminAccountQuery? query,
    SystemAdminAccountView? view,
    String? errorMessage,
    bool? isMutating,
    bool clearError = false,
  }) => SystemAdminAccountManagementState(
    status: status ?? this.status,
    summary: summary ?? this.summary,
    accounts: accounts ?? this.accounts,
    pending: pending ?? this.pending,
    query: query ?? this.query,
    view: view ?? this.view,
    errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    isMutating: isMutating ?? this.isMutating,
  );
}
