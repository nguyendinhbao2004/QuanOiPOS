import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quan_oi/core/storage/last_active_store_storage.dart';
import 'package:quan_oi/core/theme/index.dart';
import 'package:quan_oi/features/auth/domain/entities/account_type.dart';
import 'package:quan_oi/features/auth/presentation/controllers/auth_notifier.dart';
import 'package:quan_oi/features/auth/presentation/controllers/auth_state.dart';
import 'package:quan_oi/features/auth/presentation/providers/auth_providers.dart';
import 'package:quan_oi/features/store_operations/product_management/domain/entities/product.dart';
import 'package:quan_oi/features/store_operations/product_management/domain/entities/product_topping.dart';
import 'package:quan_oi/features/store_operations/product_management/domain/entities/product_type.dart';
import 'package:quan_oi/features/store_operations/product_management/domain/entities/product_variant_draft.dart';
import 'package:quan_oi/features/store_operations/table_management/domain/entities/dining_table.dart';
import 'package:quan_oi/features/store_operations/table_management/domain/entities/table_status.dart';
import 'package:quan_oi/features/store_operations/voice_order/domain/entities/voice_order_item.dart';
import 'package:quan_oi/features/store_operations/voice_order/domain/entities/voice_order_recognition.dart';
import 'package:quan_oi/features/store_operations/voice_order/domain/entities/voice_order_topping.dart';
import 'package:quan_oi/features/store_operations/voice_order/domain/repositories/voice_order_repository.dart';
import 'package:quan_oi/features/store_operations/voice_order/domain/usecases/recognize_voice_order_use_case.dart';
import 'package:quan_oi/features/store_operations/voice_order/presentation/pages/voice_order_page.dart';
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
  testWidgets('idle page shows review layout and bottom mic', (tester) async {
    await _pumpVoiceOrderPage(tester);
    await tester.pumpAndSettle();

    expect(find.text('Order bằng giọng nói'), findsOneWidget);
    expect(find.text('Bàn'), findsOneWidget);
    expect(find.text('Chưa có order'), findsOneWidget);
    expect(find.byIcon(Icons.mic_rounded), findsOneWidget);

    final micCenter = tester.getCenter(find.byIcon(Icons.mic_rounded));
    final screenHeight =
        tester.view.physicalSize.height / tester.view.devicePixelRatio;
    expect(micCenter.dy, greaterThan(screenHeight * 0.75));
  });

  testWidgets('hold mic starts recording and release sends to backend', (
    tester,
  ) async {
    final recorder = _FakeVoiceOrderAudioRecorder();
    await _pumpVoiceOrderPage(tester, recorder: recorder);
    await tester.pumpAndSettle();

    final gesture = await tester.startGesture(
      tester.getCenter(find.byIcon(Icons.mic_rounded)),
    );
    await tester.pump();

    expect(find.text('Đang nghe...'), findsOneWidget);
    expect(recorder.startCallCount, 1);

    await gesture.up();
    await tester.pumpAndSettle();

    expect(find.text('Bàn 8'), findsOneWidget);
    expect(find.text('mi hai san'), findsOneWidget);
    expect(find.text('Ghi chú: cay'), findsOneWidget);
    expect(find.text('Size nhỏ'), findsOneWidget);
    expect(find.text('Trân châu x2'), findsOneWidget);
  });

  testWidgets('release mic shows processing while waiting for backend', (
    tester,
  ) async {
    final completer = Completer<VoiceOrderRecognition>();
    await _pumpVoiceOrderPage(
      tester,
      repository: _FakeVoiceOrderRepository(
        recognitionFuture: completer.future,
      ),
    );
    await tester.pumpAndSettle();

    final gesture = await tester.startGesture(
      tester.getCenter(find.byIcon(Icons.mic_rounded)),
    );
    await tester.pump();
    await gesture.up();
    await tester.pump();

    expect(find.text('Đang xử lý...'), findsOneWidget);

    completer.complete(_recognition());
    await tester.pumpAndSettle();

    expect(find.text('Bàn 8'), findsOneWidget);
  });

  testWidgets('tap item opens edit sheet', (tester) async {
    await _pumpVoiceOrderPage(tester);
    await tester.pumpAndSettle();
    await _recognizeOrder(tester);

    expect(find.text('mi hai san'), findsOneWidget);

    await tester.tap(find.text('mi hai san'));
    await tester.pumpAndSettle();

    expect(find.text('Chỉnh sửa món'), findsOneWidget);
    expect(find.text('Tên món'), findsOneWidget);
    expect(find.text('Giá bán'), findsNothing);
    expect(find.text('Ghi chú'), findsOneWidget);
    expect(find.text('Hủy'), findsOneWidget);
    expect(find.text('Lưu'), findsOneWidget);
    expect(find.text('Kích cỡ'), findsOneWidget);
    expect(find.text('Topping'), findsOneWidget);
    expect(find.byIcon(Icons.remove_rounded), findsWidgets);
    expect(find.byIcon(Icons.add_rounded), findsWidgets);
  });

  testWidgets('tap item quantity plus increments without opening edit sheet', (
    tester,
  ) async {
    await _pumpVoiceOrderPage(tester);
    await tester.pumpAndSettle();
    await _recognizeOrder(tester);

    await tester.tap(find.byIcon(Icons.add_rounded).first);
    await tester.pumpAndSettle();

    expect(find.text('Chỉnh sửa món'), findsNothing);
    expect(find.text('SL 2'), findsOneWidget);
  });

  testWidgets('save edit sheet updates rendered item values', (tester) async {
    await _pumpVoiceOrderPage(tester);
    await tester.pumpAndSettle();
    await _recognizeOrder(tester);

    await tester.tap(find.text('mi hai san'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).at(1), 'mi xao bo');
    await tester.enterText(find.byType(TextField).last, 'it cay');
    await tester.tap(find.byIcon(Icons.add_rounded).last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Lưu'));
    await tester.pumpAndSettle();

    expect(find.text('Chỉnh sửa món'), findsNothing);
    expect(find.text('mi xao bo'), findsOneWidget);
    expect(find.text('Ghi chú: it cay'), findsOneWidget);
    expect(find.text('SL 2'), findsOneWidget);
  });

  testWidgets('renders missing fields and validation errors', (tester) async {
    await _pumpVoiceOrderPage(
      tester,
      repository: _FakeVoiceOrderRepository(
        recognition: _recognitionWithValidationErrors(),
      ),
    );
    await tester.pumpAndSettle();
    await _recognizeOrder(tester);

    expect(find.text('Thông tin còn thiếu'), findsOneWidget);
    expect(find.text('• table'), findsOneWidget);
    expect(find.text('Lỗi xác thực'), findsOneWidget);
    expect(find.text("• Không tìm thấy bàn 'Bàn 9'."), findsOneWidget);
  });

  testWidgets('product and table autocomplete suggestions can be selected', (
    tester,
  ) async {
    await _pumpVoiceOrderPage(tester);
    await tester.pumpAndSettle();
    await _recognizeOrder(tester);

    await tester.enterText(find.byType(TextField).first, '9');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Bàn 9').last);
    await tester.pumpAndSettle();

    expect(find.text('Bàn 9'), findsOneWidget);

    await tester.tap(find.text('mi hai san'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).at(1), 'Coca');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Coca cola').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Lưu'));
    await tester.pumpAndSettle();

    expect(find.text('Coca cola'), findsOneWidget);
  });

  testWidgets('permission denied microphone state renders message', (
    tester,
  ) async {
    await _pumpVoiceOrderPage(
      tester,
      recorder: _FakeVoiceOrderAudioRecorder(
        startError: const VoiceOrderRecorderPermissionException(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.press(find.byIcon(Icons.mic_rounded));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.mic_off_outlined), findsWidgets);
    expect(find.textContaining('microphone'), findsWidgets);
  });
}

