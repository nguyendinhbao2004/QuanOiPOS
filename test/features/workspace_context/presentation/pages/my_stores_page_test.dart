import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quan_oi/config/router_config.dart';
import 'package:quan_oi/core/storage/last_active_store_storage.dart';
import 'package:quan_oi/core/theme/index.dart';
import 'package:quan_oi/features/auth/domain/entities/account_type.dart';
import 'package:quan_oi/features/auth/presentation/controllers/auth_notifier.dart';
import 'package:quan_oi/features/auth/presentation/controllers/auth_state.dart';
import 'package:quan_oi/features/auth/presentation/providers/auth_providers.dart';
import 'package:quan_oi/features/subscription/domain/entities/active_subscription.dart';
import 'package:quan_oi/features/subscription/domain/entities/pending_subscription_purchase.dart';
import 'package:quan_oi/features/subscription/domain/entities/purchase_subscription_result.dart';
import 'package:quan_oi/features/subscription/domain/entities/service_package.dart';
import 'package:quan_oi/features/subscription/domain/repositories/subscription_repository.dart';
import 'package:quan_oi/features/subscription/domain/usecases/cancel_pending_subscription_purchase_use_case.dart';
import 'package:quan_oi/features/subscription/domain/usecases/clear_pending_subscription_purchase_use_case.dart';
import 'package:quan_oi/features/subscription/domain/usecases/load_active_subscription_use_case.dart';
import 'package:quan_oi/features/subscription/domain/usecases/load_pending_subscription_purchase_use_case.dart';
import 'package:quan_oi/features/subscription/domain/usecases/load_subscription_plans_use_case.dart';
import 'package:quan_oi/features/subscription/domain/usecases/purchase_subscription_use_case.dart';
import 'package:quan_oi/features/subscription/presentation/providers/subscription_providers.dart';
import 'package:quan_oi/features/workspace_context/domain/usecases/create_store_use_case.dart';
import 'package:quan_oi/features/workspace_context/domain/usecases/clear_last_active_store_use_case.dart';
import 'package:quan_oi/features/workspace_context/domain/usecases/clear_store_access_context_cache_use_case.dart';
import 'package:quan_oi/features/workspace_context/domain/usecases/load_cached_store_access_context_use_case.dart';
import 'package:quan_oi/features/workspace_context/domain/usecases/load_last_active_store_use_case.dart';
import 'package:quan_oi/features/workspace_context/domain/entities/store.dart';
import 'package:quan_oi/features/workspace_context/domain/entities/store_access_context.dart';
import 'package:quan_oi/features/workspace_context/domain/entities/store_permission.dart';
import 'package:quan_oi/features/workspace_context/domain/repositories/workspace_repository.dart';
import 'package:quan_oi/features/workspace_context/domain/usecases/load_my_stores_use_case.dart';
import 'package:quan_oi/features/workspace_context/domain/usecases/load_store_access_context_use_case.dart';
import 'package:quan_oi/features/workspace_context/domain/usecases/save_last_active_store_use_case.dart';
import 'package:quan_oi/features/workspace_context/domain/usecases/save_store_access_context_cache_use_case.dart';
import 'package:quan_oi/features/workspace_context/presentation/pages/my_stores_page.dart';
import 'package:quan_oi/features/workspace_context/presentation/providers/workspace_context_providers.dart';

