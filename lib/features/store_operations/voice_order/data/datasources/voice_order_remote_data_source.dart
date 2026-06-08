import 'package:dio/dio.dart';

import '../../../../../core/network/dio/dio_client.dart';
import '../models/voice_order_recognition_model.dart';

class VoiceOrderRemoteDataSource {
  final DioClient _dioClient;

  const VoiceOrderRemoteDataSource(this._dioClient);

  Future<VoiceOrderRecognitionModel> recognizeAudioFile(
    String audioFilePath,
  ) async {
    final formData = FormData.fromMap({
      'audioFile': await MultipartFile.fromFile(
        audioFilePath,
        filename: 'voice-order.mp3',
        contentType: DioMediaType('audio', 'mpeg'),
      ),
    });

    final response = await _dioClient.post<dynamic>(
      '/voice-order/recognize',
      data: formData,
    );

    return VoiceOrderRecognitionModel.fromApiResponse(response.data);
  }
}
