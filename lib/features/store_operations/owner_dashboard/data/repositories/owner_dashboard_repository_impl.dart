import '../../domain/entities/owner_dashboard_insight.dart';
import '../../domain/entities/owner_dashboard_insight_type.dart';
import '../../domain/entities/owner_dashboard_period.dart';
import '../../domain/repositories/owner_dashboard_repository.dart';
import '../datasources/owner_dashboard_remote_data_source.dart';
import '../models/owner_dashboard_request_model.dart';

class OwnerDashboardRepositoryImpl implements OwnerDashboardRepository {
  final OwnerDashboardRemoteDataSource _remoteDataSource;

  const OwnerDashboardRepositoryImpl(this._remoteDataSource);

  @override
  Future<OwnerDashboardInsight> loadSalesInsight({
    required int storeId,
    required OwnerDashboardPeriod period,
    required OwnerDashboardInsightType type,
  }) async {
    final insight = await _remoteDataSource.createSalesInsight(
      OwnerDashboardRequestModel.fromPeriod(
        storeId: storeId,
        period: period,
        type: type,
      ),
    );

    return insight.toEntity();
  }
}
