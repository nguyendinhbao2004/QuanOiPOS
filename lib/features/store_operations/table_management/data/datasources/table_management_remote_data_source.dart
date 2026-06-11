import '../../../../../core/network/dio/dio_client.dart';
import '../models/area_model.dart';
import '../models/area_request_models.dart';
import '../models/dining_table_model.dart';
import '../models/table_request_models.dart';
import '../models/table_area_group_model.dart';
import '../models/table_session_model.dart';

class TableManagementRemoteDataSource {
  final DioClient _dioClient;

  const TableManagementRemoteDataSource(this._dioClient);

  Future<List<AreaModel>> getAreasByStore(int storeId) async {
    final response = await _dioClient.getResponse<List<AreaModel>>(
      '/areas/store/$storeId',
      dataFromJson: AreaModel.listFromJson,
    );

    if (!response.succeeded || response.data == null) {
      _throwRequestFailure(
        response.message,
        response.errors,
        'Không thể tải danh sách khu vực',
      );
    }

    return response.data!;
  }

  Future<List<TableAreaGroupModel>> getTableGroupsByStore({
    required int storeId,
    int? areaId,
  }) async {
    final response = await _dioClient.getResponse<List<TableAreaGroupModel>>(
      '/tables/store/$storeId/areas',
      queryParameters: areaId == null ? null : {'areaId': areaId},
      dataFromJson: TableAreaGroupModel.listFromJson,
    );

    if (!response.succeeded || response.data == null) {
      _throwRequestFailure(
        response.message,
        response.errors,
        'Không thể tải danh sách bàn',
      );
    }

    return response.data!;
  }

  Future<DiningTableModel> getTableById(int tableId) async {
    final response = await _dioClient.getResponse<DiningTableModel>(
      '/tables/$tableId',
      dataFromJson: DiningTableModel.fromJson,
    );

    if (!response.succeeded || response.data == null) {
      _throwRequestFailure(
        response.message,
        response.errors,
        'Không thể tải chi tiết bàn',
      );
    }

    return response.data!;
  }

  Future<AreaModel> getAreaById(int areaId) async {
    final response = await _dioClient.getResponse<AreaModel>(
      '/areas/$areaId',
      dataFromJson: AreaModel.fromJson,
    );

    if (!response.succeeded || response.data == null) {
      _throwRequestFailure(
        response.message,
        response.errors,
        'Không thể tải khu vực',
      );
    }

    return response.data!;
  }

  Future<AreaModel> createArea(CreateAreaRequestModel request) async {
    final response = await _dioClient.postResponse<AreaModel>(
      '/areas',
      data: request.toJson(),
      dataFromJson: AreaModel.fromJson,
    );

    if (!response.succeeded || response.data == null) {
      _throwRequestFailure(
        response.message,
        response.errors,
        'Không thể thêm khu vực',
      );
    }

    return response.data!;
  }

  Future<DiningTableModel> createTable(CreateTableRequestModel request) async {
    final response = await _dioClient.postResponse<DiningTableModel>(
      '/tables',
      data: request.toJson(),
      dataFromJson: DiningTableModel.fromJson,
    );

    if (!response.succeeded || response.data == null) {
      _throwRequestFailure(
        response.message,
        response.errors,
        'Không thể thêm bàn',
      );
    }

    return response.data!;
  }

  Future<DiningTableModel> updateTable({
    required int tableId,
    required UpdateTableRequestModel request,
  }) async {
    final response = await _dioClient.putResponse<DiningTableModel>(
      '/tables/$tableId',
      data: request.toJson(),
      dataFromJson: DiningTableModel.fromJson,
    );

    if (!response.succeeded || response.data == null) {
      _throwRequestFailure(
        response.message,
        response.errors,
        'Không thể cập nhật bàn',
      );
    }

    return response.data!;
  }

  Future<void> updateTableStatus({
    required int tableId,
    required UpdateTableStatusRequestModel request,
  }) async {
    final response = await _dioClient.putResponse<Object?>(
      '/tables/$tableId/status',
      data: request.toJson(),
    );

    if (!response.succeeded) {
      _throwRequestFailure(
        response.message,
        response.errors,
        'Không thể cập nhật trạng thái bàn',
      );
    }
  }

  Future<List<TableSessionModel>> getTableSessionsByTable(int tableId) async {
    final response = await _dioClient.getResponse<List<TableSessionModel>>(
      '/table-sessions/table/$tableId',
      dataFromJson: TableSessionModel.listFromJson,
    );

    if (!response.succeeded || response.data == null) {
      _throwRequestFailure(
        response.message,
        response.errors,
        'Không thể tải phiên bàn',
      );
    }

    return response.data!;
  }

  Future<List<TableSessionModel>> getOpenTableSessionsByTable(
    int tableId,
  ) async {
    final response = await _dioClient.getResponse<List<TableSessionModel>>(
      '/table-sessions/table/$tableId/open',
      dataFromJson: TableSessionModel.listFromJson,
    );

    if (!response.succeeded || response.data == null) {
      _throwRequestFailure(
        response.message,
        response.errors,
        'Không thể tải phiên bàn đang mở',
      );
    }

    return response.data!;
  }

  Future<TableSessionModel> openTableSession(
    OpenTableSessionRequestModel request,
  ) async {
    final response = await _dioClient.postResponse<TableSessionModel>(
      '/table-sessions',
      data: request.toJson(),
      dataFromJson: TableSessionModel.fromJson,
    );

    if (!response.succeeded || response.data == null) {
      _throwRequestFailure(
        response.message,
        response.errors,
        'Không thể mở phiên bàn',
      );
    }

    return response.data!;
  }

  Future<TableSessionModel> closeTableSession(int tableSessionId) async {
    final response = await _dioClient.putResponse<TableSessionModel>(
      '/table-sessions/$tableSessionId/close',
      dataFromJson: TableSessionModel.fromJson,
    );

    if (!response.succeeded || response.data == null) {
      _throwRequestFailure(
        response.message,
        response.errors,
        'Không thể đóng phiên bàn',
      );
    }

    return response.data!;
  }

  Future<AreaModel> updateArea({
    required int areaId,
    required UpdateAreaRequestModel request,
  }) async {
    final response = await _dioClient.putResponse<AreaModel>(
      '/areas/$areaId',
      data: request.toJson(),
      dataFromJson: AreaModel.fromJson,
    );

    if (!response.succeeded || response.data == null) {
      _throwRequestFailure(
        response.message,
        response.errors,
        'Không thể cập nhật khu vực',
      );
    }

    return response.data!;
  }

  Future<AreaModel> updateAreaDisplayOrder({
    required int areaId,
    required UpdateAreaDisplayOrderRequestModel request,
  }) async {
    final response = await _dioClient.putResponse<AreaModel>(
      '/areas/$areaId/display-order',
      data: request.toJson(),
      dataFromJson: AreaModel.fromJson,
    );

    if (!response.succeeded || response.data == null) {
      _throwRequestFailure(
        response.message,
        response.errors,
        'Không thể cập nhật thứ tự khu vực',
      );
    }

    return response.data!;
  }

  Future<void> deleteArea(int areaId) async {
    final response = await _dioClient.deleteResponse<Object?>('/areas/$areaId');

    if (!response.succeeded) {
      _throwRequestFailure(
        response.message,
        response.errors,
        'Không thể xóa khu vực',
      );
    }
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