void main() {
  testWidgets('StoreUser can open my stores route from account menu', (
    tester,
  ) async {
    final lastActiveStoreStorage = _FakeLastActiveStoreStorage();
    final container = _buildContainer(
      AccountType.storeUser,
      lastActiveStoreStorage: lastActiveStoreStorage,
    );
    addTearDown(container.dispose);

    final router = container.read(routerProvider);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(theme: AppTheme.light, routerConfig: router),
      ),
    );

    router.go('/store-home');
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Cửa hàng'));
    await tester.pumpAndSettle();

    expect(find.text('Danh sách cửa hàng'), findsOneWidget);
    expect(
      find.text('Buffet Poseidon Vincom Plaza Lê Văn Việt'),
      findsOneWidget,
    );
    expect(find.text('Hoạt động'), findsOneWidget);

    await tester.tap(find.byKey(const Key('access_store_2')));
    await tester.pumpAndSettle();

    expect(find.text('Tổng quan hôm nay'), findsOneWidget);
    expect(
      find.text('Bạn chưa tạo hóa đơn để phân tích lãi lỗ'),
      findsOneWidget,
    );
    expect(lastActiveStoreStorage.lastStoreId, 2);
  });

  testWidgets('StoreUser opens last active store from root route', (
    tester,
  ) async {
    final container = _buildContainer(
      AccountType.storeUser,
      lastActiveStoreStorage: _FakeLastActiveStoreStorage(initialStoreId: 2),
    );
    addTearDown(container.dispose);

    final router = container.read(routerProvider);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(theme: AppTheme.light, routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Tổng quan hôm nay'), findsOneWidget);
    expect(
      find.text('Buffet Poseidon Vincom Plaza Lê Văn Việt'),
      findsOneWidget,
    );
    expect(find.text('Xin chào, Test User'), findsNothing);
  });

  testWidgets(
    'StoreUser opens cached last active store without blocking loader',
    (tester) async {
      final accessCompleter = Completer<StoreAccessContext>();
      final repository = _FakeWorkspaceRepository(
        cachedContext: _cachedAccessContext,
        accessCompleter: accessCompleter,
      );
      final container = _buildContainer(
        AccountType.storeUser,
        workspaceRepository: repository,
        lastActiveStoreStorage: _FakeLastActiveStoreStorage(initialStoreId: 2),
      );
      addTearDown(container.dispose);

      final router = container.read(routerProvider);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(
            theme: AppTheme.light,
            routerConfig: router,
          ),
        ),
      );

      for (var i = 0; i < 5; i += 1) {
        await tester.pump();
      }

      expect(find.text('Cached Buffet'), findsOneWidget);
      expect(find.text('Tổng quan hôm nay'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);

      accessCompleter.complete(_remoteAccessContext);
      await tester.pumpAndSettle();

      expect(
        find.text('Buffet Poseidon Vincom Plaza Lê Văn Việt'),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'StoreUser opens account hub from root without last active store',
    (tester) async {
      final container = _buildContainer(AccountType.storeUser);
      addTearDown(container.dispose);

      final router = container.read(routerProvider);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(
            theme: AppTheme.light,
            routerConfig: router,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Xin chào, Test User'), findsOneWidget);
      expect(find.text('Tổng quan hôm nay'), findsNothing);
    },
  );

  testWidgets('SystemAdmin is redirected away from my stores route', (
    tester,
  ) async {
    final container = _buildContainer(
      AccountType.systemAdmin,
      lastActiveStoreStorage: _FakeLastActiveStoreStorage(initialStoreId: 2),
    );
    addTearDown(container.dispose);

    final router = container.read(routerProvider);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(theme: AppTheme.light, routerConfig: router),
      ),
    );

    router.go('/my-stores');
    await tester.pumpAndSettle();

    expect(find.text('SystemAdmin Workspace'), findsOneWidget);
    expect(find.text('Danh sách cửa hàng'), findsNothing);
  });

  testWidgets('SystemAdmin is redirected away from store overview route', (
    tester,
  ) async {
    final container = _buildContainer(
      AccountType.systemAdmin,
      lastActiveStoreStorage: _FakeLastActiveStoreStorage(initialStoreId: 2),
    );
    addTearDown(container.dispose);

    final router = container.read(routerProvider);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(theme: AppTheme.light, routerConfig: router),
      ),
    );

    router.go('/stores/2');
    await tester.pumpAndSettle();

    expect(find.text('SystemAdmin Workspace'), findsOneWidget);
    expect(find.text('Tổng quan hôm nay'), findsNothing);
  });

  testWidgets('my stores page enables access only for active stores', (
    tester,
  ) async {
    await _pumpMyStoresPage(tester, _FakeWorkspaceRepository());
    await tester.pumpAndSettle();

    expect(find.text('Hoạt động'), findsOneWidget);
    expect(find.text('Ngưng hoạt động'), findsOneWidget);
    expect(find.text('Đóng cửa'), findsOneWidget);

    final activeButton = tester.widget<ElevatedButton>(
      find.byKey(const Key('access_store_2')),
    );
    final inactiveButton = tester.widget<ElevatedButton>(
      find.byKey(const Key('access_store_5')),
    );
    final closedButton = tester.widget<ElevatedButton>(
      find.byKey(const Key('access_store_6')),
    );

    expect(activeButton.onPressed, isNotNull);
    expect(inactiveButton.onPressed, isNull);
    expect(closedButton.onPressed, isNull);
  });

  testWidgets('my stores page shows empty and search-empty states', (
    tester,
  ) async {
    await _pumpMyStoresPage(tester, _FakeWorkspaceRepository(stores: const []));
    await tester.pumpAndSettle();

    expect(find.text('Chưa có cửa hàng'), findsOneWidget);
    expect(find.text('Tạo cửa hàng'), findsOneWidget);

    await _pumpMyStoresPage(tester, _FakeWorkspaceRepository());
    await tester.pumpAndSettle();

    expect(
      find.text('Buffet Poseidon Vincom Plaza Lê Văn Việt'),
      findsOneWidget,
    );

    await tester.enterText(
      find.byKey(const Key('my_stores_search_field')),
      'khong-co',
    );
    await tester.pumpAndSettle();

    expect(find.text('Không tìm thấy cửa hàng'), findsOneWidget);
  });

  testWidgets('my stores page shows loading state', (tester) async {
    final completer = Completer<List<Store>>();
    await _pumpMyStoresPage(
      tester,
      _FakeWorkspaceRepository(loadCompleter: completer),
    );
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('my stores page shows error state', (tester) async {
    await _pumpMyStoresPage(
      tester,
      _FakeWorkspaceRepository(loadError: Exception('Network down')),
    );
    await tester.pumpAndSettle();

    expect(find.text('Network down'), findsOneWidget);
    expect(find.text('Thử lại'), findsOneWidget);
  });

  testWidgets('create store action opens form when subscription is active', (
    tester,
  ) async {
    final container = _buildContainer(AccountType.storeUser);
    addTearDown(container.dispose);

    final router = container.read(routerProvider);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(theme: AppTheme.light, routerConfig: router),
      ),
    );

    router.go('/my-stores');
    await tester.pumpAndSettle();

    await tester.tap(find.text('Thêm mới'));
    await tester.pumpAndSettle();

    expect(find.text('Tạo cửa hàng'), findsOneWidget);
    expect(find.byKey(const Key('create_store_name_field')), findsOneWidget);
  });

  testWidgets(
    'create store action redirects to subscription without active package',
    (tester) async {
      final container = _buildContainer(
        AccountType.storeUser,
        activeSubscription: null,
      );
      addTearDown(container.dispose);

      final router = container.read(routerProvider);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(
            theme: AppTheme.light,
            routerConfig: router,
          ),
        ),
      );

      router.go('/my-stores');
      await tester.pumpAndSettle();

      await tester.tap(find.text('Thêm mới'));
      await tester.pumpAndSettle();

      expect(find.text('Gói dịch vụ của tôi'), findsOneWidget);
      expect(find.text('Tạo cửa hàng'), findsNothing);
    },
  );

  testWidgets('empty stores create CTA opens create form', (tester) async {
    final container = _buildContainer(AccountType.storeUser, stores: const []);
    addTearDown(container.dispose);

    final router = container.read(routerProvider);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(theme: AppTheme.light, routerConfig: router),
      ),
    );

    router.go('/my-stores');
    await tester.pumpAndSettle();

    await tester.tap(find.text('Tạo cửa hàng'));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('create_store_name_field')), findsOneWidget);
  });

  testWidgets('create store form validates required fields and phone', (
    tester,
  ) async {
    final container = _buildContainer(AccountType.storeUser);
    addTearDown(container.dispose);

    final router = container.read(routerProvider);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(theme: AppTheme.light, routerConfig: router),
      ),
    );

    router.go('/stores/create');
    await tester.pumpAndSettle();

    await tester.ensureVisible(
      find.byKey(const Key('create_store_submit_button')),
    );
    await tester.tap(find.byKey(const Key('create_store_submit_button')));
    await tester.pumpAndSettle();

    expect(find.text('Vui lòng nhập tên cửa hàng'), findsOneWidget);
    expect(find.text('Vui lòng nhập số điện thoại'), findsOneWidget);
    expect(find.text('Vui lòng nhập địa chỉ cửa hàng'), findsOneWidget);

    await tester.enterText(
      find.byKey(const Key('create_store_name_field')),
      'Quan oi',
    );
    await tester.enterText(
      find.byKey(const Key('create_store_phone_field')),
      '123',
    );
    await tester.enterText(
      find.byKey(const Key('create_store_address_field')),
      '123 Nguyen Trai',
    );
    await tester.ensureVisible(
      find.byKey(const Key('create_store_submit_button')),
    );
    await tester.tap(find.byKey(const Key('create_store_submit_button')));
    await tester.pumpAndSettle();

    expect(
      find.text('Số điện thoại phải gồm 10 hoặc 11 chữ số'),
      findsOneWidget,
    );
  });

  testWidgets('create store submit saves active store and opens overview', (
    tester,
  ) async {
    final repository = _FakeWorkspaceRepository();
    final lastActiveStoreStorage = _FakeLastActiveStoreStorage();
    final container = _buildContainer(
      AccountType.storeUser,
      workspaceRepository: repository,
      lastActiveStoreStorage: lastActiveStoreStorage,
    );
    addTearDown(container.dispose);

    final router = container.read(routerProvider);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(theme: AppTheme.light, routerConfig: router),
      ),
    );

    router.go('/stores/create');
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('create_store_name_field')),
      'Quan oi',
    );
    await tester.enterText(
      find.byKey(const Key('create_store_phone_field')),
      '0900000000',
    );
    await tester.enterText(
      find.byKey(const Key('create_store_address_field')),
      '123 Nguyen Trai',
    );
    await tester.ensureVisible(
      find.byKey(const Key('create_store_submit_button')),
    );
    await tester.tap(find.byKey(const Key('create_store_submit_button')));
    await tester.pumpAndSettle();

    expect(lastActiveStoreStorage.lastStoreId, 10);
    expect(repository.createStoreCallCount, 1);
    expect(find.text('Tổng quan hôm nay'), findsOneWidget);
    expect(find.text('Quan oi'), findsOneWidget);
  });
}

