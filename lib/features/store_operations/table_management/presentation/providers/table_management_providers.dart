import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/di/injection.dart';
import '../../data/datasources/table_management_remote_data_source.dart';
import '../../domain/repositories/table_management_repository.dart';
import '../../domain/usecases/load_areas_use_case.dart';
import '../../domain/usecases/load_table_groups_use_case.dart';
import '../controllers/table_management_notifier.dart';
import '../controllers/table_management_state.dart';

final tableManagementRemoteDataSourceProvider =
    Provider<TableManagementRemoteDataSource>((ref) {
      return locator<TableManagementRemoteDataSource>();
    });

final tableManagementRepositoryProvider = Provider<TableManagementRepository>((
  ref,
) {
  return locator<TableManagementRepository>();
});

final loadAreasUseCaseProvider = Provider<LoadAreasUseCase>((ref) {
  return locator<LoadAreasUseCase>();
});

final loadTableGroupsUseCaseProvider = Provider<LoadTableGroupsUseCase>((ref) {
  return locator<LoadTableGroupsUseCase>();
});

final tableManagementNotifierProvider = NotifierProvider.autoDispose
    .family<
      TableManagementNotifier,
      TableManagementState,
      TableManagementAccess
    >(TableManagementNotifier.new);
