import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quan_oi/config/router_config.dart';
import 'package:quan_oi/core/theme/index.dart';
import 'package:quan_oi/features/auth/domain/entities/account_type.dart';
import 'package:quan_oi/features/auth/presentation/controllers/auth_notifier.dart';
import 'package:quan_oi/features/auth/presentation/controllers/auth_state.dart';
import 'package:quan_oi/features/auth/presentation/providers/auth_providers.dart';
import 'package:quan_oi/features/store_operations/presentation/pages/store_overview_page.dart';
import 'package:quan_oi/features/workspace_context/domain/entities/store.dart';
import 'package:quan_oi/features/workspace_context/domain/entities/store_access_context.dart';
import 'package:quan_oi/features/workspace_context/domain/entities/store_permission.dart';
import 'package:quan_oi/features/workspace_context/domain/repositories/workspace_repository.dart';
import 'package:quan_oi/features/workspace_context/domain/usecases/load_my_stores_use_case.dart';
import 'package:quan_oi/features/workspace_context/domain/usecases/load_store_access_context_use_case.dart';
import 'package:quan_oi/features/workspace_context/presentation/providers/workspace_context_providers.dart';

void main() {
  testWidgets('store overview renders dashboard and active overview nav', (
    tester,
  ) async {
    await _pumpOverview(
      tester,
      const _FakeWorkspaceRepository(
        permissions: [
          StorePermission(permissionId: 1, code: 'DASHBOARD.VIEW'),
          StorePermission(permissionId: 3, code: 'STORE.UPDATE'),
          StorePermission(permissionId: 4, code: 'AREA.VIEW'),
        ],
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('FPT Shipper Vip'), findsOneWidget);
    expect(find.byIcon(Icons.arrow_back_rounded), findsNothing);
    expect(find.text('Tổng quan hôm nay'), findsOneWidget);
    expect(
      find.text('Bạn chưa tạo hóa đơn để phân tích lãi lỗ'),
      findsOneWidget,
    );
    expect(find.text('Tổng quan'), findsOneWidget);
    expect(find.text('Quản lý bàn'), findsOneWidget);
    expect(find.text('Bạn chưa có quyền xem quản lý bàn'), findsNothing);
  });

  testWidgets('store overview blocks dashboard without DASHBOARD.VIEW', (
    tester,
  ) async {
    await _pumpOverview(
      tester,
      const _FakeWorkspaceRepository(
        permissions: [StorePermission(permissionId: 2, code: 'STORE.VIEW')],
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Bạn chưa có quyền xem tổng quan'), findsOneWidget);
    expect(find.text('Tổng quan hôm nay'), findsNothing);
  });

  testWidgets('store overview disables missing permission actions', (
    tester,
  ) async {
    await _pumpOverview(
      tester,
      const _FakeWorkspaceRepository(
        permissions: [StorePermission(permissionId: 1, code: 'DASHBOARD.VIEW')],
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Bạn chưa có quyền xem quản lý bàn'), findsOneWidget);
    expect(find.text('Bạn chưa có quyền cập nhật cửa hàng'), findsWidgets);
  });

  testWidgets('store header opens switcher bottom sheet with active store', (
    tester,
  ) async {
    await _pumpOverview(
      tester,
      const _FakeWorkspaceRepository(
        permissions: [StorePermission(permissionId: 1, code: 'DASHBOARD.VIEW')],
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(const Key('store_workspace_header_store_button')),
    );
    await tester.pumpAndSettle();

    expect(find.text('Chuyển cửa hàng'), findsOneWidget);
    expect(find.byKey(const Key('switch_store_5')), findsOneWidget);
    expect(find.text('Buffet Poseidon'), findsOneWidget);
    expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);

    await tester.enterText(
      find.byKey(const Key('store_switcher_search_field')),
      'poseidon',
    );
    await tester.pumpAndSettle();

    expect(find.text('Buffet Poseidon'), findsOneWidget);
    expect(find.byKey(const Key('switch_store_5')), findsNothing);
  });

  testWidgets('selecting current store closes switcher without route reload', (
    tester,
  ) async {
    await _pumpOverview(
      tester,
      const _FakeWorkspaceRepository(
        permissions: [StorePermission(permissionId: 1, code: 'DASHBOARD.VIEW')],
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(const Key('store_workspace_header_store_button')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('switch_store_5')));
    await tester.pumpAndSettle();

    expect(find.text('Chuyển cửa hàng'), findsNothing);
    expect(find.text('FPT Shipper Vip'), findsOneWidget);
  });

  testWidgets(
    'selecting another active store navigates to that store overview',
    (tester) async {
      final repository = const _FakeWorkspaceRepository(
        permissions: [StorePermission(permissionId: 1, code: 'DASHBOARD.VIEW')],
      );
      final container = _buildRouterContainer(repository);
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

      router.go('/stores/5');
      await tester.pumpAndSettle();

      await tester.tap(
        find.byKey(const Key('store_workspace_header_store_button')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('switch_store_2')));
      await tester.pumpAndSettle();

      expect(find.text('Buffet Poseidon'), findsOneWidget);
      expect(find.text('FPT Shipper Vip'), findsNothing);
    },
  );

  testWidgets('inactive store is disabled in switcher', (tester) async {
    await _pumpOverview(
      tester,
      const _FakeWorkspaceRepository(
        permissions: [StorePermission(permissionId: 1, code: 'DASHBOARD.VIEW')],
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(const Key('store_workspace_header_store_button')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('switch_store_6')));
    await tester.pumpAndSettle();

    expect(find.text('Chuyển cửa hàng'), findsOneWidget);
    expect(find.byKey(const Key('switch_store_6')), findsOneWidget);
  });
}

Future<void> _pumpOverview(
  WidgetTester tester,
  _FakeWorkspaceRepository repository,
) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authNotifierProvider.overrideWith(
          () => _FixedAuthNotifier(
            const AuthState(
              status: AuthStatus.authenticated,
              accountType: AccountType.storeUser,
              fullName: 'Test User',
              email: 'user@quanoi.test',
            ),
          ),
        ),
        loadStoreAccessContextUseCaseProvider.overrideWithValue(
          LoadStoreAccessContextUseCase(repository),
        ),
        loadMyStoresUseCaseProvider.overrideWithValue(
          LoadMyStoresUseCase(repository),
        ),
      ],
      child: MaterialApp(
        theme: AppTheme.light,
        home: const StoreOverviewPage(storeId: 5),
      ),
    ),
  );
}

ProviderContainer _buildRouterContainer(_FakeWorkspaceRepository repository) {
  return ProviderContainer(
    overrides: [
      authNotifierProvider.overrideWith(
        () => _FixedAuthNotifier(
          const AuthState(
            status: AuthStatus.authenticated,
            accountType: AccountType.storeUser,
            fullName: 'Test User',
            email: 'user@quanoi.test',
          ),
        ),
      ),
      loadStoreAccessContextUseCaseProvider.overrideWithValue(
        LoadStoreAccessContextUseCase(repository),
      ),
      loadMyStoresUseCaseProvider.overrideWithValue(
        LoadMyStoresUseCase(repository),
      ),
    ],
  );
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
  final List<StorePermission> permissions;

  const _FakeWorkspaceRepository({required this.permissions});

  @override
  Future<List<Store>> loadMyStores() async {
    return _stores;
  }

  @override
  Future<Store> loadStoreById(int storeId) async {
    return _stores.firstWhere((store) => store.id == storeId);
  }

  @override
  Future<List<StorePermission>> loadMyStorePermissions(int storeId) async {
    return permissions;
  }

  @override
  Future<StoreAccessContext> loadStoreAccessContext(int storeId) async {
    return StoreAccessContext(
      store: await loadStoreById(storeId),
      permissions: await loadMyStorePermissions(storeId),
    );
  }
}

const _stores = [
  Store(
    id: 5,
    ownerAccountId: 8,
    storeName: 'FPT Shipper Vip',
    phone: '0123456789',
    address: 'Gần Đại Học FPT',
    status: StoreStatus.active,
    isDeleted: false,
  ),
  Store(
    id: 2,
    ownerAccountId: 8,
    storeName: 'Buffet Poseidon',
    phone: '0961813466',
    address: 'TTTM Vincom Plaza',
    status: StoreStatus.active,
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
