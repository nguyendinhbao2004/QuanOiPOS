import '../../../../../core/network/dio/dio_client.dart';
import '../models/system_admin_account_models.dart';

class SystemAdminAccountManagementRemoteDataSource {
  final DioClient _dio;
  const SystemAdminAccountManagementRemoteDataSource(this._dio);
  Future<SystemAdminAccountSummaryModel> loadSummary() => _get(
    '/system-admin/accounts/summary',
    SystemAdminAccountSummaryModel.fromJson,
    'Không thể tải tổng quan account',
  );
  Future<SystemAdminPageModel<SystemAdminAccountModel>> loadAccounts(
    Map<String, dynamic> query,
  ) => _get(
    '/system-admin/accounts',
    (data) => SystemAdminPageModel.fromJson(
      data,
      (item) => SystemAdminAccountModel.fromJson(item),
    ),
    'Không thể tải danh sách account',
    query,
  );
  Future<SystemAdminAccountDetailModel> loadAccount(int id) => _get(
    '/system-admin/accounts/$id',
    SystemAdminAccountDetailModel.fromJson,
    'Không thể tải chi tiết account',
  );
  Future<SystemAdminPageModel<PendingRegistrationModel>> loadPending(
    Map<String, dynamic> query,
  ) => _get(
    '/system-admin/pending-registrations',
    (data) => SystemAdminPageModel.fromJson(
      data,
      (item) => PendingRegistrationModel.fromJson(item),
    ),
    'Không thể tải đăng ký chờ xác minh',
    query,
  );
  Future<void> updateStatus(int id, Map<String, dynamic> data) async {
    final r = await _dio.patchResponse<Object?>(
      '/system-admin/accounts/$id/status',
      data: data,
    );
    _ensure(
      r.succeeded,
      r.message,
      r.errors,
      'Không thể cập nhật trạng thái account',
    );
  }

  Future<T> _get<T>(
    String path,
    T Function(Object?) parser,
    String fallback, [
    Map<String, dynamic>? query,
  ]) async {
    final r = await _dio.getResponse<T>(
      path,
      queryParameters: query,
      dataFromJson: parser,
    );
    _ensure(r.succeeded && r.data != null, r.message, r.errors, fallback);
    return r.data as T;
  }

  void _ensure(bool ok, String? message, List<String> errors, String fallback) {
    if (ok) return;
    throw Exception(
      message?.trim().isNotEmpty == true
          ? message
          : errors.isNotEmpty
          ? errors.first
          : fallback,
    );
  }
}
