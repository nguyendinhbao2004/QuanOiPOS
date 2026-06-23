import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quan_oi/core/constants/app_permission_codes.dart';
import 'package:quan_oi/core/storage/last_active_store_storage.dart';
import 'package:quan_oi/core/theme/index.dart';
import 'package:quan_oi/features/auth/domain/entities/account_type.dart';
import 'package:quan_oi/features/auth/presentation/controllers/auth_notifier.dart';
import 'package:quan_oi/features/auth/presentation/controllers/auth_state.dart';
import 'package:quan_oi/features/auth/presentation/providers/auth_providers.dart';
import 'package:quan_oi/features/store_operations/kitchen/domain/entities/kitchen_order_item.dart';
import 'package:quan_oi/features/store_operations/kitchen/domain/repositories/kitchen_repository.dart';
import 'package:quan_oi/features/store_operations/kitchen/domain/usecases/bulk_cancel_kitchen_items_use_case.dart';
import 'package:quan_oi/features/store_operations/kitchen/domain/usecases/bulk_update_kitchen_items_use_case.dart';
import 'package:quan_oi/features/store_operations/kitchen/domain/usecases/cancel_kitchen_item_use_case.dart';
import 'package:quan_oi/features/store_operations/kitchen/domain/usecases/load_kitchen_items_use_case.dart';
import 'package:quan_oi/features/store_operations/kitchen/domain/usecases/update_kitchen_item_status_use_case.dart';
import 'package:quan_oi/features/store_operations/kitchen/presentation/pages/kitchen_page.dart';
import 'package:quan_oi/features/store_operations/kitchen/presentation/controllers/kitchen_state.dart';
import 'package:quan_oi/features/store_operations/kitchen/presentation/providers/kitchen_providers.dart';
import 'package:quan_oi/features/workspace_context/domain/entities/store.dart';
import 'package:quan_oi/features/workspace_context/domain/entities/store_access_context.dart';
import 'package:quan_oi/features/workspace_context/domain/entities/store_permission.dart';
import 'package:quan_oi/features/workspace_context/domain/repositories/workspace_repository.dart';
import 'package:quan_oi/features/workspace_context/domain/usecases/clear_last_active_store_use_case.dart';
import 'package:quan_oi/features/workspace_context/domain/usecases/clear_store_access_context_cache_use_case.dart';
import 'package:quan_oi/features/workspace_context/domain/usecases/load_cached_store_access_context_use_case.dart';
import 'package:quan_oi/features/workspace_context/domain/usecases/load_last_active_store_use_case.dart';
import 'package:quan_oi/features/workspace_context/domain/usecases/load_my_stores_use_case.dart';
import 'package:quan_oi/features/workspace_context/domain/usecases/load_store_access_context_use_case.dart';
import 'package:quan_oi/features/workspace_context/domain/usecases/save_last_active_store_use_case.dart';
import 'package:quan_oi/features/workspace_context/domain/usecases/save_store_access_context_cache_use_case.dart';
import 'package:quan_oi/features/workspace_context/presentation/providers/workspace_context_providers.dart';

