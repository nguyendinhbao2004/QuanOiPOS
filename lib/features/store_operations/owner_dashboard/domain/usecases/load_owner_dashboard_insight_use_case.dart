import '../entities/owner_dashboard_insight.dart';
import '../entities/owner_dashboard_insight_type.dart';
import '../entities/owner_dashboard_period.dart';
import '../repositories/owner_dashboard_repository.dart';

class LoadOwnerDashboardInsightUseCase {
  final OwnerDashboardRepository _repository;

  const LoadOwnerDashboardInsightUseCase(this._repository);

  Future<OwnerDashboardInsight> call({
    required int storeId,
    required OwnerDashboardPeriod period,
    required OwnerDashboardInsightType type,
  }) {
    return _repository.loadSalesInsight(
      storeId: storeId,
      period: period,
      type: type,
    );
  }
}
