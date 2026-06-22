import '../../../../../core/network/dio/dio_client.dart';
import '../models/system_admin_subscription_plan_models.dart';

class SystemAdminPackageManagementRemoteDataSource {
  final DioClient _dioClient;
  const SystemAdminPackageManagementRemoteDataSource(this._dioClient);

  Future<SystemAdminPlanSummaryModel> loadSummary() => _get(
    '/system-admin/subscription-plans/summary',
    SystemAdminPlanSummaryModel.fromJson,
    'Không thể tải tổng quan gói',
  );

  Future<SystemAdminPlanPageModel> loadPlans({
    required String status,
    required int pageIndex,
    required int pageSize,
  }) => _get(
    '/system-admin/subscription-plans',
    SystemAdminPlanPageModel.fromJson,
    'Không thể tải danh sách gói',
    queryParameters: {
      'status': status,
      'pageIndex': pageIndex,
      'pageSize': pageSize,
    },
  );

  Future<SystemAdminSubscriptionPlanModel> loadPlan(int id) => _get(
    '/system-admin/subscription-plans/$id',
    SystemAdminSubscriptionPlanModel.fromJson,
    'Không thể tải chi tiết gói',
  );

  Future<SystemAdminSubscriptionPlanModel> createPlan(
    UpsertSystemAdminSubscriptionPlanModel request,
  ) => _send(
    () => _dioClient.postResponse<SystemAdminSubscriptionPlanModel>(
      '/system-admin/subscription-plans',
      data: request.toJson(),
      dataFromJson: SystemAdminSubscriptionPlanModel.fromJson,
    ),
    'Không thể tạo gói',
  );

  Future<SystemAdminSubscriptionPlanModel> updatePlan(
    int id,
    UpsertSystemAdminSubscriptionPlanModel request,
  ) => _send(
    () => _dioClient.putResponse<SystemAdminSubscriptionPlanModel>(
      '/system-admin/subscription-plans/$id',
      data: request.toJson(),
      dataFromJson: SystemAdminSubscriptionPlanModel.fromJson,
    ),
    'Không thể cập nhật gói',
  );

  Future<void> activatePlan(int id) => _mutate(
    '/system-admin/subscription-plans/$id/activate',
    'Không thể bật bán gói',
  );
  Future<void> deactivatePlan(int id) => _mutate(
    '/system-admin/subscription-plans/$id/deactivate',
    'Không thể tạm ẩn gói',
  );
  Future<void> deletePlan(int id) async {
    final response = await _dioClient.deleteResponse<Object?>(
      '/system-admin/subscription-plans/$id',
    );
    _ensureSucceeded(
      response.succeeded,
      response.message,
      response.errors,
      'Không thể xóa gói',
    );
  }

  Future<void> _mutate(String path, String fallback) async {
    final response = await _dioClient.patchResponse<Object?>(path);
    _ensureSucceeded(
      response.succeeded,
      response.message,
      response.errors,
      fallback,
    );
  }

  Future<T> _get<T>(
    String path,
    T Function(Object?) parser,
    String fallback, {
    Map<String, dynamic>? queryParameters,
  }) => _send(
    () => _dioClient.getResponse<T>(
      path,
      queryParameters: queryParameters,
      dataFromJson: parser,
    ),
    fallback,
  );

  Future<T> _send<T>(
    Future<dynamic> Function() request,
    String fallback,
  ) async {
    final response = await request();
    _ensureSucceeded(
      response.succeeded && response.data != null,
      response.message,
      response.errors,
      fallback,
    );
    return response.data as T;
  }

  void _ensureSucceeded(
    bool succeeded,
    String? message,
    List<String> errors,
    String fallback,
  ) {
    if (succeeded) return;
    throw Exception(
      message?.trim().isNotEmpty == true
          ? message
          : errors.isNotEmpty
          ? errors.first
          : fallback,
    );
  }
}
