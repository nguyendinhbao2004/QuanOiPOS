import 'package:get_it/get_it.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:logger/logger.dart';
import '../storage/token_storage.dart';
import '../storage/token_storage_impl.dart';
import '../storage/session_snapshot_storage.dart';
import '../storage/session_snapshot_storage_impl.dart';
import '../storage/last_active_store_storage.dart';
import '../storage/last_active_store_storage_impl.dart';
import '../network/dio/dio_factory.dart';
import '../network/dio/dio_client.dart';
import '../realtime/realtime_notification_service.dart';
import '../realtime/signalr_realtime_notification_service.dart';
import '../session/session_invalidator.dart';
import 'package:dio/dio.dart';
import '../../features/auth/data/datasources/auth_remote_data_source.dart';
import '../../features/auth/data/repositories/auth_repository_impl.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/auth/domain/usecases/change_password_use_case.dart';
import '../../features/auth/domain/usecases/login_use_case.dart';
import '../../features/auth/domain/usecases/load_current_user_profile_use_case.dart';
import '../../features/auth/domain/usecases/logout_use_case.dart';
import '../../features/auth/domain/usecases/restore_session_use_case.dart';
import '../../features/auth/domain/usecases/register_use_case.dart';
import '../../features/auth/domain/usecases/update_current_user_profile_use_case.dart';
import '../../features/auth/domain/usecases/confirm_registration_use_case.dart';
import '../../features/auth/domain/usecases/forgot_password_use_case.dart';
import '../../features/auth/domain/usecases/confirm_forgot_password_use_case.dart';
import '../../features/subscription/data/datasources/subscription_remote_data_source.dart';
import '../../features/subscription/data/datasources/subscription_pending_purchase_storage.dart';
import '../../features/subscription/data/datasources/subscription_pending_purchase_storage_impl.dart';
import '../../features/subscription/data/repositories/subscription_repository_impl.dart';
import '../../features/subscription/domain/repositories/subscription_repository.dart';
import '../../features/subscription/domain/usecases/cancel_pending_subscription_purchase_use_case.dart';
import '../../features/subscription/domain/usecases/clear_pending_subscription_purchase_use_case.dart';
import '../../features/subscription/domain/usecases/load_active_subscription_use_case.dart';
import '../../features/subscription/domain/usecases/load_pending_subscription_purchase_use_case.dart';
import '../../features/subscription/domain/usecases/load_subscription_plans_use_case.dart';
import '../../features/subscription/domain/usecases/purchase_subscription_use_case.dart';
import '../../features/system_admin/data/datasources/system_admin_dashboard_remote_data_source.dart';
import '../../features/system_admin/data/repositories/system_admin_dashboard_repository_impl.dart';
import '../../features/system_admin/domain/repositories/system_admin_dashboard_repository.dart';
import '../../features/system_admin/domain/usecases/load_system_admin_dashboard_blocks_use_cases.dart';
import '../../features/system_admin/account_management/data/datasources/system_admin_account_management_remote_data_source.dart';
import '../../features/system_admin/account_management/data/repositories/system_admin_account_management_repository_impl.dart';
import '../../features/system_admin/account_management/domain/repositories/system_admin_account_management_repository.dart';
import '../../features/system_admin/account_management/domain/usecases/system_admin_account_management_use_cases.dart';
import '../../features/system_admin/package_management/data/datasources/system_admin_package_management_remote_data_source.dart';
import '../../features/system_admin/package_management/data/repositories/system_admin_package_management_repository_impl.dart';
import '../../features/system_admin/package_management/domain/repositories/system_admin_package_management_repository.dart';
import '../../features/system_admin/package_management/domain/usecases/system_admin_package_management_use_cases.dart';
import '../../features/store_operations/table_management/data/datasources/table_management_remote_data_source.dart';
import '../../features/store_operations/table_management/data/repositories/table_management_repository_impl.dart';
import '../../features/store_operations/table_management/domain/repositories/table_management_repository.dart';
import '../../features/store_operations/table_management/domain/usecases/create_area_use_case.dart';
import '../../features/store_operations/table_management/domain/usecases/create_table_use_case.dart';
import '../../features/store_operations/table_management/domain/usecases/close_table_session_use_case.dart';
import '../../features/store_operations/table_management/domain/usecases/delete_area_use_case.dart';
import '../../features/store_operations/table_management/domain/usecases/load_area_detail_use_case.dart';
import '../../features/store_operations/table_management/domain/usecases/load_areas_use_case.dart';
import '../../features/store_operations/table_management/domain/usecases/load_table_detail_use_case.dart';
import '../../features/store_operations/table_management/domain/usecases/load_table_groups_use_case.dart';
import '../../features/store_operations/table_management/domain/usecases/load_open_table_sessions_use_case.dart';
import '../../features/store_operations/table_management/domain/usecases/load_table_sessions_use_case.dart';
import '../../features/store_operations/table_management/domain/usecases/open_table_session_use_case.dart';
import '../../features/store_operations/table_management/domain/usecases/update_area_display_order_use_case.dart';
import '../../features/store_operations/table_management/domain/usecases/update_area_use_case.dart';
import '../../features/store_operations/table_management/domain/usecases/update_table_status_use_case.dart';
import '../../features/store_operations/table_management/domain/usecases/update_table_use_case.dart';
import '../../features/store_operations/order_management/data/datasources/order_management_remote_data_source.dart';
import '../../features/store_operations/order_management/data/datasources/viet_qr_remote_data_source.dart';
import '../../features/store_operations/order_management/data/repositories/order_management_repository_impl.dart';
import '../../features/store_operations/order_management/domain/repositories/order_management_repository.dart';
import '../../features/store_operations/order_management/domain/usecases/create_order_use_case.dart';
import '../../features/store_operations/order_management/domain/usecases/create_order_invoice_use_case.dart';
import '../../features/store_operations/order_management/domain/usecases/create_session_invoice_use_case.dart';
import '../../features/store_operations/order_management/domain/usecases/confirm_payment_use_case.dart';
import '../../features/store_operations/order_management/domain/usecases/load_order_detail_use_case.dart';
import '../../features/store_operations/order_management/domain/usecases/load_orders_by_table_session_use_case.dart';
import '../../features/store_operations/order_management/domain/usecases/load_viet_qr_banks_use_case.dart';
import '../../features/store_operations/owner_dashboard/data/datasources/owner_dashboard_remote_data_source.dart';
import '../../features/store_operations/owner_dashboard/data/repositories/owner_dashboard_repository_impl.dart';
import '../../features/store_operations/owner_dashboard/domain/repositories/owner_dashboard_repository.dart';
import '../../features/store_operations/owner_dashboard/domain/usecases/load_owner_dashboard_insight_use_case.dart';
import '../../features/store_operations/product_management/data/datasources/product_management_remote_data_source.dart';
import '../../features/store_operations/product_management/data/repositories/product_management_repository_impl.dart';
import '../../features/store_operations/product_management/domain/repositories/product_management_repository.dart';
import '../../features/store_operations/product_management/domain/usecases/create_product_category_use_case.dart';
import '../../features/store_operations/product_management/domain/usecases/create_product_ingredient_use_case.dart';
import '../../features/store_operations/product_management/domain/usecases/create_product_topping_use_case.dart';
import '../../features/store_operations/product_management/domain/usecases/create_product_use_case.dart';
import '../../features/store_operations/product_management/domain/usecases/delete_product_category_use_case.dart';
import '../../features/store_operations/product_management/domain/usecases/delete_product_ingredient_use_case.dart';
import '../../features/store_operations/product_management/domain/usecases/delete_product_topping_use_case.dart';
import '../../features/store_operations/product_management/domain/usecases/delete_product_use_case.dart';
import '../../features/store_operations/product_management/domain/usecases/load_product_categories_use_case.dart';
import '../../features/store_operations/product_management/domain/usecases/load_product_detail_use_case.dart';
import '../../features/store_operations/product_management/domain/usecases/load_product_ingredients_use_case.dart';
import '../../features/store_operations/product_management/domain/usecases/load_ingredient_inventory_settings_use_case.dart';
import '../../features/store_operations/product_management/domain/usecases/load_product_inventory_settings_use_case.dart';
import '../../features/store_operations/product_management/domain/usecases/load_product_recipes_use_case.dart';
import '../../features/store_operations/product_management/domain/usecases/load_product_toppings_use_case.dart';
import '../../features/store_operations/product_management/domain/usecases/load_products_use_case.dart';
import '../../features/store_operations/product_management/domain/usecases/replace_product_recipe_use_case.dart';
import '../../features/store_operations/product_management/domain/usecases/update_ingredient_inventory_settings_use_case.dart';
import '../../features/store_operations/product_management/domain/usecases/update_product_category_use_case.dart';
import '../../features/store_operations/product_management/domain/usecases/update_product_inventory_settings_use_case.dart';
import '../../features/store_operations/product_management/domain/usecases/update_product_ingredient_use_case.dart';
import '../../features/store_operations/product_management/domain/usecases/update_product_sell_status_use_case.dart';
import '../../features/store_operations/product_management/domain/usecases/update_product_topping_use_case.dart';
import '../../features/store_operations/product_management/domain/usecases/update_product_use_case.dart';
import '../../features/store_operations/inventory_documents/data/datasources/inventory_document_remote_data_source.dart';
import '../../features/store_operations/inventory_documents/data/repositories/inventory_document_repository_impl.dart';
import '../../features/store_operations/inventory_documents/domain/repositories/inventory_document_repository.dart';
import '../../features/store_operations/inventory_documents/domain/usecases/inventory_document_use_cases.dart';
import '../../features/store_operations/staff_management/data/datasources/staff_management_remote_data_source.dart';
import '../../features/store_operations/staff_management/data/repositories/staff_management_repository_impl.dart';
import '../../features/store_operations/staff_management/domain/repositories/staff_management_repository.dart';
import '../../features/store_operations/staff_management/domain/usecases/cancel_staff_invitation_use_case.dart';
import '../../features/store_operations/staff_management/domain/usecases/create_staff_role_use_case.dart';
import '../../features/store_operations/staff_management/domain/usecases/delete_staff_role_use_case.dart';
import '../../features/store_operations/staff_management/domain/usecases/invite_staff_use_case.dart';
import '../../features/store_operations/staff_management/domain/usecases/load_staff_members_use_case.dart';
import '../../features/store_operations/staff_management/domain/usecases/load_staff_permission_groups_use_case.dart';
import '../../features/store_operations/staff_management/domain/usecases/load_staff_roles_use_case.dart';
import '../../features/store_operations/staff_management/domain/usecases/remove_staff_use_case.dart';
import '../../features/store_operations/staff_management/domain/usecases/update_staff_access_use_case.dart';
import '../../features/store_operations/staff_management/domain/usecases/update_staff_display_name_use_case.dart';
import '../../features/store_operations/staff_management/domain/usecases/update_staff_role_use_case.dart';
import '../../features/store_operations/voice_order/data/datasources/voice_order_remote_data_source.dart';
import '../../features/store_operations/voice_order/data/repositories/voice_order_repository_impl.dart';
import '../../features/store_operations/voice_order/domain/repositories/voice_order_repository.dart';
import '../../features/store_operations/voice_order/domain/usecases/recognize_voice_order_use_case.dart';
import '../../features/workspace_context/data/datasources/store_access_context_cache_storage.dart';
import '../../features/workspace_context/data/datasources/store_access_context_cache_storage_impl.dart';
import '../../features/workspace_context/data/datasources/workspace_remote_data_source.dart';
import '../../features/workspace_context/data/repositories/workspace_repository_impl.dart';
import '../../features/workspace_context/domain/repositories/workspace_repository.dart';
import '../../features/workspace_context/domain/usecases/clear_all_store_access_context_cache_use_case.dart';
import '../../features/workspace_context/domain/usecases/clear_last_active_store_use_case.dart';
import '../../features/workspace_context/domain/usecases/clear_store_access_context_cache_use_case.dart';
import '../../features/workspace_context/domain/usecases/create_store_use_case.dart';
import '../../features/workspace_context/domain/usecases/load_cached_store_access_context_use_case.dart';
import '../../features/workspace_context/domain/usecases/load_last_active_store_use_case.dart';
import '../../features/workspace_context/domain/usecases/load_my_stores_use_case.dart';
import '../../features/workspace_context/domain/usecases/load_store_access_context_use_case.dart';
import '../../features/workspace_context/domain/usecases/save_last_active_store_use_case.dart';
import '../../features/workspace_context/domain/usecases/save_store_access_context_cache_use_case.dart';

