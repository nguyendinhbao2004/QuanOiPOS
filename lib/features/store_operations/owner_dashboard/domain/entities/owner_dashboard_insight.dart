import 'owner_dashboard_insight_type.dart';
import 'owner_dashboard_metrics.dart';

class OwnerDashboardInsight {
  final int id;
  final int storeId;
  final OwnerDashboardInsightType type;
  final DateTime fromDate;
  final DateTime toDate;
  final String content;
  final OwnerDashboardMetrics metrics;
  final DateTime? createdAt;

  const OwnerDashboardInsight({
    required this.id,
    required this.storeId,
    required this.type,
    required this.fromDate,
    required this.toDate,
    required this.content,
    required this.metrics,
    required this.createdAt,
  });
}
