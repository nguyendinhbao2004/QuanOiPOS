import '../../domain/entities/owner_dashboard_insight_type.dart';
import '../../domain/entities/owner_dashboard_period.dart';

class OwnerDashboardRequestModel {
  final int storeId;
  final DateTime fromDate;
  final DateTime toDate;
  final OwnerDashboardInsightType type;

  const OwnerDashboardRequestModel({
    required this.storeId,
    required this.fromDate,
    required this.toDate,
    required this.type,
  });

  factory OwnerDashboardRequestModel.fromPeriod({
    required int storeId,
    required OwnerDashboardPeriod period,
    required OwnerDashboardInsightType type,
  }) {
    return OwnerDashboardRequestModel(
      storeId: storeId,
      fromDate: period.fromDate,
      toDate: period.toDate,
      type: type,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'storeId': storeId,
      'fromDate': fromDate.toUtc().toIso8601String(),
      'toDate': toDate.toUtc().toIso8601String(),
      'type': type.apiValue,
    };
  }
}
