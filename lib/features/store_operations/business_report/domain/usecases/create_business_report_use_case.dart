import '../entities/business_report.dart';
import '../repositories/business_report_repository.dart';

class CreateBusinessReportUseCase {
  final BusinessReportRepository _repository;

  const CreateBusinessReportUseCase(this._repository);

  Future<BusinessReport> call({
    required int storeId,
    required DateTime fromDate,
    required DateTime toDate,
    required int timezoneOffsetMinutes,
  }) {
    return _repository.createBusinessReport(
      storeId: storeId,
      fromDate: fromDate,
      toDate: toDate,
      timezoneOffsetMinutes: timezoneOffsetMinutes,
    );
  }
}
