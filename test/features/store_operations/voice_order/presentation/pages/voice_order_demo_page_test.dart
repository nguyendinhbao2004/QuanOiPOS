import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quan_oi/core/storage/last_active_store_storage.dart';
import 'package:quan_oi/core/theme/index.dart';
import 'package:quan_oi/features/auth/domain/entities/account_type.dart';
import 'package:quan_oi/features/auth/presentation/controllers/auth_notifier.dart';
import 'package:quan_oi/features/auth/presentation/controllers/auth_state.dart';
import 'package:quan_oi/features/auth/presentation/providers/auth_providers.dart';
import 'package:quan_oi/features/store_operations/voice_order/domain/entities/voice_order_item.dart';
import 'package:quan_oi/features/store_operations/voice_order/domain/entities/voice_order_recognition.dart';
import 'package:quan_oi/features/store_operations/voice_order/domain/repositories/voice_order_repository.dart';
import 'package:quan_oi/features/store_operations/voice_order/domain/usecases/recognize_voice_order_use_case.dart';
import 'package:quan_oi/features/store_operations/voice_order/presentation/pages/voice_order_demo_page.dart';
import 'package:quan_oi/features/store_operations/voice_order/presentation/providers/voice_order_providers.dart';
import 'package:quan_oi/features/store_operations/voice_order/presentation/services/voice_order_audio_recorder.dart';
import 'package:quan_oi/features/store_operations/voice_order/presentation/services/voice_order_speech_preview_service.dart';
import 'package:quan_oi/features/workspace_context/domain/entities/store.dart';
import 'package:quan_oi/features/workspace_context/domain/entities/store_access_context.dart';
import 'package:quan_oi/features/workspace_context/domain/entities/store_permission.dart';
import 'package:quan_oi/features/workspace_context/domain/repositories/workspace_repository.dart';
import 'package:quan_oi/features/workspace_context/domain/usecases/clear_last_active_store_use_case.dart';
import 'package:quan_oi/features/workspace_context/domain/usecases/load_last_active_store_use_case.dart';
import 'package:quan_oi/features/workspace_context/domain/usecases/load_my_stores_use_case.dart';
import 'package:quan_oi/features/workspace_context/domain/usecases/load_store_access_context_use_case.dart';
import 'package:quan_oi/features/workspace_context/domain/usecases/save_last_active_store_use_case.dart';
import 'package:quan_oi/features/workspace_context/presentation/providers/workspace_context_providers.dart';

void main() {
  testWidgets('idle page only shows mic CTA without bottom sheet controls', (
    tester,
  ) async {
    await _pumpVoiceOrderPage(tester);
    await tester.pumpAndSettle();

    expect(find.text('Order giọng nói'), findsOneWidget);
    expect(find.text('Chạm mic để đọc món'), findsOneWidget);
    expect(find.byIcon(Icons.mic_rounded), findsOneWidget);
    expect(find.text('Đọc order bằng giọng nói'), findsNothing);
    expect(find.text('Nhập tên khách hàng, phòng bàn...'), findsNothing);
  });

  testWidgets('tap mic opens bottom sheet and shows live transcript', (
    tester,
  ) async {
    final recorder = _FakeVoiceOrderAudioRecorder();
    final speechPreview = _FakeVoiceOrderSpeechPreviewService(
      transcript: 'hai cà phê sữa',
    );
    await _pumpVoiceOrderPage(
      tester,
      recorder: recorder,
      speechPreview: speechPreview,
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.mic_rounded));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Đọc order bằng giọng nói'), findsOneWidget);
    expect(find.text('Bạn đang nói'), findsOneWidget);
    expect(find.text('hai cà phê sữa'), findsOneWidget);
    expect(recorder.startCallCount, 1);
    expect(speechPreview.startCallCount, 1);
  });

  testWidgets('recognized result renders on main page after sending audio', (
    tester,
  ) async {
    final repository = _FakeVoiceOrderRepository(
      recognition: const VoiceOrderRecognition(
        transcript: 'Cho tôi 1 trà sữa',
        items: [
          VoiceOrderItem(
            productId: 1,
            productName: 'Trà sữa',
            quantity: 1,
            unitPrice: 45000,
            totalPrice: 45000,
            confidence: 0.92,
          ),
        ],
        unmatchedItems: [],
        estimatedTotal: 45000,
      ),
    );
    await _pumpVoiceOrderPage(tester, repository: repository);
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.mic_rounded));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.tap(find.text('Dừng'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Gửi'));
    await tester.pumpAndSettle();

    expect(find.text('Kết quả nhận diện'), findsOneWidget);
    expect(find.text('Cho tôi 1 trà sữa'), findsOneWidget);
    expect(find.text('Trà sữa'), findsOneWidget);
  });
}

