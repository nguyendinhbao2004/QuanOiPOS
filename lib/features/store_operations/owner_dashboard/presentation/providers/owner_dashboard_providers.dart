import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/di/injection.dart';
import '../../data/datasources/owner_dashboard_remote_data_source.dart';
import '../../domain/repositories/owner_dashboard_repository.dart';
import '../../domain/usecases/load_owner_dashboard_insight_use_case.dart';
import '../controllers/owner_dashboard_notifier.dart';
import '../controllers/owner_dashboard_state.dart';

final ownerDashboardRemoteDataSourceProvider =
    Provider<OwnerDashboardRemoteDataSource>((ref) {
      return locator<OwnerDashboardRemoteDataSource>();
    });

final ownerDashboardRepositoryProvider = Provider<OwnerDashboardRepository>((
  ref,
) {
  return locator<OwnerDashboardRepository>();
});

final loadOwnerDashboardInsightUseCaseProvider =
    Provider<LoadOwnerDashboardInsightUseCase>((ref) {
      return locator<LoadOwnerDashboardInsightUseCase>();
    });

final ownerDashboardNotifierProvider = NotifierProvider.autoDispose
    .family<OwnerDashboardNotifier, OwnerDashboardState, int>(
      OwnerDashboardNotifier.new,
    );