Future<void> _recognizeOrder(WidgetTester tester) async {
  final gesture = await tester.startGesture(
    tester.getCenter(find.byIcon(Icons.mic_rounded)),
  );
  await tester.pump();
  await gesture.up();
  await tester.pumpAndSettle();
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
        voiceOrderProductsProvider(5).overrideWith((ref) async => _products),
        voiceOrderTablesProvider(5).overrideWith((ref) async => _tables),
        voiceOrderAudioRecorderProvider.overrideWithValue(
          recorder ?? _FakeVoiceOrderAudioRecorder(),
        ),
        voiceOrderSpeechPreviewServiceProvider.overrideWithValue(
          speechPreview ?? _FakeVoiceOrderSpeechPreviewService(),
        ),
      ],
      child: MaterialApp(
        theme: AppTheme.light,
        home: const VoiceOrderPage(storeId: 5),
      ),
    ),
  );
}

VoiceOrderRecognition _recognition() {
  return const VoiceOrderRecognition(
    storeId: 8,
    transcript: 'bàn tám gọi mì hải sản size nhỏ thêm trân châu',
    validationSucceeded: true,
    validationMessage: '',
    tableName: '8',
    items: [
      VoiceOrderItem(
        productId: null,
        productName: 'mi hai san',
        variantId: 36,
        variantName: 'nhỏ',
        quantity: 1,
        available: true,
        note: 'cay',
        toppings: [VoiceOrderTopping(id: 201, name: 'Trân châu', quantity: 2)],
      ),
      VoiceOrderItem(
        productId: null,
        productName: 'lau bo',
        quantity: 1,
        available: true,
      ),
    ],
    unmatchedItems: [],
  );
}