Future<void> _pumpVoiceOrderPage(
  WidgetTester tester, {
  _FakeVoiceOrderRepository? repository,
  _FakeVoiceOrderAudioRecorder? recorder,
  _FakeVoiceOrderSpeechPreviewService? speechPreview,
}) async {
  final workspaceRepository = const _FakeWorkspaceRepository();
  final lastActiveStoreStorage = _FakeLastActiveStoreStorage();
  final voiceOrderRepository =
      repository ?? _FakeVoiceOrderRepository(recognition: _recognition());

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authNotifierProvider.overrideWith(
          () => _FixedAuthNotifier(
            const AuthState(
              status: AuthStatus.authenticated,
              accountType: AccountType.storeUser,
              accountId: 10,
              fullName: 'Test User',
              email: 'user@quanoi.test',
            ),
          ),
        ),
        loadStoreAccessContextUseCaseProvider.overrideWithValue(
          LoadStoreAccessContextUseCase(workspaceRepository),
        ),
        loadMyStoresUseCaseProvider.overrideWithValue(
          LoadMyStoresUseCase(workspaceRepository),
        ),
        loadLastActiveStoreUseCaseProvider.overrideWithValue(
          LoadLastActiveStoreUseCase(lastActiveStoreStorage),
        ),
        saveLastActiveStoreUseCaseProvider.overrideWithValue(
          SaveLastActiveStoreUseCase(lastActiveStoreStorage),
        ),
        clearLastActiveStoreUseCaseProvider.overrideWithValue(
          ClearLastActiveStoreUseCase(lastActiveStoreStorage),
        ),
        recognizeVoiceOrderUseCaseProvider.overrideWithValue(
          RecognizeVoiceOrderUseCase(voiceOrderRepository),
        ),
        voiceOrderAudioRecorderProvider.overrideWithValue(
          recorder ?? _FakeVoiceOrderAudioRecorder(),
        ),
        voiceOrderSpeechPreviewServiceProvider.overrideWithValue(
          speechPreview ?? _FakeVoiceOrderSpeechPreviewService(),
        ),
      ],
      child: MaterialApp(
        theme: AppTheme.light,
        home: const VoiceOrderDemoPage(storeId: 5),
      ),
    ),
  );
}

VoiceOrderRecognition _recognition() {
  return const VoiceOrderRecognition(
    transcript: 'Cho tôi 1 trà sữa',
    items: [
      VoiceOrderItem(
        productId: 1,
        productName: 'Trà sữa',
        quantity: 1,
        unitPrice: 45000,
        totalPrice: 45000,
        confidence: 0.92,
      ),
    ],
    unmatchedItems: [],
    estimatedTotal: 45000,
  );
}

class _FixedAuthNotifier extends AuthNotifier {
  final AuthState fixedState;

  _FixedAuthNotifier(this.fixedState);

  @override
  AuthState build() {
    return fixedState;
  }
}

class _FakeWorkspaceRepository implements WorkspaceRepository {
  const _FakeWorkspaceRepository();

  @override
  Future<List<Store>> loadMyStores() async => [_store];

  @override
  Future<Store> createStore({
    required String storeName,
    required String phone,
    required String address,
  }) async {
    return _store;
  }

  @override
  Future<Store> loadStoreById(int storeId) async => _store;

  @override
  Future<List<StorePermission>> loadMyStorePermissions(int storeId) async {
    return const [StorePermission(permissionId: 1, code: 'DASHBOARD.VIEW')];
  }

  @override
  Future<StoreAccessContext> loadStoreAccessContext(int storeId) async {
    return StoreAccessContext(
      store: _store,
      permissions: await loadMyStorePermissions(storeId),
    );
  }

  @override
  Future<StoreAccessContext?> loadCachedStoreAccessContext({
    required int accountId,
    required int storeId,
  }) async {
    return null;
  }

  @override
  Future<void> saveStoreAccessContextCache({
    required int accountId,
    required StoreAccessContext context,
  }) async {}

  @override
  Future<void> clearStoreAccessContextCache({
    required int accountId,
    required int storeId,
  }) async {}

  @override
  Future<void> clearAllStoreAccessContextCache() async {}
}

const _store = Store(
  id: 5,
  ownerAccountId: 10,
  storeName: 'FPT Shipper Vip',
  phone: '0909000000',
  address: 'Tầng 1',
  status: StoreStatus.active,
  isDeleted: false,
);

class _FakeLastActiveStoreStorage implements LastActiveStoreStorage {
  int? lastStoreId;

  @override
  Future<int?> getLastActiveStoreId() async => lastStoreId;

  @override
  Future<void> saveLastActiveStoreId(int storeId) async {
    lastStoreId = storeId;
  }

  @override
  Future<void> clearLastActiveStoreId() async {
    lastStoreId = null;
  }
}

class _FakeVoiceOrderRepository implements VoiceOrderRepository {
  final VoiceOrderRecognition recognition;

  _FakeVoiceOrderRepository({required this.recognition});

  @override
  Future<VoiceOrderRecognition> recognizeAudioFile(String audioFilePath) async {
    return recognition;
  }
}

class _FakeVoiceOrderAudioRecorder implements VoiceOrderAudioRecorder {
  int startCallCount = 0;

  @override
  Future<String> start() async {
    startCallCount += 1;
    return '/tmp/voice-order.mp3';
  }

  @override
  Future<String?> stop() async => '/tmp/voice-order.mp3';

  @override
  Future<void> cancel() async {}
}

class _FakeVoiceOrderSpeechPreviewService
    implements VoiceOrderSpeechPreviewService {
  final String? transcript;
  int startCallCount = 0;

  _FakeVoiceOrderSpeechPreviewService({this.transcript});

  @override
  Future<void> start({
    required void Function(String transcript) onTranscript,
    required void Function(String message) onUnavailable,
  }) async {
    startCallCount += 1;
    final text = transcript;
    if (text != null) {
      onTranscript(text);
    }
  }

  @override
  Future<void> stop() async {}

  @override
  Future<void> cancel() async {}
}
