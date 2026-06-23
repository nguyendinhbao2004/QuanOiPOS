import 'package:dio/dio.dart';
import '../../../../../core/network/dio/dio_client.dart';
import '../../domain/entities/inventory_document.dart';
import '../models/inventory_document_models.dart';

class InventoryDocumentRemoteDataSource {
  final DioClient _client;
  InventoryDocumentRemoteDataSource(this._client);

  Future<InventoryDocumentPageModel> getImports({
    required int storeId,
    InventoryDocumentStatus? status,
    DateTime? from,
    DateTime? to,
    required int pageIndex,
    required int pageSize,
  }) => _get(
    '/inventory/documents',
    query: {
      'storeId': storeId,
      'type': 'Import',
      if (status != null) 'status': status.apiValue,
      if (from != null) 'from': from.toUtc().toIso8601String(),
      if (to != null) 'to': to.toUtc().toIso8601String(),
      'pageIndex': pageIndex,
      'pageSize': pageSize,
    },
    parser: InventoryDocumentPageModel.fromJson,
    fallback: 'Không thể tải sổ nhập hàng',
  );
  Future<InventoryDocumentModel> getDocument(int id) => _get(
    '/inventory/documents/$id',
    parser: InventoryDocumentModel.fromJson,
    fallback: 'Không thể tải chi tiết phiếu nhập',
  );
  Future<List<InventoryVendorModel>> getVendors(
    int storeId, {
    String? keyword,
  }) => _get(
    '/vendors',
    query: {
      'storeId': storeId,
      if (keyword != null && keyword.isNotEmpty) 'keyword': keyword,
    },
    parser: InventoryVendorModel.listFromJson,
    fallback: 'Không thể tải nhà cung cấp',
  );

  Future<InventoryVendorModel> createVendor(
    CreateInventoryVendorRequestModel request,
  ) async {
    try {
      final response = await _client.dio.post<dynamic>(
        '/vendors',
        data: request.toJson(),
      );
      return _unwrap(
        response.data,
        InventoryVendorModel.fromJson,
        'Không thể tạo nhà cung cấp',
      );
    } on DioException catch (error) {
      throw Exception(_message(error, 'Không thể tạo nhà cung cấp'));
    }
  }

  Future<List<InventoryItemModel>> getItems(int storeId) async {
    final results = await Future.wait([
      _get<List<Object?>>(
        '/inventory/ingredients',
        query: {'storeId': storeId, 'status': 'all'},
        parser: (json) => json is List ? List<Object?>.from(json) : const [],
        fallback: 'Không thể tải nguyên liệu',
      ),
      _get<List<Object?>>(
        '/inventory/products',
        query: {'storeId': storeId, 'status': 'all'},
        parser: (json) => json is List ? List<Object?>.from(json) : const [],
        fallback: 'Không thể tải sản phẩm',
      ),
    ]);
    return [
      ...results[0].map(
        (item) => InventoryItemModel.fromJson(
          item,
          InventoryDocumentItemType.ingredient,
        ),
      ),
      ...results[1].map(
        (item) => InventoryItemModel.fromJson(
          item,
          InventoryDocumentItemType.product,
        ),
      ),
    ];
  }

  Future<InventoryDocumentModel> create(
    InventoryDocumentRequestModel request,
  ) => _post(
    '/inventory/documents',
    request.toJson(),
    fallback: 'Không thể tạo phiếu nhập',
  );
  Future<InventoryDocumentModel> update(
    int id,
    InventoryDocumentRequestModel request,
  ) => _put(
    '/inventory/documents/$id',
    request.toJson(),
    fallback: 'Không thể cập nhật phiếu nhập',
  );
  Future<InventoryDocumentModel> complete(int id) async {
    try {
      final response = await _client.dio.post<dynamic>(
        '/inventory/documents/$id/complete',
      );
      return _unwrap(
        response.data,
        InventoryDocumentModel.fromJson,
        'Không thể hoàn thành phiếu nhập',
      );
    } on DioException catch (error) {
      final data = error.response?.data;
      if (data is Map) {
        final map = data.map((key, value) => MapEntry(key.toString(), value));
        final shortages = shortagesFromJson(map['data']);
        if (shortages.isNotEmpty) {
          throw InventoryDocumentShortageException(
            (map['message'] ?? 'Không đủ tồn kho để hoàn thành phiếu.')
                .toString(),
            shortages,
          );
        }
      }
      throw Exception(_message(error, 'Không thể hoàn thành phiếu nhập'));
    }
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

  Future<InventoryDocumentModel> _post(
    String path,
    Map<String, dynamic> data, {
    required String fallback,
  }) async {
    try {
      final response = await _client.dio.post<dynamic>(path, data: data);
      return _unwrap(response.data, InventoryDocumentModel.fromJson, fallback);
    } on DioException catch (error) {
      throw Exception(_message(error, fallback));
    }
  }

  Future<InventoryDocumentModel> _put(
    String path,
    Map<String, dynamic> data, {
    required String fallback,
  }) async {
    try {
      final response = await _client.dio.put<dynamic>(path, data: data);
      return _unwrap(response.data, InventoryDocumentModel.fromJson, fallback);
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
