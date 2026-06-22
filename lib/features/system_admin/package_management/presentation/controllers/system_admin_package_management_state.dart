import '../../domain/entities/system_admin_subscription_plan.dart';

enum SystemAdminPackageManagementStatus { initial, loading, ready, error }

class SystemAdminPackageManagementState {
  final SystemAdminPackageManagementStatus status;
  final SystemAdminPlanSummary? summary;
  final SystemAdminPlanPage? page;
  final SystemAdminPlanStatus filter;
  final double? monthlyRevenue;
  final String? errorMessage;
  final bool isMutating;

  const SystemAdminPackageManagementState({
    required this.status,
    required this.summary,
    required this.page,
    required this.filter,
    required this.monthlyRevenue,
    required this.errorMessage,
    required this.isMutating,
  });

  const SystemAdminPackageManagementState.initial()
    : status = SystemAdminPackageManagementStatus.initial,
      summary = null,
      page = null,
      filter = SystemAdminPlanStatus.all,
      monthlyRevenue = null,
      errorMessage = null,
      isMutating = false;

  SystemAdminPackageManagementState copyWith({
    SystemAdminPackageManagementStatus? status,
    SystemAdminPlanSummary? summary,
    SystemAdminPlanPage? page,
    SystemAdminPlanStatus? filter,
    double? monthlyRevenue,
    String? errorMessage,
    bool? isMutating,
    bool clearError = false,
  }) => SystemAdminPackageManagementState(
    status: status ?? this.status,
    summary: summary ?? this.summary,
    page: page ?? this.page,
    filter: filter ?? this.filter,
    monthlyRevenue: monthlyRevenue ?? this.monthlyRevenue,
    errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    isMutating: isMutating ?? this.isMutating,
  );
}
