import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quan_oi/features/store_operations/voice_order/domain/entities/unmatched_voice_order_item.dart';
import 'package:quan_oi/features/store_operations/voice_order/domain/entities/voice_order_item.dart';
import 'package:quan_oi/features/store_operations/voice_order/domain/entities/voice_order_recognition.dart';
import 'package:quan_oi/features/store_operations/voice_order/domain/repositories/voice_order_repository.dart';
import 'package:quan_oi/features/store_operations/voice_order/domain/usecases/recognize_voice_order_use_case.dart';
import 'package:quan_oi/features/store_operations/voice_order/presentation/controllers/voice_order_state.dart';
import 'package:quan_oi/features/store_operations/voice_order/presentation/providers/voice_order_providers.dart';
import 'package:quan_oi/features/store_operations/voice_order/presentation/services/voice_order_audio_recorder.dart';
import 'package:quan_oi/features/store_operations/voice_order/presentation/services/voice_order_speech_preview_service.dart';

void main() {
  test('records, stops, and recognizes voice order', () async {
    final repository = _FakeVoiceOrderRepository(
      recognition: _recognition(unmatched: true),
    );
    final recorder = _FakeVoiceOrderAudioRecorder();
    final speechPreview = _FakeVoiceOrderSpeechPreviewService(
      transcript: 'một trà sữa',
    );
    final container = _container(
      repository: repository,
      recorder: recorder,
      speechPreview: speechPreview,
    );
    addTearDown(container.dispose);

    final subscription = container.listen(
      voiceOrderNotifierProvider,
      (_, _) {},
      fireImmediately: true,
    );
    addTearDown(subscription.close);

    final notifier = container.read(voiceOrderNotifierProvider.notifier);

    await notifier.startRecording();
    expect(
      container.read(voiceOrderNotifierProvider).status,
      VoiceOrderStatus.recording,
    );
    expect(recorder.startCallCount, 1);
    expect(speechPreview.startCallCount, 1);
    expect(
      container.read(voiceOrderNotifierProvider).liveTranscript,
      'một trà sữa',
    );

    await notifier.stopRecording();
    expect(
      container.read(voiceOrderNotifierProvider).status,
      VoiceOrderStatus.readyToSend,
    );
    expect(speechPreview.stopCallCount, 1);

    await notifier.recognize();
    final state = container.read(voiceOrderNotifierProvider);
    expect(state.status, VoiceOrderStatus.success);
    expect(state.recognition?.items.single.productName, 'Trà sữa');
    expect(state.recognition?.unmatchedItems.single.rawText, 'trà đào');
    expect(repository.recognizedAudioPath, recorder.path);
  });

  test('permission denial sets permissionDenied state', () async {
    final container = _container(
      repository: _FakeVoiceOrderRepository(recognition: _recognition()),
      recorder: _FakeVoiceOrderAudioRecorder(
        startError: const VoiceOrderRecorderPermissionException(),
      ),
      speechPreview: _FakeVoiceOrderSpeechPreviewService(),
    );
    addTearDown(container.dispose);
    final subscription = container.listen(
      voiceOrderNotifierProvider,
      (_, _) {},
      fireImmediately: true,
    );
    addTearDown(subscription.close);

    await container.read(voiceOrderNotifierProvider.notifier).startRecording();

    final state = container.read(voiceOrderNotifierProvider);
    expect(state.status, VoiceOrderStatus.permissionDenied);
    expect(state.errorMessage, contains('microphone'));
  });

  test('recognition error keeps audio and exposes error state', () async {
    final repository = _FakeVoiceOrderRepository(
      recognitionError: Exception('Backend down'),
    );
    final recorder = _FakeVoiceOrderAudioRecorder();
    final container = _container(
      repository: repository,
      recorder: recorder,
      speechPreview: _FakeVoiceOrderSpeechPreviewService(),
    );
    addTearDown(container.dispose);
    final subscription = container.listen(
      voiceOrderNotifierProvider,
      (_, _) {},
      fireImmediately: true,
    );
    addTearDown(subscription.close);

    final notifier = container.read(voiceOrderNotifierProvider.notifier);
    await notifier.startRecording();
    await notifier.stopRecording();
    await notifier.recognize();

    final state = container.read(voiceOrderNotifierProvider);
    expect(state.status, VoiceOrderStatus.error);
    expect(state.audioFilePath, recorder.path);
    expect(state.errorMessage, 'Backend down');
  });

  test('speech preview failure does not block recording', () async {
    final speechPreview = _FakeVoiceOrderSpeechPreviewService(
      unavailableMessage: 'Speech unavailable',
    );
    final container = _container(
      repository: _FakeVoiceOrderRepository(recognition: _recognition()),
      recorder: _FakeVoiceOrderAudioRecorder(),
      speechPreview: speechPreview,
    );
    addTearDown(container.dispose);
    final subscription = container.listen(
      voiceOrderNotifierProvider,
      (_, _) {},
      fireImmediately: true,
    );
    addTearDown(subscription.close);

    await container.read(voiceOrderNotifierProvider.notifier).startRecording();

    final state = container.read(voiceOrderNotifierProvider);
    expect(state.status, VoiceOrderStatus.recording);
    expect(state.liveTranscript, isEmpty);
    expect(state.speechPreviewMessage, 'Speech unavailable');
  });

  test('clear cancels recorder and speech preview', () async {
    final recorder = _FakeVoiceOrderAudioRecorder();
    final speechPreview = _FakeVoiceOrderSpeechPreviewService();
    final container = _container(
      repository: _FakeVoiceOrderRepository(recognition: _recognition()),
      recorder: recorder,
      speechPreview: speechPreview,
    );
    addTearDown(container.dispose);
    final subscription = container.listen(
      voiceOrderNotifierProvider,
      (_, _) {},
      fireImmediately: true,
    );
    addTearDown(subscription.close);

    final notifier = container.read(voiceOrderNotifierProvider.notifier);
    await notifier.startRecording();
    await notifier.clear();

    expect(
      container.read(voiceOrderNotifierProvider).status,
      VoiceOrderStatus.idle,
    );
    expect(recorder.cancelCallCount, 1);
    expect(speechPreview.cancelCallCount, 1);
  });
}

