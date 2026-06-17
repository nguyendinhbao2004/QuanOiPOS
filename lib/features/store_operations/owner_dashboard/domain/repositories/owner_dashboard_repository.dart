import '../entities/owner_dashboard_insight.dart';
import '../entities/owner_dashboard_insight_type.dart';
import '../entities/owner_dashboard_period.dart';

abstract class OwnerDashboardRepository {
  Future<OwnerDashboardInsight> loadSalesInsight({
    required int storeId,
    required OwnerDashboardPeriod period,
    required OwnerDashboardInsightType type,
  });
}
