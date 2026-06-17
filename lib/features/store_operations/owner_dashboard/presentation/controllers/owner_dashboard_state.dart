import '../../domain/entities/owner_dashboard_insight.dart';
import '../../domain/entities/owner_dashboard_insight_type.dart';
import '../../domain/entities/owner_dashboard_period.dart';

enum OwnerDashboardStatus { initial, loading, ready, error }

class OwnerDashboardState {
  final OwnerDashboardStatus status;
  final OwnerDashboardPeriod period;
  final OwnerDashboardInsightType type;
  final OwnerDashboardInsight? insight;
  final String? errorMessage;

  const OwnerDashboardState({
    required this.status,
    required this.period,
    required this.type,
    required this.insight,
    required this.errorMessage,
  });

  factory OwnerDashboardState.initial() {
    return OwnerDashboardState(
      status: OwnerDashboardStatus.initial,
      period: OwnerDashboardPeriod.today(),
      type: OwnerDashboardInsightType.trend,
      insight: null,
      errorMessage: null,
    );
  }

  bool get isLoading =>
      status == OwnerDashboardStatus.initial ||
      status == OwnerDashboardStatus.loading;

  OwnerDashboardState copyWith({
    OwnerDashboardStatus? status,
    OwnerDashboardPeriod? period,
    OwnerDashboardInsightType? type,
    OwnerDashboardInsight? insight,
    bool clearInsight = false,
    String? errorMessage,
    bool clearError = false,
  }) {
    return OwnerDashboardState(
      status: status ?? this.status,
      period: period ?? this.period,
      type: type ?? this.type,
      insight: clearInsight ? null : (insight ?? this.insight),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}