Future<void> _pumpMyStoresPage(
  WidgetTester tester,
  _FakeWorkspaceRepository repository,
) async {
  await tester.pumpWidget(
    ProviderScope(
      key: UniqueKey(),
      overrides: [
        loadMyStoresUseCaseProvider.overrideWithValue(
          LoadMyStoresUseCase(repository),
        ),
        createStoreUseCaseProvider.overrideWithValue(
          CreateStoreUseCase(repository),
        ),
        ..._subscriptionOverrides(_FakeSubscriptionRepository()),
        ..._lastActiveStoreOverrides(_FakeLastActiveStoreStorage()),
      ],
      child: MaterialApp(theme: AppTheme.light, home: const MyStoresPage()),
    ),
  );
}

ProviderContainer _buildContainer(
  AccountType accountType, {
  List<Store> stores = _defaultStores,
  _FakeWorkspaceRepository? workspaceRepository,
  _FakeLastActiveStoreStorage? lastActiveStoreStorage,
  ActiveSubscription? activeSubscription = _activeSubscription,
}) {
  final repository =
      workspaceRepository ?? _FakeWorkspaceRepository(stores: stores);
  final storeStorage = lastActiveStoreStorage ?? _FakeLastActiveStoreStorage();
  final subscriptionRepository = _FakeSubscriptionRepository(
    activeSubscription: activeSubscription,
  );

  return ProviderContainer(
    overrides: [
      authNotifierProvider.overrideWith(
        () => _FixedAuthNotifier(
          AuthState(
            status: AuthStatus.authenticated,
            accountId: 8,
            accountType: accountType,
            fullName: 'Test User',
            email: 'user@quanoi.test',
          ),
        ),
      ),
      loadMyStoresUseCaseProvider.overrideWithValue(
        LoadMyStoresUseCase(repository),
      ),
      createStoreUseCaseProvider.overrideWithValue(
        CreateStoreUseCase(repository),
      ),
      loadStoreAccessContextUseCaseProvider.overrideWithValue(
        LoadStoreAccessContextUseCase(repository),
      ),
      loadCachedStoreAccessContextUseCaseProvider.overrideWithValue(
        LoadCachedStoreAccessContextUseCase(repository),
      ),
      saveStoreAccessContextCacheUseCaseProvider.overrideWithValue(
        SaveStoreAccessContextCacheUseCase(repository),
      ),
      clearStoreAccessContextCacheUseCaseProvider.overrideWithValue(
        ClearStoreAccessContextCacheUseCase(repository),
      ),
      ..._subscriptionOverrides(subscriptionRepository),
      ..._lastActiveStoreOverrides(storeStorage),
    ],
  );
}

