import '../../../../core/network/dio/dio_client.dart';
import '../models/received_store_invitation_model.dart';

class StoreInvitationRemoteDataSource {
  final DioClient _dioClient;

  const StoreInvitationRemoteDataSource(this._dioClient);

  Future<List<ReceivedStoreInvitationModel>> getReceivedInvitations() async {
    final response = await _dioClient
        .getResponse<List<ReceivedStoreInvitationModel>>(
          '/store-invitations/received-by-me',
          dataFromJson: ReceivedStoreInvitationModel.listFromJson,
        );

    if (!response.succeeded || response.data == null) {
      _throwRequestFailure(
        response.message,
        response.errors,
        'Không thể tải lời mời cửa hàng',
      );
    }

    return response.data!;
  }

  Future<String> acceptInvitation(int invitationId) async {
    final response = await _dioClient.postResponse<Object?>(
      '/store-invitations/$invitationId/accept',
    );

    if (!response.succeeded) {
      _throwRequestFailure(
        response.message,
        response.errors,
        'Không thể chấp nhận lời mời',
      );
    }

    return _successMessage(response.message, 'Chấp nhận lời mời thành công');
  }

  Future<String> rejectInvitation(int invitationId) async {
    final response = await _dioClient.postResponse<Object?>(
      '/store-invitations/$invitationId/reject',
    );

    if (!response.succeeded) {
      _throwRequestFailure(
        response.message,
        response.errors,
        'Không thể từ chối lời mời',
      );
    }

    return _successMessage(response.message, 'Từ chối lời mời thành công');
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

  String _successMessage(String? message, String fallbackMessage) {
    final cleanMessage = message?.trim();
    if (cleanMessage != null && cleanMessage.isNotEmpty) {
      return cleanMessage;
    }

    return fallbackMessage;
  }
}
