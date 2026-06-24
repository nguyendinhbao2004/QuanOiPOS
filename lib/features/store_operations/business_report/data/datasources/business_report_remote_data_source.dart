import '../../../../../core/network/dio/dio_client.dart';
import '../models/business_report_model.dart';
import '../models/business_report_request_model.dart';

class BusinessReportRemoteDataSource {
  final DioClient _dioClient;

  const BusinessReportRemoteDataSource(this._dioClient);

  Future<BusinessReportModel> createBusinessReport(
    BusinessReportRequestModel request,
  ) async {
    final response = await _dioClient.postResponse<BusinessReportModel>(
      '/ai-insights/business-report',
      data: request.toJson(),
      dataFromJson: BusinessReportModel.fromJson,
    );

    if (!response.succeeded || response.data == null) {
      _throwRequestFailure(
        response.message,
        response.errors,
        'Không thể tạo báo cáo kinh doanh AI',
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
