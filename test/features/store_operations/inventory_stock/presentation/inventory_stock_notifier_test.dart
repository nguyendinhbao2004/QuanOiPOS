import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quan_oi/features/store_operations/inventory_stock/domain/entities/inventory_stock.dart';
import 'package:quan_oi/features/store_operations/inventory_stock/domain/repositories/inventory_stock_repository.dart';
import 'package:quan_oi/features/store_operations/inventory_stock/domain/usecases/inventory_stock_use_cases.dart';
import 'package:quan_oi/features/store_operations/inventory_stock/presentation/controllers/inventory_stock_notifiers.dart';
import 'package:quan_oi/features/store_operations/inventory_stock/presentation/controllers/inventory_stock_state.dart';
import 'package:quan_oi/features/store_operations/inventory_stock/presentation/providers/inventory_stock_providers.dart';

void main() {
  test('initial load defaults to product all status', () async {
    final repository = _FakeInventoryStockRepository();
    final container = _container(repository);
    addTearDown(container.dispose);

    final args = InventoryStockListArgs(storeId: 5);
    final subscription = container.listen(
      inventoryStockListNotifierProvider(args),
      (_, _) {},
    );
    addTearDown(subscription.close);
    await _pump();

    final state = container.read(inventoryStockListNotifierProvider(args));

    expect(state.status, InventoryStockLoadStatus.ready);
    expect(
      repository.loadItemsCalls.single.type,
      InventoryStockItemType.product,
    );
    expect(repository.loadItemsCalls.single.status, InventoryStockStatus.all);
    expect(state.visibleItems.map((item) => item.name), ['Coca', 'Number 1']);
  });

  test('changing type and status reloads list', () async {
    final repository = _FakeInventoryStockRepository();
    final container = _container(repository);
    addTearDown(container.dispose);

    final args = InventoryStockListArgs(storeId: 5);
    final subscription = container.listen(
      inventoryStockListNotifierProvider(args),
      (_, _) {},
    );
    addTearDown(subscription.close);
    final notifier = container.read(
      inventoryStockListNotifierProvider(args).notifier,
    );
    await _pump();

    await notifier.setType(InventoryStockItemType.ingredient);
    await notifier.setStatus(InventoryStockStatus.low);

    expect(repository.loadItemsCalls.map((call) => call.type), [
      InventoryStockItemType.product,
      InventoryStockItemType.ingredient,
      InventoryStockItemType.ingredient,
    ]);
    expect(repository.loadItemsCalls.last.status, InventoryStockStatus.low);
  });

  test('search filters locally without reloading API', () async {
    final repository = _FakeInventoryStockRepository();
    final container = _container(repository);
    addTearDown(container.dispose);

    final args = InventoryStockListArgs(storeId: 5);
    final subscription = container.listen(
      inventoryStockListNotifierProvider(args),
      (_, _) {},
    );
    addTearDown(subscription.close);
    final notifier = container.read(
      inventoryStockListNotifierProvider(args).notifier,
    );
    await _pump();

    notifier.setSearchQuery('number');
    final state = container.read(inventoryStockListNotifierProvider(args));

    expect(state.visibleItems.map((item) => item.name), ['Number 1']);
    expect(repository.loadItemsCalls, hasLength(1));
  });

  test('movement notifier requests default 30 day range', () async {
    final repository = _FakeInventoryStockRepository();
    final container = _container(repository);
    addTearDown(container.dispose);

    final args = InventoryMovementArgs(
      type: InventoryStockItemType.ingredient,
      itemId: 10,
    );
    final subscription = container.listen(
      inventoryMovementNotifierProvider(args),
      (_, _) {},
    );
    addTearDown(subscription.close);
    await _pump();

    final state = container.read(inventoryMovementNotifierProvider(args));
    final call = repository.loadMovementCalls.single;

    expect(state.status, InventoryStockLoadStatus.ready);
    expect(call.type, InventoryStockItemType.ingredient);
    expect(call.itemId, 10);
    expect(call.from, isNotNull);
    expect(call.to, isNotNull);
    expect(call.to!.difference(call.from!).inDays, 30);
  });
}

ProviderContainer _container(_FakeInventoryStockRepository repository) {
  return ProviderContainer(
    overrides: [
      loadInventoryStockItemsUseCaseProvider.overrideWithValue(
        LoadInventoryStockItemsUseCase(repository),
      ),
      loadInventoryMovementsUseCaseProvider.overrideWithValue(
        LoadInventoryMovementsUseCase(repository),
      ),
    ],
  );
}

Future<void> _pump() => Future<void>.delayed(const Duration(milliseconds: 10));

class _FakeInventoryStockRepository implements InventoryStockRepository {
  final loadItemsCalls = <_LoadItemsCall>[];
  final loadMovementCalls = <_LoadMovementCall>[];

  @override
  Future<List<InventoryStockItem>> loadItems({
    required int storeId,
    required InventoryStockItemType type,
    required InventoryStockStatus status,
  }) async {
    loadItemsCalls.add(_LoadItemsCall(storeId, type, status));
    return type == InventoryStockItemType.product
        ? const [
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
            InventoryStockItem(
              type: InventoryStockItemType.product,
              id: 21,
              storeId: 5,
              name: 'Number 1',
              unit: 'sp',
              quantity: 1,
              minimumStock: 3,
              averageUnitCost: 6000,
              lastImportUnitCost: 6500,
              isTrackInventory: true,
              inventoryDeductionMode: 'ProductOnly',
              isLowStock: true,
              isOutOfStock: false,
            ),
          ]
        : const [
            InventoryStockItem(
              type: InventoryStockItemType.ingredient,
              id: 10,
              storeId: 5,
              name: 'Đường',
              unit: 'g',
              quantity: 1000,
              minimumStock: 1200,
              averageUnitCost: 20,
              lastImportUnitCost: 22,
              isTrackInventory: true,
              inventoryDeductionMode: null,
              isLowStock: true,
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
    loadMovementCalls.add(_LoadMovementCall(type, itemId, from, to));
    return [
      InventoryMovement(
        id: 1,
        ingredientId: type == InventoryStockItemType.ingredient ? itemId : null,
        productId: type == InventoryStockItemType.product ? itemId : null,
        type: 'Import',
        reason: 'Purchase',
        quantity: 5,
        requestedQuantity: 5,
        shortageQuantity: 0,
        unitCost: 7000,
        totalCost: 35000,
        orderId: null,
        orderItemId: null,
        note: null,
        destinationName: null,
        occurredAt: DateTime(2026, 6, 25),
      ),
    ];
  }
}

class _LoadItemsCall {
  final int storeId;
  final InventoryStockItemType type;
  final InventoryStockStatus status;

  const _LoadItemsCall(this.storeId, this.type, this.status);
}

class _LoadMovementCall {
  final InventoryStockItemType type;
  final int itemId;
  final DateTime? from;
  final DateTime? to;

  const _LoadMovementCall(this.type, this.itemId, this.from, this.to);
}
