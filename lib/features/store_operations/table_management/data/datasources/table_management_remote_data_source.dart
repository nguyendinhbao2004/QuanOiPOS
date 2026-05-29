import '../../../../../core/network/dio/dio_client.dart';
import '../models/area_model.dart';
import '../models/table_area_group_model.dart';

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
