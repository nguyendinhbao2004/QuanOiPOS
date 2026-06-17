import '../../../../../core/network/dio/dio_client.dart';
import '../models/owner_dashboard_insight_model.dart';
import '../models/owner_dashboard_request_model.dart';

class OwnerDashboardRemoteDataSource {
  final DioClient _dioClient;

  const OwnerDashboardRemoteDataSource(this._dioClient);

  Future<OwnerDashboardInsightModel> createSalesInsight(
    OwnerDashboardRequestModel request,
  ) async {
    final response = await _dioClient.postResponse<OwnerDashboardInsightModel>(
      '/ai-insights/sales',
      data: request.toJson(),
      dataFromJson: OwnerDashboardInsightModel.fromJson,
    );

    if (!response.succeeded || response.data == null) {
      _throwRequestFailure(
        response.message,
        response.errors,
        'Không thể tải tổng quan doanh thu',
      );
    }

    return response.data!;
  }

  Never _throwRequestFailure(
    String? message,
    List<String> errors,
    String fallbackMessage,
  ) {
    final cleanMessage = message?.trim();
    if (cleanMessage != null && cleanMessage.isNotEmpty) {
      throw Exception(cleanMessage);
    }

    if (errors.isNotEmpty) {
      throw Exception(errors.first);
    }

    throw Exception(fallbackMessage);
  }
}
