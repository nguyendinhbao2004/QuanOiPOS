import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quan_oi/core/constants/app_permission_codes.dart';
import 'package:quan_oi/features/store_operations/inventory_stock/domain/entities/inventory_stock.dart';
import 'package:quan_oi/features/store_operations/inventory_stock/domain/repositories/inventory_stock_repository.dart';
import 'package:quan_oi/features/store_operations/inventory_stock/domain/usecases/inventory_stock_use_cases.dart';
import 'package:quan_oi/features/store_operations/inventory_stock/presentation/providers/inventory_stock_providers.dart';
import 'package:quan_oi/features/store_operations/presentation/pages/store_inventory_stock_page.dart';
import 'package:quan_oi/features/workspace_context/domain/entities/store.dart';
import 'package:quan_oi/features/workspace_context/domain/entities/store_access_context.dart';
import 'package:quan_oi/features/workspace_context/domain/entities/store_permission.dart';
import 'package:quan_oi/features/workspace_context/domain/repositories/workspace_repository.dart';
import 'package:quan_oi/features/workspace_context/domain/usecases/load_store_access_context_use_case.dart';
import 'package:quan_oi/features/workspace_context/presentation/providers/workspace_context_providers.dart';

void main() {
  testWidgets('without inventory view permission skips stock API', (
    tester,
  ) async {
    final stockRepository = _FakeInventoryStockRepository();
    await _pumpPage(
      tester,
      stockRepository: stockRepository,
      permissions: const [],
    );

    await tester.pumpAndSettle();

    expect(find.text('Bạn chưa có quyền xem tồn kho'), findsOneWidget);
    expect(stockRepository.loadItemsCallCount, 0);
  });

  testWidgets('renders stock list and opens movement bottom sheet', (
    tester,
  ) async {
    final stockRepository = _FakeInventoryStockRepository();
    await _pumpPage(
      tester,
      stockRepository: stockRepository,
      permissions: const [AppPermissionCodes.inventoryView],
    );

    await tester.pumpAndSettle();

    expect(find.text('Coca'), findsOneWidget);
    expect(stockRepository.loadItemsCallCount, 1);

    await tester.tap(find.text('Coca'));
    await tester.pumpAndSettle();

    expect(find.text('Lịch sử biến động 30 ngày gần nhất'), findsOneWidget);
    expect(find.text('Purchase'), findsOneWidget);
    expect(stockRepository.loadMovementsCallCount, 1);
  });
}

Future<void> _pumpPage(
  WidgetTester tester, {
  required _FakeInventoryStockRepository stockRepository,
  required List<String> permissions,
}) async {
  final workspaceRepository = _FakeWorkspaceRepository(permissions);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        loadStoreAccessContextUseCaseProvider.overrideWithValue(
          LoadStoreAccessContextUseCase(workspaceRepository),
        ),
        loadInventoryStockItemsUseCaseProvider.overrideWithValue(
          LoadInventoryStockItemsUseCase(stockRepository),
        ),
        loadInventoryMovementsUseCaseProvider.overrideWithValue(
          LoadInventoryMovementsUseCase(stockRepository),
        ),
      ],
      child: const MaterialApp(home: StoreInventoryStockPage(storeId: 5)),
    ),
  );
}

class _FakeWorkspaceRepository implements WorkspaceRepository {
  final List<String> permissions;

  const _FakeWorkspaceRepository(this.permissions);

  @override
  Future<StoreAccessContext> loadStoreAccessContext(int storeId) async {
    return StoreAccessContext(
      store: Store(
        id: storeId,
        ownerAccountId: 1,
        storeName: 'Quán Ơi',
        phone: '0900000000',
        address: 'Test',
        status: StoreStatus.active,
        isDeleted: false,
      ),
      permissions: [
        for (var i = 0; i < permissions.length; i++)
          StorePermission(permissionId: i + 1, code: permissions[i]),
      ],
    );
  }

  @override
  Future<void> clearAllStoreAccessContextCache() {
    throw UnimplementedError();
  }

  @override
  Future<void> clearStoreAccessContextCache({
    required int accountId,
    required int storeId,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<Store> createStore({
    required String storeName,
    required String phone,
    required String address,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<StoreAccessContext?> loadCachedStoreAccessContext({
    required int accountId,
    required int storeId,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<List<Store>> loadMyStores() {
    throw UnimplementedError();
  }

  @override
  Future<List<StorePermission>> loadMyStorePermissions(int storeId) {
    throw UnimplementedError();
  }

  @override
  Future<Store> loadStoreById(int storeId) {
    throw UnimplementedError();
  }

  @override
  Future<void> saveStoreAccessContextCache({
    required int accountId,
    required StoreAccessContext context,
  }) {
    throw UnimplementedError();
  }
}

class _FakeInventoryStockRepository implements InventoryStockRepository {
  int loadItemsCallCount = 0;
  int loadMovementsCallCount = 0;

  @override
  Future<List<InventoryStockItem>> loadItems({
    required int storeId,
    required InventoryStockItemType type,
    required InventoryStockStatus status,
  }) async {
    loadItemsCallCount += 1;
    return const [
      InventoryStockItem(
        type: InventoryStockItemType.product,
        id: 20,
        storeId: 5,
        name: 'Coca',
        unit: 'sp',
        quantity: 4,
        minimumStock: 2,
        averageUnitCost: 7000,
        lastImportUnitCost: 7500,
        isTrackInventory: true,
        inventoryDeductionMode: 'ProductOnly',
        isLowStock: false,
        isOutOfStock: false,
      ),
    ];
  }

  @override
  Future<List<InventoryMovement>> loadMovements({
    required InventoryStockItemType type,
    required int itemId,
    DateTime? from,
    DateTime? to,
  }) async {
    loadMovementsCallCount += 1;
    return [
      InventoryMovement(
        id: 1,
        ingredientId: null,
        productId: itemId,
        type: 'Import',
        reason: 'Purchase',
        quantity: 4,
        requestedQuantity: 4,
        shortageQuantity: 0,
        unitCost: 7000,
        totalCost: 28000,
        orderId: null,
        orderItemId: null,
        note: null,
        destinationName: null,
        occurredAt: DateTime(2026, 6, 25),
      ),
    ];
  }
}