List<Override> _subscriptionOverrides(_FakeSubscriptionRepository repository) {
  return [
    loadSubscriptionPlansUseCaseProvider.overrideWithValue(
      LoadSubscriptionPlansUseCase(repository),
    ),
    loadActiveSubscriptionUseCaseProvider.overrideWithValue(
      LoadActiveSubscriptionUseCase(repository),
    ),
    purchaseSubscriptionUseCaseProvider.overrideWithValue(
      PurchaseSubscriptionUseCase(repository),
    ),
    loadPendingSubscriptionPurchaseUseCaseProvider.overrideWithValue(
      LoadPendingSubscriptionPurchaseUseCase(repository),
    ),
    clearPendingSubscriptionPurchaseUseCaseProvider.overrideWithValue(
      ClearPendingSubscriptionPurchaseUseCase(repository),
    ),
    cancelPendingSubscriptionPurchaseUseCaseProvider.overrideWithValue(
      CancelPendingSubscriptionPurchaseUseCase(repository),
    ),
  ];
}

List<Override> _lastActiveStoreOverrides(_FakeLastActiveStoreStorage storage) {
  return [
    loadLastActiveStoreUseCaseProvider.overrideWithValue(
      LoadLastActiveStoreUseCase(storage),
    ),
    saveLastActiveStoreUseCaseProvider.overrideWithValue(
      SaveLastActiveStoreUseCase(storage),
    ),
    clearLastActiveStoreUseCaseProvider.overrideWithValue(
      ClearLastActiveStoreUseCase(storage),
    ),
  ];
}

