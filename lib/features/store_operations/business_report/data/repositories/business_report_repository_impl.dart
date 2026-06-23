import '../../domain/entities/business_report.dart';
import '../../domain/repositories/business_report_repository.dart';
import '../datasources/business_report_remote_data_source.dart';
import '../models/business_report_request_model.dart';

class BusinessReportRepositoryImpl implements BusinessReportRepository {
  final BusinessReportRemoteDataSource _remoteDataSource;

  const BusinessReportRepositoryImpl(this._remoteDataSource);

  @override
  Future<BusinessReport> createBusinessReport({
    required int storeId,
    required DateTime fromDate,
    required DateTime toDate,
    required int timezoneOffsetMinutes,
  }) async {
    final report = await _remoteDataSource.createBusinessReport(
      BusinessReportRequestModel(
        storeId: storeId,
        fromDate: fromDate,
        toDate: toDate,
        timezoneOffsetMinutes: timezoneOffsetMinutes,
      ),
    );

    return report.toEntity();
  }
}