ProviderContainer _container({
  required _FakeVoiceOrderRepository repository,
  required _FakeVoiceOrderAudioRecorder recorder,
  required _FakeVoiceOrderSpeechPreviewService speechPreview,
}) {
  return ProviderContainer(
    overrides: [
      recognizeVoiceOrderUseCaseProvider.overrideWithValue(
        RecognizeVoiceOrderUseCase(repository),
      ),
      voiceOrderAudioRecorderProvider.overrideWithValue(recorder),
      voiceOrderSpeechPreviewServiceProvider.overrideWithValue(speechPreview),
    ],
  );
}

VoiceOrderRecognition _recognition({bool unmatched = false}) {
  return VoiceOrderRecognition(
    transcript: 'Cho tôi 1 trà sữa',
    items: const [
      VoiceOrderItem(
        productId: 1,
        productName: 'Trà sữa',
        quantity: 1,
        unitPrice: 45000,
        totalPrice: 45000,
        confidence: 0.92,
      ),
    ],
    unmatchedItems: unmatched
        ? const [
            UnmatchedVoiceOrderItem(
              rawText: 'trà đào',
              quantity: 2,
              reason: 'Product not found in database',
            ),
          ]
        : const [],
    estimatedTotal: 45000,
  );
}

class _FakeVoiceOrderRepository implements VoiceOrderRepository {
  final VoiceOrderRecognition? recognition;
  final Exception? recognitionError;
  String? recognizedAudioPath;

  _FakeVoiceOrderRepository({this.recognition, this.recognitionError});

  @override
  Future<VoiceOrderRecognition> recognizeAudioFile(String audioFilePath) async {
    recognizedAudioPath = audioFilePath;
    final error = recognitionError;
    if (error != null) {
      throw error;
    }

    return recognition!;
  }
}

class _FakeVoiceOrderAudioRecorder implements VoiceOrderAudioRecorder {
  final Object? startError;
  final String path = '/tmp/voice-order.mp3';
  int startCallCount = 0;
  int cancelCallCount = 0;

  _FakeVoiceOrderAudioRecorder({this.startError});

  @override
  Future<String> start() async {
    startCallCount += 1;
    final error = startError;
    if (error != null) {
      throw error;
    }

    return path;
  }

  @override
  Future<String?> stop() async {
    return path;
  }

  @override
  Future<void> cancel() async {
    cancelCallCount += 1;
  }
}

class _FakeVoiceOrderSpeechPreviewService
    implements VoiceOrderSpeechPreviewService {
  final String? transcript;
  final String? unavailableMessage;
  int startCallCount = 0;
  int stopCallCount = 0;
  int cancelCallCount = 0;

  _FakeVoiceOrderSpeechPreviewService({
    this.transcript,
    this.unavailableMessage,
  });

  @override
  Future<void> start({
    required void Function(String transcript) onTranscript,
    required void Function(String message) onUnavailable,
  }) async {
    startCallCount += 1;
    final message = unavailableMessage;
    if (message != null) {
      onUnavailable(message);
      return;
    }

    final text = transcript;
    if (text != null) {
      onTranscript(text);
    }
  }

  @override
  Future<void> stop() async {
    stopCallCount += 1;
  }

  @override
  Future<void> cancel() async {
    cancelCallCount += 1;
  }
}
