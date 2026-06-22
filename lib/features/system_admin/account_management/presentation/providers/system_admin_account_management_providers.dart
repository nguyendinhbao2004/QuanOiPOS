import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/di/injection.dart';
import '../../data/datasources/system_admin_account_management_remote_data_source.dart';
import '../../domain/repositories/system_admin_account_management_repository.dart';
import '../controllers/system_admin_account_management_notifier.dart';
import '../controllers/system_admin_account_management_state.dart';

final systemAdminAccountManagementRemoteDataSourceProvider =
    Provider<SystemAdminAccountManagementRemoteDataSource>(
      (ref) => locator<SystemAdminAccountManagementRemoteDataSource>(),
    );
final systemAdminAccountManagementRepositoryProvider =
    Provider<SystemAdminAccountManagementRepository>(
      (ref) => locator<SystemAdminAccountManagementRepository>(),
    );
final systemAdminAccountManagementProvider =
    NotifierProvider<
      SystemAdminAccountManagementNotifier,
      SystemAdminAccountManagementState
    >(SystemAdminAccountManagementNotifier.new);
