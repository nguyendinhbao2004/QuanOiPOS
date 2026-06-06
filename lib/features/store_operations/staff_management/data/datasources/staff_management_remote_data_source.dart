import '../../../../../core/network/dio/dio_client.dart';
import '../models/permission_group_model.dart';
import '../models/staff_invitation_model.dart';
import '../models/staff_member_model.dart';
import '../models/staff_request_models.dart';
import '../models/staff_role_model.dart';

class StaffManagementRemoteDataSource {
  final DioClient _dioClient;

  const StaffManagementRemoteDataSource(this._dioClient);

  Future<List<StaffRoleModel>> getRoles(int storeId) async {
    final response = await _dioClient.getResponse<List<StaffRoleModel>>(
      '/stores/$storeId/roles',
      dataFromJson: StaffRoleModel.listFromJson,
    );

    if (!response.succeeded || response.data == null) {
      _throwRequestFailure(
        response.message,
        response.errors,
        'Không thể tải danh sách vai trò',
      );
    }

    return response.data!;
  }

  Future<List<StaffMemberModel>> getStaff(int storeId) async {
    final response = await _dioClient.getResponse<List<StaffMemberModel>>(
      '/stores/$storeId/staff',
      dataFromJson: StaffMemberModel.listFromJson,
    );

    if (!response.succeeded || response.data == null) {
      _throwRequestFailure(
        response.message,
        response.errors,
        'Không thể tải danh sách nhân viên',
      );
    }

    return response.data!;
  }

  Future<List<PermissionGroupModel>> getPermissionGroups(int storeId) async {
    final response = await _dioClient.getResponse<List<PermissionGroupModel>>(
      '/stores/$storeId/permissions/groups',
      dataFromJson: PermissionGroupModel.listFromJson,
    );

    if (!response.succeeded || response.data == null) {
      _throwRequestFailure(
        response.message,
        response.errors,
        'Không thể tải danh sách quyền',
      );
    }

    return response.data!;
  }

  Future<StaffInvitationModel> inviteStaff(
    InviteStaffRequestModel request,
  ) async {
    final response = await _dioClient.postResponse<StaffInvitationModel>(
      '/store-invitations',
      data: request.toJson(),
      dataFromJson: StaffInvitationModel.fromJson,
    );

    if (!response.succeeded || response.data == null) {
      _throwRequestFailure(
        response.message,
        response.errors,
        'Không thể gửi lời mời nhân viên',
      );
    }

    return response.data!;
  }

  Future<void> cancelInvitation({
    required int storeId,
    required int invitationId,
  }) async {
    final response = await _dioClient.deleteResponse<Object?>(
      '/stores/$storeId/staff/invitations/$invitationId',
    );

    if (!response.succeeded) {
      _throwRequestFailure(
        response.message,
        response.errors,
        'Không thể hủy lời mời',
      );
    }
  }

  Future<void> updateStaffDisplayName({
    required int storeId,
    required int storeUserId,
    required UpdateStaffDisplayNameRequestModel request,
  }) async {
    final response = await _dioClient.putResponse<Object?>(
      '/stores/$storeId/staff/$storeUserId/display-name',
      data: request.toJson(),
    );

    if (!response.succeeded) {
      _throwRequestFailure(
        response.message,
        response.errors,
        'Không thể cập nhật tên nhân viên',
      );
    }
  }

  Future<void> updateStaffAccess({
    required int storeId,
    required int storeUserId,
    required UpdateStaffAccessRequestModel request,
  }) async {
    final response = await _dioClient.putResponse<Object?>(
      '/stores/$storeId/staff/$storeUserId/role-permissions',
      data: request.toJson(),
    );

    if (!response.succeeded) {
      _throwRequestFailure(
        response.message,
        response.errors,
        'Không thể cập nhật vai trò và quyền nhân viên',
      );
    }
  }

  Future<void> removeStaff({
    required int storeId,
    required int storeUserId,
  }) async {
    final response = await _dioClient.deleteResponse<Object?>(
      '/stores/$storeId/staff/$storeUserId',
    );

    if (!response.succeeded) {
      _throwRequestFailure(
        response.message,
        response.errors,
        'Không thể xóa nhân viên',
      );
    }
  }

  Future<StaffRoleModel> createRole({
    required int storeId,
    required StaffRoleRequestModel request,
  }) async {
    final response = await _dioClient.postResponse<StaffRoleModel>(
      '/stores/$storeId/roles',
      data: request.toJson(),
      dataFromJson: StaffRoleModel.fromJson,
    );

    if (!response.succeeded || response.data == null) {
      _throwRequestFailure(
        response.message,
        response.errors,
        'Không thể tạo vai trò',
      );
    }

    return response.data!;
  }

  Future<StaffRoleModel> updateRole({
    required int storeId,
    required int roleId,
    required StaffRoleRequestModel request,
  }) async {
    final response = await _dioClient.putResponse<StaffRoleModel>(
      '/stores/$storeId/roles/$roleId',
      data: request.toJson(),
      dataFromJson: StaffRoleModel.fromJson,
    );

    if (!response.succeeded || response.data == null) {
      _throwRequestFailure(
        response.message,
        response.errors,
        'Không thể cập nhật vai trò',
      );
    }

    return response.data!;
  }

  Future<void> deleteRole({required int storeId, required int roleId}) async {
    final response = await _dioClient.deleteResponse<Object?>(
      '/stores/$storeId/roles/$roleId',
    );

    if (!response.succeeded) {
      _throwRequestFailure(
        response.message,
        response.errors,
        'Không thể xóa vai trò',
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
