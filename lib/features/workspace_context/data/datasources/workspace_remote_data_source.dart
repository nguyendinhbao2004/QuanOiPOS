import '../../../../core/network/dio/dio_client.dart';
import '../../domain/exceptions/store_access_denied_exception.dart';
import '../models/create_store_request_model.dart';
import '../models/store_permission_model.dart';
import '../models/store_model.dart';

class WorkspaceRemoteDataSource {
  final DioClient _dioClient;

  const WorkspaceRemoteDataSource(this._dioClient);

  Future<List<StoreModel>> getMyStores() async {
    final response = await _dioClient.getResponse<List<StoreModel>>(
      '/stores/my',
      dataFromJson: StoreModel.listFromJson,
    );

    if (!response.succeeded || response.data == null) {
      _throwRequestFailure(
        response.message,
        response.errors,
        'Load my stores failed',
      );
    }

    return response.data!;
  }

  Future<StoreModel> createStore(CreateStoreRequestModel request) async {
    final response = await _dioClient.postResponse<StoreModel?>(
      '/stores',
      data: request.toJson(),
      dataFromJson: (json) => json == null ? null : StoreModel.fromJson(json),
    );

    if (!response.succeeded || response.data == null) {
      _throwRequestFailure(
        response.message,
        response.errors,
        'Không thể tạo cửa hàng',
      );
    }

    return response.data!;
  }

  Future<StoreModel> getStoreById(int storeId) async {
    final response = await _dioClient.getResponse<Object>('/stores/$storeId');

    if (!response.succeeded || response.data == null) {
      _throwRequestFailure(
        response.message,
        response.errors,
        'Load store failed',
      );
    }

    return StoreModel.fromJson(response.data);
  }

  Future<List<StorePermissionModel>> getMyStorePermissions(int storeId) async {
    final response = await _dioClient.getResponse<List<StorePermissionModel>>(
      '/permissions/store/$storeId/me',
      dataFromJson: StorePermissionModel.listFromJson,
    );

    if (!response.succeeded || response.data == null) {
      throw StoreAccessDeniedException(
        _failureMessage(
          response.message,
          response.errors,
          'Bạn không có quyền truy cập cửa hàng này',
        ),
      );
    }

    return response.data!;
  }

  Never _throwRequestFailure(
    String? message,
    List<String> errors,
    String fallbackMessage,
  ) {
    throw Exception(_failureMessage(message, errors, fallbackMessage));
  }

  String _failureMessage(
    String? message,
    List<String> errors,
    String fallbackMessage,
  ) {
    final cleanMessage = message?.trim();
    if (cleanMessage != null && cleanMessage.isNotEmpty) {
      return cleanMessage;
    }

    if (errors.isNotEmpty) {
      return errors.first;
    }

    return fallbackMessage;
  }
}
