import '../../domain/entities/voice_order_recognition.dart';

enum VoiceOrderStatus {
  idle,
  permissionDenied,
  recording,
  readyToSend,
  recognizing,
  submitting,
  success,
  error,
}

class VoiceOrderState {
  final VoiceOrderStatus status;
  final String? audioFilePath;
  final String liveTranscript;
  final String? speechPreviewMessage;
  final VoiceOrderRecognition? recognition;
  final String? errorMessage;

  const VoiceOrderState({
    required this.status,
    this.audioFilePath,
    this.liveTranscript = '',
    this.speechPreviewMessage,
    this.recognition,
    this.errorMessage,
  });

  const VoiceOrderState.idle() : this(status: VoiceOrderStatus.idle);

  bool get isBusy =>
      status == VoiceOrderStatus.recognizing ||
      status == VoiceOrderStatus.submitting;

  VoiceOrderState copyWith({
    VoiceOrderStatus? status,
    Object? audioFilePath = _unchanged,
    String? liveTranscript,
    Object? speechPreviewMessage = _unchanged,
    Object? recognition = _unchanged,
    Object? errorMessage = _unchanged,
  }) {
    return VoiceOrderState(
      status: status ?? this.status,
      audioFilePath: audioFilePath == _unchanged
          ? this.audioFilePath
          : audioFilePath as String?,
      liveTranscript: liveTranscript ?? this.liveTranscript,
      speechPreviewMessage: speechPreviewMessage == _unchanged
          ? this.speechPreviewMessage
          : speechPreviewMessage as String?,
      recognition: recognition == _unchanged
          ? this.recognition
          : recognition as VoiceOrderRecognition?,
      errorMessage: errorMessage == _unchanged
          ? this.errorMessage
          : errorMessage as String?,
    );
  }
}

const Object _unchanged = Object();