final GetIt locator = GetIt.instance;

Future<void> setupDependencies({bool enableLogging = false}) async {
  // Secure storage
  locator.registerLazySingleton<FlutterSecureStorage>(
    () => const FlutterSecureStorage(),
  );

  // Token storage
  locator.registerLazySingleton<TokenStorage>(
    () => TokenStorageImpl(locator<FlutterSecureStorage>()),
  );

  // Session snapshot storage
  final prefs = await SharedPreferences.getInstance();
  locator.registerLazySingleton<SharedPreferences>(() => prefs);
  locator.registerLazySingleton<SessionSnapshotStorage>(
    () => SessionSnapshotStorageImpl(locator<SharedPreferences>()),
  );
  locator.registerLazySingleton<LastActiveStoreStorage>(
    () => LastActiveStoreStorageImpl(locator<SharedPreferences>()),
  );

  // Logger
  locator.registerLazySingleton<Logger>(() => Logger());

  // Session invalidation
  locator.registerLazySingleton<SessionInvalidator>(
    SessionInvalidator.new,
    dispose: (sessionInvalidator) => sessionInvalidator.dispose(),
  );

  // Realtime notifications
  locator.registerLazySingleton<RealtimeNotificationService>(
    () => SignalRRealtimeNotificationService(
      tokenStorage: locator<TokenStorage>(),
      logger: locator<Logger>(),
    ),
    dispose: (service) async {
      if (service is SignalRRealtimeNotificationService) {
        await service.dispose();
      } else {
        await service.stop();
      }
    },
  );

  // Dio
  final dio = DioFactory.createDio(
    tokenStorage: locator<TokenStorage>(),
    sessionInvalidator: locator<SessionInvalidator>(),
    logger: locator<Logger>(),
    enableLogging: enableLogging,
    onAccessTokenRefreshed: () =>
        locator<RealtimeNotificationService>().restart(),
  );

  locator.registerLazySingleton<Dio>(() => dio);
  locator.registerLazySingleton<DioClient>(() => DioClient(locator<Dio>()));

  // Auth
  locator.registerLazySingleton<AuthRemoteDataSource>(
    () => AuthRemoteDataSource(locator<DioClient>()),
  );
  locator.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(
      locator<AuthRemoteDataSource>(),
      locator<TokenStorage>(),
      locator<SessionSnapshotStorage>(),
    ),
  );
  locator.registerLazySingleton<LoginUseCase>(
    () => LoginUseCase(locator<AuthRepository>()),
  );
  locator.registerLazySingleton<LogoutUseCase>(
    () => LogoutUseCase(locator<AuthRepository>()),
  );
  locator.registerLazySingleton<RestoreSessionUseCase>(
    () => RestoreSessionUseCase(locator<AuthRepository>()),
  );
  locator.registerLazySingleton<RegisterUseCase>(
    () => RegisterUseCase(locator<AuthRepository>()),
  );
  locator.registerLazySingleton<ConfirmRegistrationUseCase>(
    () => ConfirmRegistrationUseCase(locator<AuthRepository>()),
  );
  locator.registerLazySingleton<ForgotPasswordUseCase>(
    () => ForgotPasswordUseCase(locator<AuthRepository>()),
  );
  locator.registerLazySingleton<ConfirmForgotPasswordUseCase>(
    () => ConfirmForgotPasswordUseCase(locator<AuthRepository>()),
  );
  locator.registerLazySingleton<ChangePasswordUseCase>(
    () => ChangePasswordUseCase(locator<AuthRepository>()),
  );
  locator.registerLazySingleton<LoadCurrentUserProfileUseCase>(
    () => LoadCurrentUserProfileUseCase(locator<AuthRepository>()),
  );
  locator.registerLazySingleton<UpdateCurrentUserProfileUseCase>(
    () => UpdateCurrentUserProfileUseCase(locator<AuthRepository>()),
  );

  // Subscription
  locator.registerLazySingleton<SubscriptionRemoteDataSource>(
    () => SubscriptionRemoteDataSource(locator<DioClient>()),
  );
  locator.registerLazySingleton<SubscriptionPendingPurchaseStorage>(
    () => SubscriptionPendingPurchaseStorageImpl(locator<SharedPreferences>()),
  );
  locator.registerLazySingleton<SubscriptionRepository>(
    () => SubscriptionRepositoryImpl(
      locator<SubscriptionRemoteDataSource>(),
      locator<SubscriptionPendingPurchaseStorage>(),
      locator<SessionSnapshotStorage>(),
    ),
  );
  locator.registerLazySingleton<LoadSubscriptionPlansUseCase>(
    () => LoadSubscriptionPlansUseCase(locator<SubscriptionRepository>()),
  );
  locator.registerLazySingleton<LoadActiveSubscriptionUseCase>(
    () => LoadActiveSubscriptionUseCase(locator<SubscriptionRepository>()),
  );
  locator.registerLazySingleton<PurchaseSubscriptionUseCase>(
    () => PurchaseSubscriptionUseCase(locator<SubscriptionRepository>()),
  );
  locator.registerLazySingleton<LoadPendingSubscriptionPurchaseUseCase>(
    () => LoadPendingSubscriptionPurchaseUseCase(
      locator<SubscriptionRepository>(),
    ),
  );
  locator.registerLazySingleton<ClearPendingSubscriptionPurchaseUseCase>(
    () => ClearPendingSubscriptionPurchaseUseCase(
      locator<SubscriptionRepository>(),
    ),
  );
  locator.registerLazySingleton<CancelPendingSubscriptionPurchaseUseCase>(
    () => CancelPendingSubscriptionPurchaseUseCase(
      locator<SubscriptionRepository>(),
    ),
  );

  // System admin dashboard
  locator.registerLazySingleton<SystemAdminDashboardRemoteDataSource>(
    () => SystemAdminDashboardRemoteDataSource(locator<DioClient>()),
  );
  locator.registerLazySingleton<SystemAdminDashboardRepository>(
    () => SystemAdminDashboardRepositoryImpl(
      locator<SystemAdminDashboardRemoteDataSource>(),
    ),
  );
  locator.registerLazySingleton<LoadSystemAdminDashboardOverviewUseCase>(
    () => LoadSystemAdminDashboardOverviewUseCase(
      locator<SystemAdminDashboardRepository>(),
    ),
  );
  locator.registerLazySingleton<LoadSystemAdminRevenueSeriesUseCase>(
    () => LoadSystemAdminRevenueSeriesUseCase(
      locator<SystemAdminDashboardRepository>(),
    ),
  );
  locator.registerLazySingleton<LoadSystemAdminRevenueByPlanUseCase>(
    () => LoadSystemAdminRevenueByPlanUseCase(
      locator<SystemAdminDashboardRepository>(),
    ),
  );
  locator.registerLazySingleton<LoadSystemAdminAccountGrowthUseCase>(
    () => LoadSystemAdminAccountGrowthUseCase(
      locator<SystemAdminDashboardRepository>(),
    ),
  );
  locator.registerLazySingleton<LoadSystemAdminDistributionUseCase>(
    () => LoadSystemAdminDistributionUseCase(
      locator<SystemAdminDashboardRepository>(),
    ),
  );
  locator.registerLazySingleton<LoadSystemAdminPaymentsUseCase>(
    () => LoadSystemAdminPaymentsUseCase(
      locator<SystemAdminDashboardRepository>(),
    ),
  );

  // System admin package management
  locator.registerLazySingleton<SystemAdminPackageManagementRemoteDataSource>(
    () => SystemAdminPackageManagementRemoteDataSource(locator<DioClient>()),
  );
  locator.registerLazySingleton<SystemAdminPackageManagementRepository>(
    () => SystemAdminPackageManagementRepositoryImpl(
      locator<SystemAdminPackageManagementRemoteDataSource>(),
    ),
  );
  locator.registerLazySingleton<LoadSystemAdminPlanSummaryUseCase>(
    () => LoadSystemAdminPlanSummaryUseCase(
      locator<SystemAdminPackageManagementRepository>(),
    ),
  );
  locator.registerLazySingleton<LoadSystemAdminPlansUseCase>(
    () => LoadSystemAdminPlansUseCase(
      locator<SystemAdminPackageManagementRepository>(),
    ),
  );
  locator.registerLazySingleton<LoadSystemAdminPlanUseCase>(
    () => LoadSystemAdminPlanUseCase(
      locator<SystemAdminPackageManagementRepository>(),
    ),
  );
  locator.registerLazySingleton<CreateSystemAdminPlanUseCase>(
    () => CreateSystemAdminPlanUseCase(
      locator<SystemAdminPackageManagementRepository>(),
    ),
  );
  locator.registerLazySingleton<UpdateSystemAdminPlanUseCase>(
    () => UpdateSystemAdminPlanUseCase(
      locator<SystemAdminPackageManagementRepository>(),
    ),
  );
  locator.registerLazySingleton<ActivateSystemAdminPlanUseCase>(
    () => ActivateSystemAdminPlanUseCase(
      locator<SystemAdminPackageManagementRepository>(),
    ),
  );
  locator.registerLazySingleton<DeactivateSystemAdminPlanUseCase>(
    () => DeactivateSystemAdminPlanUseCase(
      locator<SystemAdminPackageManagementRepository>(),
    ),
  );
  locator.registerLazySingleton<DeleteSystemAdminPlanUseCase>(
    () => DeleteSystemAdminPlanUseCase(
      locator<SystemAdminPackageManagementRepository>(),
    ),
  );

  // System admin account management
  locator.registerLazySingleton<SystemAdminAccountManagementRemoteDataSource>(
    () => SystemAdminAccountManagementRemoteDataSource(locator<DioClient>()),
  );
  locator.registerLazySingleton<SystemAdminAccountManagementRepository>(
    () => SystemAdminAccountManagementRepositoryImpl(
      locator<SystemAdminAccountManagementRemoteDataSource>(),
    ),
  );
  locator.registerLazySingleton<LoadSystemAdminAccountSummaryUseCase>(
    () => LoadSystemAdminAccountSummaryUseCase(
      locator<SystemAdminAccountManagementRepository>(),
    ),
  );
  locator.registerLazySingleton<LoadSystemAdminAccountsUseCase>(
    () => LoadSystemAdminAccountsUseCase(
      locator<SystemAdminAccountManagementRepository>(),
    ),
  );
  locator.registerLazySingleton<LoadSystemAdminAccountUseCase>(
    () => LoadSystemAdminAccountUseCase(
      locator<SystemAdminAccountManagementRepository>(),
    ),
  );
  locator.registerLazySingleton<UpdateSystemAdminAccountStatusUseCase>(
    () => UpdateSystemAdminAccountStatusUseCase(
      locator<SystemAdminAccountManagementRepository>(),
    ),
  );
  locator.registerLazySingleton<LoadPendingRegistrationsUseCase>(
    () => LoadPendingRegistrationsUseCase(
      locator<SystemAdminAccountManagementRepository>(),
    ),
  );

  // Workspace context
  locator.registerLazySingleton<WorkspaceRemoteDataSource>(
    () => WorkspaceRemoteDataSource(locator<DioClient>()),
  );
  locator.registerLazySingleton<StoreAccessContextCacheStorage>(
    () => StoreAccessContextCacheStorageImpl(locator<SharedPreferences>()),
  );
  locator.registerLazySingleton<WorkspaceRepository>(
    () => WorkspaceRepositoryImpl(
      locator<WorkspaceRemoteDataSource>(),
      locator<StoreAccessContextCacheStorage>(),
    ),
  );
  locator.registerLazySingleton<LoadMyStoresUseCase>(
    () => LoadMyStoresUseCase(locator<WorkspaceRepository>()),
  );
  locator.registerLazySingleton<CreateStoreUseCase>(
    () => CreateStoreUseCase(locator<WorkspaceRepository>()),
  );
  locator.registerLazySingleton<LoadStoreAccessContextUseCase>(
    () => LoadStoreAccessContextUseCase(locator<WorkspaceRepository>()),
  );
  locator.registerLazySingleton<LoadCachedStoreAccessContextUseCase>(
    () => LoadCachedStoreAccessContextUseCase(locator<WorkspaceRepository>()),
  );
  locator.registerLazySingleton<SaveStoreAccessContextCacheUseCase>(
    () => SaveStoreAccessContextCacheUseCase(locator<WorkspaceRepository>()),
  );
  locator.registerLazySingleton<ClearStoreAccessContextCacheUseCase>(
    () => ClearStoreAccessContextCacheUseCase(locator<WorkspaceRepository>()),
  );
  locator.registerLazySingleton<ClearAllStoreAccessContextCacheUseCase>(
    () =>
        ClearAllStoreAccessContextCacheUseCase(locator<WorkspaceRepository>()),
  );
  locator.registerLazySingleton<LoadLastActiveStoreUseCase>(
    () => LoadLastActiveStoreUseCase(locator<LastActiveStoreStorage>()),
  );
  locator.registerLazySingleton<SaveLastActiveStoreUseCase>(
    () => SaveLastActiveStoreUseCase(locator<LastActiveStoreStorage>()),
  );
  locator.registerLazySingleton<ClearLastActiveStoreUseCase>(
    () => ClearLastActiveStoreUseCase(locator<LastActiveStoreStorage>()),
  );

  // Table management
  locator.registerLazySingleton<TableManagementRemoteDataSource>(
    () => TableManagementRemoteDataSource(locator<DioClient>()),
  );
  locator.registerLazySingleton<TableManagementRepository>(
    () => TableManagementRepositoryImpl(
      locator<TableManagementRemoteDataSource>(),
    ),
  );
  locator.registerLazySingleton<LoadAreasUseCase>(
    () => LoadAreasUseCase(locator<TableManagementRepository>()),
  );
  locator.registerLazySingleton<LoadTableGroupsUseCase>(
    () => LoadTableGroupsUseCase(locator<TableManagementRepository>()),
  );
  locator.registerLazySingleton<LoadTableDetailUseCase>(
    () => LoadTableDetailUseCase(locator<TableManagementRepository>()),
  );
  locator.registerLazySingleton<LoadAreaDetailUseCase>(
    () => LoadAreaDetailUseCase(locator<TableManagementRepository>()),
  );
  locator.registerLazySingleton<LoadTableSessionsUseCase>(
    () => LoadTableSessionsUseCase(locator<TableManagementRepository>()),
  );
  locator.registerLazySingleton<LoadOpenTableSessionsUseCase>(
    () => LoadOpenTableSessionsUseCase(locator<TableManagementRepository>()),
  );
  locator.registerLazySingleton<CreateAreaUseCase>(
    () => CreateAreaUseCase(locator<TableManagementRepository>()),
  );
  locator.registerLazySingleton<CreateTableUseCase>(
    () => CreateTableUseCase(locator<TableManagementRepository>()),
  );
  locator.registerLazySingleton<UpdateAreaUseCase>(
    () => UpdateAreaUseCase(locator<TableManagementRepository>()),
  );
  locator.registerLazySingleton<UpdateTableUseCase>(
    () => UpdateTableUseCase(locator<TableManagementRepository>()),
  );
  locator.registerLazySingleton<UpdateTableStatusUseCase>(
    () => UpdateTableStatusUseCase(locator<TableManagementRepository>()),
  );
  locator.registerLazySingleton<OpenTableSessionUseCase>(
    () => OpenTableSessionUseCase(locator<TableManagementRepository>()),
  );
  locator.registerLazySingleton<CloseTableSessionUseCase>(
    () => CloseTableSessionUseCase(locator<TableManagementRepository>()),
  );
  locator.registerLazySingleton<UpdateAreaDisplayOrderUseCase>(
    () => UpdateAreaDisplayOrderUseCase(locator<TableManagementRepository>()),
  );
  locator.registerLazySingleton<DeleteAreaUseCase>(
    () => DeleteAreaUseCase(locator<TableManagementRepository>()),
  );

  // Order management
  locator.registerLazySingleton<OrderManagementRemoteDataSource>(
    () => OrderManagementRemoteDataSource(locator<DioClient>()),
  );
  locator.registerLazySingleton<VietQrRemoteDataSource>(
    () => VietQrRemoteDataSource(
      Dio(BaseOptions(baseUrl: 'https://api.vietqr.io')),
    ),
  );
  locator.registerLazySingleton<OrderManagementRepository>(
    () => OrderManagementRepositoryImpl(
      locator<OrderManagementRemoteDataSource>(),
      locator<VietQrRemoteDataSource>(),
    ),
  );
  locator.registerLazySingleton<LoadOrdersByTableSessionUseCase>(
    () => LoadOrdersByTableSessionUseCase(locator<OrderManagementRepository>()),
  );
  locator.registerLazySingleton<LoadOrderDetailUseCase>(
    () => LoadOrderDetailUseCase(locator<OrderManagementRepository>()),
  );
  locator.registerLazySingleton<CreateOrderUseCase>(
    () => CreateOrderUseCase(locator<OrderManagementRepository>()),
  );
  locator.registerLazySingleton<CreateSessionInvoiceUseCase>(
    () => CreateSessionInvoiceUseCase(locator<OrderManagementRepository>()),
  );
  locator.registerLazySingleton<CreateOrderInvoiceUseCase>(
    () => CreateOrderInvoiceUseCase(locator<OrderManagementRepository>()),
  );
  locator.registerLazySingleton<ConfirmPaymentUseCase>(
    () => ConfirmPaymentUseCase(locator<OrderManagementRepository>()),
  );
  locator.registerLazySingleton<LoadVietQrBanksUseCase>(
    () => LoadVietQrBanksUseCase(locator<OrderManagementRepository>()),
  );

  // Owner dashboard
  locator.registerLazySingleton<OwnerDashboardRemoteDataSource>(
    () => OwnerDashboardRemoteDataSource(locator<DioClient>()),
  );
  locator.registerLazySingleton<OwnerDashboardRepository>(
    () =>
        OwnerDashboardRepositoryImpl(locator<OwnerDashboardRemoteDataSource>()),
  );
  locator.registerLazySingleton<LoadOwnerDashboardInsightUseCase>(
    () => LoadOwnerDashboardInsightUseCase(locator<OwnerDashboardRepository>()),
  );

  // Product management
  locator.registerLazySingleton<ProductManagementRemoteDataSource>(
    () => ProductManagementRemoteDataSource(locator<DioClient>(), Dio()),
  );

  // Inventory documents
  locator.registerLazySingleton<InventoryDocumentRemoteDataSource>(
    () => InventoryDocumentRemoteDataSource(locator<DioClient>()),
  );
  locator.registerLazySingleton<InventoryDocumentRepository>(
    () => InventoryDocumentRepositoryImpl(
      locator<InventoryDocumentRemoteDataSource>(),
    ),
  );
  locator.registerLazySingleton<LoadInventoryImportsUseCase>(
    () => LoadInventoryImportsUseCase(locator<InventoryDocumentRepository>()),
  );
  locator.registerLazySingleton<LoadInventoryDocumentUseCase>(
    () => LoadInventoryDocumentUseCase(locator<InventoryDocumentRepository>()),
  );
  locator.registerLazySingleton<LoadInventoryVendorsUseCase>(
    () => LoadInventoryVendorsUseCase(locator<InventoryDocumentRepository>()),
  );
  locator.registerLazySingleton<CreateInventoryVendorUseCase>(
    () => CreateInventoryVendorUseCase(locator<InventoryDocumentRepository>()),
  );
  locator.registerLazySingleton<LoadInventorySelectableItemsUseCase>(
    () => LoadInventorySelectableItemsUseCase(
      locator<InventoryDocumentRepository>(),
    ),
  );
  locator.registerLazySingleton<CreateInventoryImportUseCase>(
    () => CreateInventoryImportUseCase(locator<InventoryDocumentRepository>()),
  );
  locator.registerLazySingleton<UpdateInventoryImportUseCase>(
    () => UpdateInventoryImportUseCase(locator<InventoryDocumentRepository>()),
  );
  locator.registerLazySingleton<CompleteInventoryImportUseCase>(
    () =>
        CompleteInventoryImportUseCase(locator<InventoryDocumentRepository>()),
  );
  locator.registerLazySingleton<ProductManagementRepository>(
    () => ProductManagementRepositoryImpl(
      locator<ProductManagementRemoteDataSource>(),
    ),
  );
  locator.registerLazySingleton<LoadProductCategoriesUseCase>(
    () => LoadProductCategoriesUseCase(locator<ProductManagementRepository>()),
  );
  locator.registerLazySingleton<LoadProductToppingsUseCase>(
    () => LoadProductToppingsUseCase(locator<ProductManagementRepository>()),
  );
  locator.registerLazySingleton<LoadProductIngredientsUseCase>(
    () => LoadProductIngredientsUseCase(locator<ProductManagementRepository>()),
  );
  locator.registerLazySingleton<LoadIngredientInventorySettingsUseCase>(
    () => LoadIngredientInventorySettingsUseCase(
      locator<ProductManagementRepository>(),
    ),
  );
  locator.registerLazySingleton<LoadProductInventorySettingsUseCase>(
    () => LoadProductInventorySettingsUseCase(
      locator<ProductManagementRepository>(),
    ),
  );
  locator.registerLazySingleton<CreateProductIngredientUseCase>(
    () =>
        CreateProductIngredientUseCase(locator<ProductManagementRepository>()),
  );
  locator.registerLazySingleton<UpdateProductIngredientUseCase>(
    () =>
        UpdateProductIngredientUseCase(locator<ProductManagementRepository>()),
  );
  locator.registerLazySingleton<DeleteProductIngredientUseCase>(
    () =>
        DeleteProductIngredientUseCase(locator<ProductManagementRepository>()),
  );
  locator.registerLazySingleton<UpdateIngredientInventorySettingsUseCase>(
    () => UpdateIngredientInventorySettingsUseCase(
      locator<ProductManagementRepository>(),
    ),
  );
  locator.registerLazySingleton<CreateProductToppingUseCase>(
    () => CreateProductToppingUseCase(locator<ProductManagementRepository>()),
  );
  locator.registerLazySingleton<UpdateProductToppingUseCase>(
    () => UpdateProductToppingUseCase(locator<ProductManagementRepository>()),
  );
  locator.registerLazySingleton<DeleteProductToppingUseCase>(
    () => DeleteProductToppingUseCase(locator<ProductManagementRepository>()),
  );
  locator.registerLazySingleton<CreateProductCategoryUseCase>(
    () => CreateProductCategoryUseCase(locator<ProductManagementRepository>()),
  );
  locator.registerLazySingleton<UpdateProductCategoryUseCase>(
    () => UpdateProductCategoryUseCase(locator<ProductManagementRepository>()),
  );
  locator.registerLazySingleton<DeleteProductCategoryUseCase>(
    () => DeleteProductCategoryUseCase(locator<ProductManagementRepository>()),
  );
  locator.registerLazySingleton<LoadProductsUseCase>(
    () => LoadProductsUseCase(locator<ProductManagementRepository>()),
  );
  locator.registerLazySingleton<CreateProductUseCase>(
    () => CreateProductUseCase(locator<ProductManagementRepository>()),
  );
  locator.registerLazySingleton<LoadProductDetailUseCase>(
    () => LoadProductDetailUseCase(locator<ProductManagementRepository>()),
  );
  locator.registerLazySingleton<LoadProductRecipesUseCase>(
    () => LoadProductRecipesUseCase(locator<ProductManagementRepository>()),
  );
  locator.registerLazySingleton<UpdateProductUseCase>(
    () => UpdateProductUseCase(locator<ProductManagementRepository>()),
  );
  locator.registerLazySingleton<UpdateProductInventorySettingsUseCase>(
    () => UpdateProductInventorySettingsUseCase(
      locator<ProductManagementRepository>(),
    ),
  );
  locator.registerLazySingleton<ReplaceProductRecipeUseCase>(
    () => ReplaceProductRecipeUseCase(locator<ProductManagementRepository>()),
  );
  locator.registerLazySingleton<UpdateProductSellStatusUseCase>(
    () =>
        UpdateProductSellStatusUseCase(locator<ProductManagementRepository>()),
  );
  locator.registerLazySingleton<DeleteProductUseCase>(
    () => DeleteProductUseCase(locator<ProductManagementRepository>()),
  );

  // Voice order
  locator.registerLazySingleton<VoiceOrderRemoteDataSource>(
    () => VoiceOrderRemoteDataSource(locator<DioClient>()),
  );
  locator.registerLazySingleton<VoiceOrderRepository>(
    () => VoiceOrderRepositoryImpl(locator<VoiceOrderRemoteDataSource>()),
  );
  locator.registerLazySingleton<RecognizeVoiceOrderUseCase>(
    () => RecognizeVoiceOrderUseCase(locator<VoiceOrderRepository>()),
  );

  // Staff management
  locator.registerLazySingleton<StaffManagementRemoteDataSource>(
    () => StaffManagementRemoteDataSource(locator<DioClient>()),
  );
  locator.registerLazySingleton<StaffManagementRepository>(
    () => StaffManagementRepositoryImpl(
      locator<StaffManagementRemoteDataSource>(),
    ),
  );
  locator.registerLazySingleton<LoadStaffRolesUseCase>(
    () => LoadStaffRolesUseCase(locator<StaffManagementRepository>()),
  );
  locator.registerLazySingleton<LoadStaffMembersUseCase>(
    () => LoadStaffMembersUseCase(locator<StaffManagementRepository>()),
  );
  locator.registerLazySingleton<LoadStaffPermissionGroupsUseCase>(
    () =>
        LoadStaffPermissionGroupsUseCase(locator<StaffManagementRepository>()),
  );
  locator.registerLazySingleton<InviteStaffUseCase>(
    () => InviteStaffUseCase(locator<StaffManagementRepository>()),
  );
  locator.registerLazySingleton<CancelStaffInvitationUseCase>(
    () => CancelStaffInvitationUseCase(locator<StaffManagementRepository>()),
  );
  locator.registerLazySingleton<UpdateStaffDisplayNameUseCase>(
    () => UpdateStaffDisplayNameUseCase(locator<StaffManagementRepository>()),
  );
  locator.registerLazySingleton<UpdateStaffAccessUseCase>(
    () => UpdateStaffAccessUseCase(locator<StaffManagementRepository>()),
  );
  locator.registerLazySingleton<RemoveStaffUseCase>(
    () => RemoveStaffUseCase(locator<StaffManagementRepository>()),
  );
  locator.registerLazySingleton<CreateStaffRoleUseCase>(
    () => CreateStaffRoleUseCase(locator<StaffManagementRepository>()),
  );
  locator.registerLazySingleton<UpdateStaffRoleUseCase>(
    () => UpdateStaffRoleUseCase(locator<StaffManagementRepository>()),
  );
  locator.registerLazySingleton<DeleteStaffRoleUseCase>(
    () => DeleteStaffRoleUseCase(locator<StaffManagementRepository>()),
  );
}
