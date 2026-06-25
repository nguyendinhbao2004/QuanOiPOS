import 'package:dio/dio.dart';

import '../../../../../core/network/dio/dio_client.dart';
import '../../domain/entities/inventory_stock.dart';
import '../models/inventory_stock_models.dart';

class InventoryStockRemoteDataSource {
  final DioClient _client;

  InventoryStockRemoteDataSource(this._client);

  Future<List<InventoryStockItemModel>> getItems({
    required int storeId,
    required InventoryStockItemType type,
    required InventoryStockStatus status,
  }) {
    final path = type == InventoryStockItemType.product
        ? '/inventory/products'
        : '/inventory/ingredients';
    return _get<List<InventoryStockItemModel>>(
      path,
      query: {'storeId': storeId, 'status': status.apiValue},
      parser: (json) => InventoryStockItemModel.listFromJson(json, type),
      fallback: type == InventoryStockItemType.product
          ? 'Không thể tải tồn kho sản phẩm'
          : 'Không thể tải tồn kho nguyên liệu',
    );
  }

  Future<List<InventoryMovementModel>> getMovements({
    required InventoryStockItemType type,
    required int itemId,
    DateTime? from,
    DateTime? to,
  }) {
    final path = type == InventoryStockItemType.product
        ? '/inventory/products/$itemId/movements'
        : '/inventory/ingredients/$itemId/movements';
    return _get<List<InventoryMovementModel>>(
      path,
      query: {
        if (from != null) 'from': from.toUtc().toIso8601String(),
        if (to != null) 'to': to.toUtc().toIso8601String(),
      },
      parser: InventoryMovementModel.listFromJson,
      fallback: 'Không thể tải lịch sử biến động tồn kho',
    );
  }

  Future<T> _get<T>(
    String path, {
    Map<String, dynamic>? query,
    required T Function(Object?) parser,
    required String fallback,
  }) async {
    try {
      final response = await _client.dio.get<dynamic>(
        path,
        queryParameters: query,
      );
      return _unwrap(response.data, parser, fallback);
    } on DioException catch (error) {
      throw Exception(_message(error, fallback));
    }
  }

  T _unwrap<T>(Object? raw, T Function(Object?) parser, String fallback) {
    if (raw is Map) {
      final map = raw.map((key, value) => MapEntry(key.toString(), value));
      if (map['succeeded'] == false) {
        throw Exception((map['message'] ?? fallback).toString());
      }
      return parser(map.containsKey('data') ? map['data'] : map);
    }
    return parser(raw);
  }

  String _message(DioException error, String fallback) {
    final data = error.response?.data;
    if (data is Map) {
      final map = data.map((key, value) => MapEntry(key.toString(), value));
      final errors = map['errors'];
      if (errors is List && errors.isNotEmpty) return errors.first.toString();
      final message = map['message']?.toString().trim();
      if (message != null && message.isNotEmpty) return message;
    }
    return fallback;
  }
}
