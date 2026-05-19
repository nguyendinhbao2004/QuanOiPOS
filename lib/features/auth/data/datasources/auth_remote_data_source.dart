import '../../../../core/network/dio/dio_client.dart';
import '../models/login_request_model.dart';
import '../models/login_response_data_model.dart';

class AuthRemoteDataSource {
  final DioClient _dioClient;

  const AuthRemoteDataSource(this._dioClient);

  Future<LoginResponseDataModel> login(LoginRequestModel request) async {
    final response = await _dioClient.postResponse<LoginResponseDataModel>(
      '/auth/login',
      data: request.toJson(),
      dataFromJson: LoginResponseDataModel.fromJson,
    );

    if (!response.succeeded || response.data == null) {
      final message = response.message ??
          (response.errors.isNotEmpty ? response.errors.first : 'Login failed');
      throw Exception(message);
    }

    return response.data!;
  }
}