void main() {
  test('todayVietnamKitchenFilter builds current Vietnam day in UTC', () {
    final filter = todayVietnamKitchenFilter(
      nowUtc: DateTime.utc(2026, 6, 23, 15, 23),
    );

    expect(filter.status, KitchenOrderItemStatus.pending);
    expect(filter.orderedFrom, DateTime.utc(2026, 6, 22, 17));
    expect(filter.orderedTo, DateTime.utc(2026, 6, 23, 16, 59, 59, 999));
  });

  testWidgets('kitchen page renders loaded pending items', (tester) async {
    final workspaceRepository = _FakeWorkspaceRepository();
    final kitchenRepository = _FakeKitchenRepository();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authNotifierProvider.overrideWith(
            () => _FixedAuthNotifier(
              const AuthState(
                status: AuthStatus.authenticated,
                accountId: 8,
                accountType: AccountType.storeUser,
              ),
            ),
          ),
          loadStoreAccessContextUseCaseProvider.overrideWithValue(
            LoadStoreAccessContextUseCase(workspaceRepository),
          ),
          loadCachedStoreAccessContextUseCaseProvider.overrideWithValue(
            LoadCachedStoreAccessContextUseCase(workspaceRepository),
          ),
          saveStoreAccessContextCacheUseCaseProvider.overrideWithValue(
            SaveStoreAccessContextCacheUseCase(workspaceRepository),
          ),
          clearStoreAccessContextCacheUseCaseProvider.overrideWithValue(
            ClearStoreAccessContextCacheUseCase(workspaceRepository),
          ),
          loadMyStoresUseCaseProvider.overrideWithValue(
            LoadMyStoresUseCase(workspaceRepository),
          ),
          loadLastActiveStoreUseCaseProvider.overrideWithValue(
            LoadLastActiveStoreUseCase(_FakeLastActiveStoreStorage()),
          ),
          saveLastActiveStoreUseCaseProvider.overrideWithValue(
            SaveLastActiveStoreUseCase(_FakeLastActiveStoreStorage()),
          ),
          clearLastActiveStoreUseCaseProvider.overrideWithValue(
            ClearLastActiveStoreUseCase(_FakeLastActiveStoreStorage()),
          ),
          loadKitchenItemsUseCaseProvider.overrideWithValue(
            LoadKitchenItemsUseCase(kitchenRepository),
          ),
          updateKitchenItemStatusUseCaseProvider.overrideWithValue(
            UpdateKitchenItemStatusUseCase(kitchenRepository),
          ),
          cancelKitchenItemUseCaseProvider.overrideWithValue(
            CancelKitchenItemUseCase(kitchenRepository),
          ),
          bulkUpdateKitchenItemsUseCaseProvider.overrideWithValue(
            BulkUpdateKitchenItemsUseCase(kitchenRepository),
          ),
          bulkCancelKitchenItemsUseCaseProvider.overrideWithValue(
            BulkCancelKitchenItemsUseCase(kitchenRepository),
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          home: const KitchenPage(storeId: 5),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('7 up - Mặc định'), findsOneWidget);
    expect(find.text('Bàn 3'), findsOneWidget);
    expect(find.text('1 order'), findsOneWidget);
    expect(find.text('Theo món'), findsNothing);
    expect(find.text('Theo phòng/bàn'), findsOneWidget);

    await tester.tap(find.text('Theo phòng/bàn'));
    await tester.pumpAndSettle();

    expect(find.text('HOÀN THÀNH CẢ BÀN'), findsOneWidget);
    expect(
      kitchenRepository.lastFilter?.status,
      KitchenOrderItemStatus.pending,
    );
    expect(kitchenRepository.lastFilter?.orderedFrom, isNotNull);
    expect(kitchenRepository.lastFilter?.orderedTo, isNotNull);
  });
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
  @override
  Future<List<Store>> loadMyStores() async {
    return const [_store];
  }

  @override
  Future<Store> createStore({
    required String storeName,
    required String phone,
    required String address,
  }) async {
    return _store;
  }

  @override
  Future<Store> loadStoreById(int storeId) async {
    return _store;
  }

  @override
  Future<List<StorePermission>> loadMyStorePermissions(int storeId) async {
    return const [
      StorePermission(permissionId: 105, code: AppPermissionCodes.kitchenAll),
    ];
  }

  @override
  Future<StoreAccessContext> loadStoreAccessContext(int storeId) async {
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
    return null;
  }

  @override
  Future<void> saveStoreAccessContextCache({
    required int accountId,
    required StoreAccessContext context,
  }) async {}

  @override
  Future<void> clearStoreAccessContextCache({
    required int accountId,
    required int storeId,
  }) async {}

  @override
  Future<void> clearAllStoreAccessContextCache() async {}
}

class _FakeKitchenRepository implements KitchenRepository {
  KitchenItemFilter? lastFilter;

  @override
  Future<List<KitchenOrderItem>> loadItems({
    required int storeId,
    KitchenItemFilter filter = const KitchenItemFilter(),
  }) async {
    lastFilter = filter;
    return [_pendingItem];
  }

  @override
  Future<KitchenOrderItem> updateItemStatus({
    required int orderItemId,
    required KitchenOrderItemStatus status,
  }) async {
    return _pendingItem;
  }

  @override
  Future<KitchenOrderItem> cancelItem(int orderItemId) async {
    return _pendingItem;
  }

  @override
  Future<KitchenBulkUpdateResult> bulkUpdateStatus({
    required List<int> itemIds,
    required KitchenOrderItemStatus status,
  }) async {
    return KitchenBulkUpdateResult(
      updatedItems: [_pendingItem],
      failedItems: const [],
    );
  }

  @override
  Future<KitchenBulkUpdateResult> bulkCancel(List<int> itemIds) async {
    return KitchenBulkUpdateResult(
      updatedItems: [_pendingItem],
      failedItems: const [],
    );
  }
}

class _FakeLastActiveStoreStorage implements LastActiveStoreStorage {
  @override
  Future<int?> getLastActiveStoreId() async {
    return 5;
  }

  @override
  Future<void> saveLastActiveStoreId(int storeId) async {}

  @override
  Future<void> clearLastActiveStoreId() async {}
}

const _store = Store(
  id: 5,
  ownerAccountId: 8,
  storeName: 'Buffet Cửu Vân Long Premium - Saigon Marina IFC',
  phone: '0900000000',
  address: 'Hồ Chí Minh',
  status: StoreStatus.active,
  isDeleted: false,
);

final _pendingItem = KitchenOrderItem(
  orderItemId: 123,
  orderId: 64,
  storeId: 5,
  tableSessionId: 28,
  tableId: 3,
  tableName: 'Bàn 3',
  productId: 15,
  productName: '7 up',
  variantId: 30,
  variantName: 'Mặc định',
  note: null,
  status: KitchenOrderItemStatus.pending,
  orderedAt: DateTime.utc(2026, 6, 22, 15, 17, 19),
  updatedAt: DateTime.utc(2026, 6, 22, 15, 17, 19),
  toppings: const [],
);
