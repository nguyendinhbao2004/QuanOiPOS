import '../entities/voice_order_recognition.dart';
import '../repositories/voice_order_repository.dart';

class RecognizeVoiceOrderUseCase {
  final VoiceOrderRepository _repository;

  const RecognizeVoiceOrderUseCase(this._repository);

  Future<VoiceOrderRecognition> call(String audioFilePath) {
    return _repository.recognizeAudioFile(audioFilePath);
  }
}
