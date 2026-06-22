import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/di/injection.dart';
import '../../data/datasources/system_admin_package_management_remote_data_source.dart';
import '../../domain/repositories/system_admin_package_management_repository.dart';
import '../controllers/system_admin_package_management_notifier.dart';
import '../controllers/system_admin_package_management_state.dart';

final systemAdminPackageManagementRemoteDataSourceProvider =
    Provider<SystemAdminPackageManagementRemoteDataSource>(
      (ref) => locator<SystemAdminPackageManagementRemoteDataSource>(),
    );
final systemAdminPackageManagementRepositoryProvider =
    Provider<SystemAdminPackageManagementRepository>(
      (ref) => locator<SystemAdminPackageManagementRepository>(),
    );

final systemAdminPackageManagementProvider =
    NotifierProvider<
      SystemAdminPackageManagementNotifier,
      SystemAdminPackageManagementState
    >(SystemAdminPackageManagementNotifier.new);
