import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/kitchen_order_item.dart';
import '../providers/kitchen_providers.dart';
import 'kitchen_state.dart';

class KitchenNotifier
    extends AutoDisposeFamilyNotifier<KitchenState, KitchenAccess> {
  late KitchenAccess _access;
  bool _loading = false;

  @override
  KitchenState build(KitchenAccess arg) {
    _access = arg;
    Future.microtask(load);
    return const KitchenState.initial().copyWith(
      filter: todayVietnamKitchenFilter(),
    );
  }

  Future<void> load({bool refresh = false}) async {
    if (_loading) return;
    if (!_access.canManageKitchen) {
      state = state.copyWith(
        status: KitchenLoadStatus.forbidden,
        errorMessage: 'Bạn chưa có quyền truy cập màn hình bếp',
      );
      return;
    }

    _loading = true;
    state = state.copyWith(
      status: refresh && state.status == KitchenLoadStatus.ready
          ? state.status
          : KitchenLoadStatus.loading,
      isRefreshing: refresh,
      clearError: true,
    );

    try {
      final items = await ref.read(loadKitchenItemsUseCaseProvider)(
        storeId: _access.storeId,
        filter: state.filter,
      );
      state = state.copyWith(
        status: KitchenLoadStatus.ready,
        items: items,
        selectedItemIds: state.selectedItemIds
            .where((id) => items.any((item) => item.orderItemId == id))
            .toSet(),
        clearError: true,
      );
    } catch (error) {
      state = state.copyWith(
        status: KitchenLoadStatus.error,
        errorMessage: _cleanError(error),
      );
    } finally {
      _loading = false;
      state = state.copyWith(isRefreshing: false);
    }
  }

  void setMode(KitchenBoardMode mode) {
    state = state.copyWith(mode: mode);
  }

  Future<void> setStatusFilter(KitchenOrderItemStatus status) async {
    state = state.copyWith(
      filter: state.filter.copyWith(status: status),
      selectedItemIds: const {},
    );
    await load();
  }

  void toggleSelection(int orderItemId) {
    final selected = {...state.selectedItemIds};
    if (!selected.add(orderItemId)) {
      selected.remove(orderItemId);
    }
    state = state.copyWith(selectedItemIds: selected);
  }

  void clearSelection() {
    state = state.copyWith(selectedItemIds: const {});
  }

  Future<KitchenBulkUpdateResult?> completeSelected() {
    return _bulkUpdate(KitchenOrderItemStatus.ready);
  }

  Future<KitchenBulkUpdateResult?> prepareSelected() {
    return _bulkUpdate(KitchenOrderItemStatus.preparing);
  }

  Future<KitchenBulkUpdateResult?> cancelSelected() async {
    final ids = state.selectedItemIds.toList();
    if (ids.isEmpty || state.isBulkProcessing) return null;

    state = state.copyWith(isBulkProcessing: true, clearError: true);
    try {
      final result = await ref.read(bulkCancelKitchenItemsUseCaseProvider)(ids);
      _replaceUpdatedItems(result.updatedItems);
      _clearSuccessfulSelection(result.updatedItems);
      return result;
    } catch (error) {
      state = state.copyWith(errorMessage: _cleanError(error));
      rethrow;
    } finally {
      state = state.copyWith(isBulkProcessing: false);
    }
  }

  Future<KitchenOrderItem> updateItemStatus({
    required int orderItemId,
    required KitchenOrderItemStatus status,
  }) async {
    if (!_access.canManageKitchen) {
      throw Exception('Bạn chưa có quyền cập nhật món bếp');
    }

    _markItemProcessing(orderItemId, true);
    try {
      final updated = await ref.read(updateKitchenItemStatusUseCaseProvider)(
        orderItemId: orderItemId,
        status: status,
      );
      _replaceUpdatedItems([updated]);
      return updated;
    } catch (error) {
      state = state.copyWith(errorMessage: _cleanError(error));
      rethrow;
    } finally {
      _markItemProcessing(orderItemId, false);
    }
  }

  Future<KitchenOrderItem> cancelItem(int orderItemId) async {
    if (!_access.canManageKitchen) {
      throw Exception('Bạn chưa có quyền hủy món bếp');
    }

    _markItemProcessing(orderItemId, true);
    try {
      final updated = await ref.read(cancelKitchenItemUseCaseProvider)(
        orderItemId,
      );
      _replaceUpdatedItems([updated]);
      return updated;
    } catch (error) {
      state = state.copyWith(errorMessage: _cleanError(error));
      rethrow;
    } finally {
      _markItemProcessing(orderItemId, false);
    }
  }

  Future<KitchenBulkUpdateResult?> _bulkUpdate(
    KitchenOrderItemStatus status,
  ) async {
    final ids = state.selectedItemIds.toList();
    if (ids.isEmpty || state.isBulkProcessing) return null;

    state = state.copyWith(isBulkProcessing: true, clearError: true);
    try {
      final result = await ref.read(bulkUpdateKitchenItemsUseCaseProvider)(
        itemIds: ids,
        status: status,
      );
      _replaceUpdatedItems(result.updatedItems);
      _clearSuccessfulSelection(result.updatedItems);
      return result;
    } catch (error) {
      state = state.copyWith(errorMessage: _cleanError(error));
      rethrow;
    } finally {
      state = state.copyWith(isBulkProcessing: false);
    }
  }

  void _replaceUpdatedItems(List<KitchenOrderItem> updatedItems) {
    if (updatedItems.isEmpty) return;
    final updatedById = {
      for (final item in updatedItems) item.orderItemId: item,
    };
    final nextItems = [
      for (final item in state.items)
        if (updatedById.containsKey(item.orderItemId))
          updatedById[item.orderItemId]!
        else
          item,
    ];
    state = state.copyWith(items: nextItems, clearError: true);
  }

  void _clearSuccessfulSelection(List<KitchenOrderItem> updatedItems) {
    final updatedIds = updatedItems.map((item) => item.orderItemId).toSet();
    state = state.copyWith(
      selectedItemIds: state.selectedItemIds
          .where((id) => !updatedIds.contains(id))
          .toSet(),
    );
  }

  void _markItemProcessing(int orderItemId, bool value) {
    final ids = {...state.processingItemIds};
    if (value) {
      ids.add(orderItemId);
    } else {
      ids.remove(orderItemId);
    }
    state = state.copyWith(processingItemIds: ids);
  }
}

String _cleanError(Object error) {
  return error.toString().replaceFirst('Exception: ', '');
}