class _FixedAuthNotifier extends AuthNotifier {
  final AuthState fixedState;

  _FixedAuthNotifier(this.fixedState);

  @override
  AuthState build() {
    return fixedState;
  }
}

class _FakeWorkspaceRepository implements WorkspaceRepository {
  final Exception? loadError;
  final Completer<List<Store>>? loadCompleter;
  final Completer<StoreAccessContext>? accessCompleter;
  final List<Store> stores;
  StoreAccessContext? cachedContext;
  StoreAccessContext? savedCache;
  int createStoreCallCount = 0;

  _FakeWorkspaceRepository({
    this.loadError,
    this.loadCompleter,
    this.accessCompleter,
    this.cachedContext,
    List<Store> stores = _defaultStores,
  }) : stores = List<Store>.of(stores);

  @override
  Future<List<Store>> loadMyStores() async {
    final error = loadError;
    if (error != null) {
      throw error;
    }

    final completer = loadCompleter;
    if (completer != null) {
      return completer.future;
    }

    return stores;
  }

  @override
  Future<Store> createStore({
    required String storeName,
    required String phone,
    required String address,
  }) async {
    createStoreCallCount += 1;
    final store = Store(
      id: 10,
      ownerAccountId: 8,
      storeName: storeName,
      phone: phone,
      address: address,
      status: StoreStatus.active,
      isDeleted: false,
    );
    stores.add(store);
    return store;
  }

  @override
  Future<Store> loadStoreById(int storeId) async {
    return stores.firstWhere((store) => store.id == storeId);
  }

  @override
  Future<List<StorePermission>> loadMyStorePermissions(int storeId) async {
    return const [StorePermission(permissionId: 1, code: 'DASHBOARD.VIEW')];
  }

  @override
  Future<StoreAccessContext> loadStoreAccessContext(int storeId) async {
    final completer = accessCompleter;
    if (completer != null) {
      return completer.future;
    }

    return StoreAccessContext(
      store: await loadStoreById(storeId),
      permissions: await loadMyStorePermissions(storeId),
    );
  }

  @override
  Future<StoreAccessContext?> loadCachedStoreAccessContext({
    required int accountId,
    required int storeId,
  }) async {
    return cachedContext;
  }

  @override
  Future<void> saveStoreAccessContextCache({
    required int accountId,
    required StoreAccessContext context,
  }) async {
    savedCache = context;
    cachedContext = context;
  }

  @override
  Future<void> clearStoreAccessContextCache({
    required int accountId,
    required int storeId,
  }) async {
    cachedContext = null;
  }

