import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/di/injection.dart';
import '../../data/datasources/business_report_remote_data_source.dart';
import '../../domain/repositories/business_report_repository.dart';
import '../../domain/usecases/create_business_report_use_case.dart';
import '../controllers/business_report_notifier.dart';
import '../controllers/business_report_state.dart';

final businessReportRemoteDataSourceProvider =
    Provider<BusinessReportRemoteDataSource>((ref) {
      return locator<BusinessReportRemoteDataSource>();
    });

final businessReportRepositoryProvider = Provider<BusinessReportRepository>((
  ref,
) {
  return locator<BusinessReportRepository>();
});

final createBusinessReportUseCaseProvider =
    Provider<CreateBusinessReportUseCase>((ref) {
      return locator<CreateBusinessReportUseCase>();
    });

final businessReportNotifierProvider = NotifierProvider.autoDispose
    .family<BusinessReportNotifier, BusinessReportState, int>(
      BusinessReportNotifier.new,
    );
