import 'package:speech_to_text/speech_to_text.dart' as speech;

abstract class VoiceOrderSpeechPreviewService {
  Future<void> start({
    required void Function(String transcript) onTranscript,
    required void Function(String message) onUnavailable,
  });

  Future<void> stop();

  Future<void> cancel();
}

class SpeechToTextVoiceOrderSpeechPreviewService
    implements VoiceOrderSpeechPreviewService {
  final speech.SpeechToText _speechToText;

  SpeechToTextVoiceOrderSpeechPreviewService({
    speech.SpeechToText? speechToText,
  }) : _speechToText = speechToText ?? speech.SpeechToText();

  @override
  Future<void> start({
    required void Function(String transcript) onTranscript,
    required void Function(String message) onUnavailable,
  }) async {
    final isAvailable = await _speechToText.initialize(
      onError: (error) {
        final message = error.errorMsg.trim();
        if (message.isNotEmpty) {
          onUnavailable(message);
        }
      },
    );

    if (!isAvailable) {
      onUnavailable('Thiết bị chưa hỗ trợ nhận diện giọng nói realtime.');
      return;
    }

    final localeId = await _preferredVietnameseLocale();
    await _speechToText.listen(
      onResult: (result) {
        final words = result.recognizedWords.trim();
        if (words.isNotEmpty) {
          onTranscript(words);
        }
      },
      listenOptions: speech.SpeechListenOptions(
        partialResults: true,
        cancelOnError: false,
        listenFor: const Duration(seconds: 30),
        pauseFor: const Duration(seconds: 4),
        localeId: localeId,
        listenMode: speech.ListenMode.dictation,
      ),
    );
  }

  @override
  Future<void> stop() {
    return _speechToText.stop();
  }

  @override
  Future<void> cancel() {
    return _speechToText.cancel();
  }

  Future<String?> _preferredVietnameseLocale() async {
    final locales = await _speechToText.locales();
    for (final locale in locales) {
      final localeId = locale.localeId;
      if (localeId.toLowerCase().startsWith('vi')) {
        return localeId;
      }
    }

    return null;
  }
}
