import '../entities/voice_order_recognition.dart';

abstract class VoiceOrderRepository {
  Future<VoiceOrderRecognition> recognizeAudioFile(String audioFilePath);
}
