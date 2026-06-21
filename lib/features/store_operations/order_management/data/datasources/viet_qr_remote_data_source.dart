import 'package:dio/dio.dart';

import '../models/viet_qr_bank_model.dart';

class VietQrRemoteDataSource {
  final Dio _dio;

  const VietQrRemoteDataSource(this._dio);

  Future<List<VietQrBankModel>> loadBanks() async {
    final response = await _dio.get<dynamic>('/v2/banks');
    final data = response.data;
    if (data is! Map<String, dynamic>) {
      throw const FormatException('Invalid VietQR bank response');
    }
    return VietQrBankModel.listFromJson(data['data']);
  }
}
