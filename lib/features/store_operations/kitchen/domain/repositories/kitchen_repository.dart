import '../entities/kitchen_order_item.dart';

abstract class KitchenRepository {
  Future<List<KitchenOrderItem>> loadItems({
    required int storeId,
    KitchenItemFilter filter = const KitchenItemFilter(),
  });

  Future<KitchenOrderItem> updateItemStatus({
    required int orderItemId,
    required KitchenOrderItemStatus status,
  });

  Future<KitchenOrderItem> cancelItem(int orderItemId);

  Future<KitchenBulkUpdateResult> bulkUpdateStatus({
    required List<int> itemIds,
    required KitchenOrderItemStatus status,
  });

  Future<KitchenBulkUpdateResult> bulkCancel(List<int> itemIds);
}
