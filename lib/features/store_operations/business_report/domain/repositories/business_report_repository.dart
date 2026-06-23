import '../entities/business_report.dart';

abstract class BusinessReportRepository {
  Future<BusinessReport> createBusinessReport({
    required int storeId,
    required DateTime fromDate,
    required DateTime toDate,
    required int timezoneOffsetMinutes,
  });
}