  @override
  Future<void> clearAllStoreAccessContextCache() async {
    cachedContext = null;
  }
}

class _FakeSubscriptionRepository implements SubscriptionRepository {
  final ActiveSubscription? activeSubscription;

  const _FakeSubscriptionRepository({
    this.activeSubscription = _activeSubscription,
  });

  @override
  Future<List<ServicePackage>> loadPlans() async {
    return const [_servicePackage];
  }

  @override
  Future<ActiveSubscription?> loadActiveSubscription() async {
    return activeSubscription;
  }

  @override
  Future<PurchaseSubscriptionResult> purchaseSubscription({
    required int planId,
    bool autoRenew = true,
    String? returnUrl,
    String? cancelUrl,
  }) async {
    return const PurchaseSubscriptionResult(
      subscriptionId: 3,
      paymentId: 7,
      orderCode: 81780473152,
      planName: 'Pro',
      amount: 299000,
      paymentLink: 'https://pay.payos.vn/web/test',
      daysValid: 30,
      maxStores: 5,
      expiresAt: null,
    );
  }

  @override
  Future<PendingSubscriptionPurchase?> loadPendingPurchase() async {
    return null;
  }

  @override
  Future<void> clearPendingPurchase() async {}

  @override
  Future<void> cancelPendingPurchase({required int subscriptionId}) async {}
}

class _FakeLastActiveStoreStorage implements LastActiveStoreStorage {
  int? lastStoreId;

  _FakeLastActiveStoreStorage({int? initialStoreId})
    : lastStoreId = initialStoreId;

  @override
  Future<int?> getLastActiveStoreId() async {
    return lastStoreId;
  }

  @override
  Future<void> saveLastActiveStoreId(int storeId) async {
    lastStoreId = storeId;
  }

  @override
  Future<void> clearLastActiveStoreId() async {
    lastStoreId = null;
  }
}

const _activeSubscription = ActiveSubscription(
  id: 2,
  accountId: 8,
  planId: 2,
  planName: 'Pro',
  price: 299000,
  startDate: null,
  endDate: null,
  daysRemaining: 18,
  isActive: true,
  isExpired: false,
  maxStores: 5,
  maxUsers: 50,
  status: 'Active',
  autoRenew: true,
  cancelAt: null,
);

const _servicePackage = ServicePackage(
  id: '2',
  name: 'Pro',
  priceAmount: 299000,
  durationDays: 30,
  maxStores: 5,
  maxUsers: 50,
  features: ['Dashboard nâng cao'],
  isActive: true,
);

const _defaultStores = [
  Store(
    id: 2,
    ownerAccountId: 8,
    storeName: 'Buffet Poseidon Vincom Plaza Lê Văn Việt',
    phone: '0961813466',
    address: 'TTTM Vincom Plaza, 50 Đ. Lê Văn Việt',
    status: StoreStatus.active,
    isDeleted: false,
  ),
  Store(
    id: 5,
    ownerAccountId: 8,
    storeName: 'FPT Shipper Vip',
    phone: '0123456789',
    address: 'Gần Đại Học FPT',
    status: StoreStatus.inactive,
    isDeleted: false,
  ),
  Store(
    id: 6,
    ownerAccountId: 8,
    storeName: 'Kitchen Closed',
    phone: '0900000000',
    address: 'Quận 1',
    status: StoreStatus.closed,
    isDeleted: false,
  ),
];

const _cachedAccessContext = StoreAccessContext(
  store: Store(
    id: 2,
    ownerAccountId: 8,
    storeName: 'Cached Buffet',
    phone: '0961813466',
    address: 'Cached address',
    status: StoreStatus.active,
    isDeleted: false,
  ),
  permissions: [StorePermission(permissionId: 1, code: 'DASHBOARD.VIEW')],
);

const _remoteAccessContext = StoreAccessContext(
  store: Store(
    id: 2,
    ownerAccountId: 8,
    storeName: 'Buffet Poseidon Vincom Plaza Lê Văn Việt',
    phone: '0961813466',
    address: 'TTTM Vincom Plaza, 50 Đ. Lê Văn Việt',
    status: StoreStatus.active,
    isDeleted: false,
  ),
  permissions: [StorePermission(permissionId: 1, code: 'DASHBOARD.VIEW')],
);
