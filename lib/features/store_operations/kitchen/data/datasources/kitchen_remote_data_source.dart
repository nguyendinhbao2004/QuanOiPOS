import '../../../../../core/network/dio/dio_client.dart';
import '../../domain/entities/kitchen_order_item.dart';
import '../models/kitchen_order_item_model.dart';

class KitchenRemoteDataSource {
  final DioClient _dioClient;

  const KitchenRemoteDataSource(this._dioClient);

  Future<List<KitchenOrderItemModel>> getItems({
    required int storeId,
    KitchenItemFilter filter = const KitchenItemFilter(),
  }) async {
    final response = await _dioClient.getResponse<List<KitchenOrderItemModel>>(
      '/kitchen/stores/$storeId/items',
      queryParameters: _toQueryParameters(filter),
      dataFromJson: KitchenOrderItemModel.listFromJson,
    );
    if (!response.succeeded || response.data == null) {
      _throwFailure(
        response.message,
        response.errors,
        'Không thể tải danh sách món bếp',
      );
    }
    return response.data!;
  }

  Future<KitchenOrderItemModel> updateItemStatus({
    required int orderItemId,
    required KitchenOrderItemStatus status,
  }) async {
    final response = await _dioClient.putResponse<KitchenOrderItemModel>(
      '/kitchen/items/$orderItemId/status',
      data: {'status': status.value},
      dataFromJson: KitchenOrderItemModel.fromJson,
    );
    if (!response.succeeded || response.data == null) {
      _throwFailure(
        response.message,
        response.errors,
        'Không thể cập nhật trạng thái món',
      );
    }
    return response.data!;
  }

  Future<KitchenOrderItemModel> cancelItem(int orderItemId) async {
    final response = await _dioClient.putResponse<KitchenOrderItemModel>(
      '/kitchen/items/$orderItemId/cancel',
      dataFromJson: KitchenOrderItemModel.fromJson,
    );
    if (!response.succeeded || response.data == null) {
      _throwFailure(response.message, response.errors, 'Không thể hủy món');
    }
    return response.data!;
  }

  Future<KitchenBulkUpdateResultModel> bulkUpdateStatus({
    required List<int> itemIds,
    required KitchenOrderItemStatus status,
  }) async {
    final response = await _dioClient.putResponse<KitchenBulkUpdateResultModel>(
      '/kitchen/items/bulk-status',
      data: {'itemIds': itemIds, 'status': status.value},
      dataFromJson: KitchenBulkUpdateResultModel.fromJson,
    );
    if (!response.succeeded || response.data == null) {
      _throwFailure(
        response.message,
        response.errors,
        'Không thể cập nhật nhiều món',
      );
    }
    return response.data!;
  }

  Future<KitchenBulkUpdateResultModel> bulkCancel(List<int> itemIds) async {
    final response = await _dioClient.putResponse<KitchenBulkUpdateResultModel>(
      '/kitchen/items/bulk-cancel',
      data: {'itemIds': itemIds},
      dataFromJson: KitchenBulkUpdateResultModel.fromJson,
    );
    if (!response.succeeded || response.data == null) {
      _throwFailure(response.message, response.errors, 'Không thể hủy nhiều món');
    }
    return response.data!;
  }

  Map<String, dynamic> _toQueryParameters(KitchenItemFilter filter) {
    return {
      if (filter.productId != null) 'productId': filter.productId,
      if (filter.tableId != null) 'tableId': filter.tableId,
      if (filter.tableSessionId != null)
        'tableSessionId': filter.tableSessionId,
      if (filter.status != null) 'status': filter.status!.value,
      if (filter.orderedFrom != null)
        'orderedFrom': filter.orderedFrom!.toUtc().toIso8601String(),
      if (filter.orderedTo != null)
        'orderedTo': filter.orderedTo!.toUtc().toIso8601String(),
    };
  }

  Never _throwFailure(String? message, List<String> errors, String fallback) {
    final cleanMessage = message?.trim();
    throw Exception(
      cleanMessage?.isNotEmpty == true
          ? cleanMessage
          : (errors.isNotEmpty ? errors.first : fallback),
    );
  }
}
