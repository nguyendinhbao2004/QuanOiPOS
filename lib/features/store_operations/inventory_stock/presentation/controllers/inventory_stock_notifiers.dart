import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/inventory_stock.dart';
import '../providers/inventory_stock_providers.dart';
import 'inventory_stock_state.dart';

class InventoryStockListNotifier
    extends
        AutoDisposeFamilyNotifier<
          InventoryStockListState,
          InventoryStockListArgs
        > {
  late InventoryStockListArgs _args;

  @override
  InventoryStockListState build(InventoryStockListArgs arg) {
    _args = arg;
    Future.microtask(load);
    return const InventoryStockListState.initial();
  }

  Future<void> load() async {
    state = state.copyWith(
      status: InventoryStockLoadStatus.loading,
      clearError: true,
    );
    try {
      final items = await ref.read(loadInventoryStockItemsUseCaseProvider)(
        storeId: _args.storeId,
        type: state.selectedType,
        status: state.selectedStatus,
      );
      state = state.copyWith(
        status: InventoryStockLoadStatus.ready,
        items: items,
      );
    } catch (error) {
      state = state.copyWith(
        status: InventoryStockLoadStatus.error,
        errorMessage: error.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  Future<void> setType(InventoryStockItemType type) async {
    if (state.selectedType == type) return;
    state = state.copyWith(selectedType: type, searchQuery: '');
    await load();
  }

  Future<void> setStatus(InventoryStockStatus status) async {
    if (state.selectedStatus == status) return;
    state = state.copyWith(selectedStatus: status);
    await load();
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }
}

class InventoryStockListArgs {
  final int storeId;

  const InventoryStockListArgs({required this.storeId});

  @override
  bool operator ==(Object other) =>
      other is InventoryStockListArgs && other.storeId == storeId;

  @override
  int get hashCode => storeId.hashCode;
}

class InventoryMovementNotifier
    extends
        AutoDisposeFamilyNotifier<
          InventoryMovementState,
          InventoryMovementArgs
        > {
  late InventoryMovementArgs _args;

  @override
  InventoryMovementState build(InventoryMovementArgs arg) {
    _args = arg;
    Future.microtask(load);
    return const InventoryMovementState.initial();
  }

  Future<void> load() async {
    state = state.copyWith(
      status: InventoryStockLoadStatus.loading,
      clearError: true,
    );
    try {
      final now = DateTime.now();
      final movements = await ref.read(loadInventoryMovementsUseCaseProvider)(
        type: _args.type,
        itemId: _args.itemId,
        from: now.subtract(const Duration(days: 30)),
        to: now,
      );
      state = state.copyWith(
        status: InventoryStockLoadStatus.ready,
        movements: movements,
      );
    } catch (error) {
      state = state.copyWith(
        status: InventoryStockLoadStatus.error,
        errorMessage: error.toString().replaceFirst('Exception: ', ''),
      );
    }
  }
}

class InventoryMovementArgs {
  final InventoryStockItemType type;
  final int itemId;

  const InventoryMovementArgs({required this.type, required this.itemId});

  @override
  bool operator ==(Object other) =>
      other is InventoryMovementArgs &&
      other.type == type &&
      other.itemId == itemId;

  @override
  int get hashCode => Object.hash(type, itemId);
}