VoiceOrderRecognition _recognitionWithValidationErrors() {
  return const VoiceOrderRecognition(
    storeId: 5,
    transcript: 'bàn chín gọi chân gà',
    validationSucceeded: false,
    validationMessage: 'Order voice chưa hợp lệ.',
    tableName: null,
    missingFields: ['table'],
    errors: ["Không tìm thấy bàn 'Bàn 9'."],
    items: [
      VoiceOrderItem(
        productId: 23,
        productName: 'CHÂN GÀ RÚT XƯƠNG SỐT THÁI',
        variantId: 36,
        variantName: 'nhỏ',
        quantity: 1,
        available: true,
      ),
    ],
    unmatchedItems: [],
  );
}

final _products = [
  const Product(
    id: 23,
    storeId: 5,
    categoryId: 1,
    categoryName: 'Đồ ăn',
    name: 'mi hai san',
    imageUrl: '',
    description: '',
    preparationTime: 5,
    price: 35000,
    type: ProductType.food,
    variants: [
      ProductVariantDraft(id: 36, name: 'nhỏ', price: 35000, isDefault: true),
      ProductVariantDraft(id: 37, name: 'lớn', price: 45000, isDefault: false),
    ],
    toppings: [
      ProductTopping(
        id: 201,
        storeId: 5,
        name: 'Trân châu',
        price: 5000,
        isDeleted: false,
      ),
    ],
    isSell: true,
    isDeleted: false,
  ),
  const Product(
    id: 14,
    storeId: 5,
    categoryId: 2,
    categoryName: 'Đồ uống',
    name: 'Coca cola',
    imageUrl: '',
    description: '',
    preparationTime: 1,
    price: 15000,
    type: ProductType.drink,
    isSell: true,
    isDeleted: false,
  ),
];

const _tables = [
  DiningTable(
    id: 8,
    storeId: 5,
    areaId: 1,
    name: 'Bàn 8',
    capacity: 4,
    status: TableStatus.available,
    isDeleted: false,
  ),
  DiningTable(
    id: 9,
    storeId: 5,
    areaId: 1,
    name: 'Bàn 9',
    capacity: 4,
    status: TableStatus.available,
    isDeleted: false,
  ),
];

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
  address: 'Tang 1',
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
  final VoiceOrderRecognition? recognition;
  final Future<VoiceOrderRecognition>? recognitionFuture;

  _FakeVoiceOrderRepository({this.recognition, this.recognitionFuture});

  @override
  Future<VoiceOrderRecognition> recognizeAudioFile({
    required String audioFilePath,
    required int storeId,
  }) async {
    final future = recognitionFuture;
    if (future != null) {
      return future;
    }

    return recognition!;
  }
}

class _FakeVoiceOrderAudioRecorder implements VoiceOrderAudioRecorder {
  final Object? startError;
  int startCallCount = 0;

  _FakeVoiceOrderAudioRecorder({this.startError});

  @override
  Future<String> start() async {
    startCallCount += 1;
    final error = startError;
    if (error != null) {
      throw error;
    }

    return '/tmp/voice-order.wav';
  }

  @override
  Future<String?> stop() async => '/tmp/voice-order.wav';

  @override
  Future<void> cancel() async {}
}

class _FakeVoiceOrderSpeechPreviewService
    implements VoiceOrderSpeechPreviewService {
  @override
  Future<void> start({
    required void Function(String transcript) onTranscript,
    required void Function(String message) onUnavailable,
  }) async {}

  @override
  Future<void> stop() async {}

  @override
  Future<void> cancel() async {}
}
