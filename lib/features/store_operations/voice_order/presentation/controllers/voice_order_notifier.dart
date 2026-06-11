import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../order_management/domain/entities/create_order_draft.dart';
import '../../../order_management/domain/entities/order.dart';
import '../../../order_management/domain/usecases/create_order_use_case.dart';
import '../../../table_management/domain/entities/table_session.dart';
import '../../../table_management/domain/usecases/load_open_table_sessions_use_case.dart';
import '../../../table_management/domain/usecases/open_table_session_use_case.dart';
import '../../domain/entities/voice_order_item.dart';
import '../../domain/entities/voice_order_recognition.dart';
import '../../domain/entities/voice_order_topping.dart';
import '../../domain/usecases/recognize_voice_order_use_case.dart';
import '../../../order_management/presentation/providers/order_management_providers.dart';
import '../../../table_management/presentation/providers/table_management_providers.dart';
import '../providers/voice_order_providers.dart';
import '../services/voice_order_audio_recorder.dart';
import 'voice_order_state.dart';

class VoiceOrderMissingSessionException implements Exception {
  final int tableId;
  final String tableName;

  const VoiceOrderMissingSessionException({
    required this.tableId,
    required this.tableName,
  });

  @override
  String toString() => 'Bàn $tableName chưa có phiên đang mở.';
}

class VoiceOrderNotifier extends AutoDisposeNotifier<VoiceOrderState> {
  late final RecognizeVoiceOrderUseCase _recognizeVoiceOrder;
  late final VoiceOrderAudioRecorder _audioRecorder;
  late final LoadOpenTableSessionsUseCase _loadOpenTableSessions;
  late final OpenTableSessionUseCase _openTableSession;
  late final CreateOrderUseCase _createOrder;

  @override
  VoiceOrderState build() {
    _recognizeVoiceOrder = ref.read(recognizeVoiceOrderUseCaseProvider);
    _audioRecorder = ref.read(voiceOrderAudioRecorderProvider);
    _loadOpenTableSessions = ref.read(loadOpenTableSessionsUseCaseProvider);
    _openTableSession = ref.read(openTableSessionUseCaseProvider);
    _createOrder = ref.read(createOrderUseCaseProvider);
    ref.onDispose(() {
      _audioRecorder.cancel();
    });
    return const VoiceOrderState.idle();
  }

  Future<void> startRecording() async {
    if (state.isBusy || state.status == VoiceOrderStatus.recording) {
      return;
    }

    try {
      if (state.audioFilePath != null || state.recognition != null) {
        await _audioRecorder.cancel();
      }
      final audioFilePath = await _audioRecorder.start();
      state = VoiceOrderState(
        status: VoiceOrderStatus.recording,
        audioFilePath: audioFilePath,
      );
    } on VoiceOrderRecorderPermissionException catch (error) {
      state = VoiceOrderState(
        status: VoiceOrderStatus.permissionDenied,
        errorMessage: error.toString(),
      );
    } catch (error) {
      state = VoiceOrderState(
        status: VoiceOrderStatus.error,
        errorMessage: _errorMessage(error, 'Không thể bắt đầu ghi âm.'),
      );
    }
  }

  Future<void> stopRecording() async {
    if (state.status != VoiceOrderStatus.recording) {
      return;
    }

    try {
      final audioFilePath = await _audioRecorder.stop();
      state = VoiceOrderState(
        status: VoiceOrderStatus.readyToSend,
        audioFilePath: audioFilePath ?? state.audioFilePath,
        liveTranscript: state.liveTranscript,
        speechPreviewMessage: state.speechPreviewMessage,
      );
    } catch (error) {
      state = state.copyWith(
        status: VoiceOrderStatus.error,
        errorMessage: _errorMessage(error, 'Không thể dừng ghi âm.'),
      );
    }
  }

  Future<void> stopAndRecognize(int storeId) async {
    if (state.status != VoiceOrderStatus.recording) {
      return;
    }

    try {
      final audioFilePath = await _audioRecorder.stop();
      final pathToSend = audioFilePath ?? state.audioFilePath;
      if (pathToSend == null || pathToSend.trim().isEmpty) {
        state = state.copyWith(
          status: VoiceOrderStatus.error,
          errorMessage: 'Không tìm thấy file ghi âm.',
        );
        return;
      }

      state = VoiceOrderState(
        status: VoiceOrderStatus.recognizing,
        audioFilePath: pathToSend,
      );

      final recognition = await _recognizeVoiceOrder(
        audioFilePath: pathToSend,
        storeId: storeId,
      );
      state = VoiceOrderState(
        status: VoiceOrderStatus.success,
        audioFilePath: pathToSend,
        recognition: recognition,
      );
    } catch (error) {
      state = state.copyWith(
        status: VoiceOrderStatus.error,
        errorMessage: _errorMessage(
          error,
          'Không thể nhận diện đơn hàng bằng giọng nói.',
        ),
      );
    }
  }

  Future<void> recognize(int storeId) async {
    final audioFilePath = state.audioFilePath;
    if (audioFilePath == null || audioFilePath.trim().isEmpty || state.isBusy) {
      return;
    }

    state = state.copyWith(
      status: VoiceOrderStatus.recognizing,
      errorMessage: null,
    );

    try {
      final recognition = await _recognizeVoiceOrder(
        audioFilePath: audioFilePath,
        storeId: storeId,
      );
      state = VoiceOrderState(
        status: VoiceOrderStatus.success,
        audioFilePath: audioFilePath,
        recognition: recognition,
      );
    } catch (error) {
      state = state.copyWith(
        status: VoiceOrderStatus.error,
        errorMessage: _errorMessage(
          error,
          'Không thể nhận diện đơn hàng bằng giọng nói.',
        ),
      );
    }
  }

  Future<void> clear() async {
    await _audioRecorder.cancel();
    state = const VoiceOrderState.idle();
  }

  Future<Order> submit({
    required int storeId,
    required bool canCreateOrder,
  }) async {
    if (state.isBusy || state.status == VoiceOrderStatus.recording) {
      throw Exception('Vui lòng chờ thao tác hiện tại hoàn tất.');
    }
    if (!canCreateOrder) {
      throw Exception('Bạn chưa có quyền tạo đơn hàng.');
    }

    final recognition = _requireSubmittableRecognition();
    final tableId = recognition.tableId;
    if (tableId == null) {
      throw Exception('Vui lòng chọn bàn trước khi xác nhận.');
    }

    state = state.copyWith(
      status: VoiceOrderStatus.submitting,
      errorMessage: null,
    );

    try {
      final sessions = await _loadOpenTableSessions(tableId);
      final session = _firstOpenSession(sessions);
      if (session == null) {
        state = state.copyWith(status: VoiceOrderStatus.success);
        throw VoiceOrderMissingSessionException(
          tableId: tableId,
          tableName: _tableName(recognition),
        );
      }

      final order = await _createOrder(
        CreateOrderDraft(
          storeId: storeId,
          tableSessionId: session.id,
          items: _createOrderItems(recognition),
        ),
      );
      await clear();
      return order;
    } on VoiceOrderMissingSessionException {
      rethrow;
    } catch (error) {
      state = state.copyWith(
        status: VoiceOrderStatus.success,
        errorMessage: _errorMessage(error, 'Không thể tạo đơn hàng.'),
      );
      rethrow;
    }
  }

  Future<TableSession> openTableSession({
    required int tableId,
    required bool canOpenSession,
  }) async {
    if (state.isBusy) {
      throw Exception('Vui lòng chờ thao tác hiện tại hoàn tất.');
    }
    if (!canOpenSession) {
      throw Exception('Bạn chưa có quyền mở phiên bàn.');
    }

    state = state.copyWith(
      status: VoiceOrderStatus.submitting,
      errorMessage: null,
    );

    try {
      final session = await _openTableSession(tableId);
      state = state.copyWith(status: VoiceOrderStatus.success);
      return session;
    } catch (error) {
      state = state.copyWith(
        status: VoiceOrderStatus.success,
        errorMessage: _errorMessage(error, 'Không thể mở phiên bàn.'),
      );
      rethrow;
    }
  }

  void updateItem(
    VoiceOrderItem original, {
    Object? productId = _unchanged,
    required String productName,
    Object? variantId = _unchanged,
    Object? variantName = _unchanged,
    required int quantity,
    String? note,
    List<VoiceOrderTopping>? toppings,
  }) {
    final recognition = state.recognition;
    if (recognition == null) {
      return;
    }

    final itemIndex = recognition.items.indexOf(original);
    if (itemIndex < 0) {
      return;
    }

    final resolvedVariantId = variantId == _unchanged
        ? original.variantId
        : variantId as int?;
    final resolvedVariantName = variantName == _unchanged
        ? original.variantName
        : variantName as String?;
    final resolvedProductId = productId == _unchanged
        ? original.productId
        : productId as int?;
    final updatedItems = List<VoiceOrderItem>.of(recognition.items);
    updatedItems[itemIndex] = original.copyWith(
      productId: resolvedProductId,
      productName: productName.trim().isEmpty
          ? original.productName
          : productName.trim(),
      variantId: resolvedVariantId,
      variantName: resolvedVariantName,
      quantity: quantity < 1 ? 1 : quantity,
      note: note == null || note.trim().isEmpty ? null : note.trim(),
      toppings: toppings,
    );

    _setRecognition(recognition.copyWith(items: updatedItems));
  }

  void updateTable({int? tableId, String? tableName, String? tableStatus}) {
    final recognition = state.recognition;
    if (recognition == null) {
      return;
    }

    _setRecognition(
      recognition.copyWith(
        tableId: tableId,
        tableName: tableName == null || tableName.trim().isEmpty
            ? null
            : tableName.trim(),
        tableStatus: tableStatus,
      ),
    );
  }

  void increaseItemQuantity(VoiceOrderItem item) {
    updateItem(
      item,
      productName: item.productName,
      quantity: item.quantity + 1,
      note: item.note,
      toppings: item.toppings,
    );
  }

  void decreaseItemQuantity(VoiceOrderItem item) {
    updateItem(
      item,
      productName: item.productName,
      quantity: item.quantity <= 1 ? 1 : item.quantity - 1,
      note: item.note,
      toppings: item.toppings,
    );
  }

  void _setRecognition(VoiceOrderRecognition recognition) {
    state = state.copyWith(
      status: VoiceOrderStatus.success,
      recognition: recognition,
      errorMessage: null,
    );
  }

  String _errorMessage(Object error, String fallback) {
    final text = error.toString().replaceFirst('Exception: ', '').trim();
    return text.isEmpty ? fallback : text;
  }

  VoiceOrderRecognition _requireSubmittableRecognition() {
    final recognition = state.recognition;
    if (recognition == null) {
      throw Exception('Chưa có order để xác nhận.');
    }
    if (recognition.items.isEmpty) {
      throw Exception('Order phải có ít nhất một món.');
    }

    for (final item in recognition.items) {
      if (item.productId == null) {
        throw Exception('Món "${item.productName}" chưa có sản phẩm hợp lệ.');
      }
      if (item.quantity < 1) {
        throw Exception('Số lượng món "${item.productName}" phải lớn hơn 0.');
      }
      for (final topping in item.toppings) {
        if (topping.id == null || topping.quantity < 1) {
          throw Exception(
            'Topping của món "${item.productName}" không hợp lệ.',
          );
        }
      }
    }

    return recognition;
  }

  TableSession? _firstOpenSession(List<TableSession> sessions) {
    for (final session in sessions) {
      if (session.status == TableSessionStatus.open) {
        return session;
      }
    }
    return null;
  }

  List<CreateOrderItemDraft> _createOrderItems(
    VoiceOrderRecognition recognition,
  ) {
    final items = <CreateOrderItemDraft>[];
    for (final item in recognition.items) {
      for (var index = 0; index < item.quantity; index += 1) {
        items.add(
          CreateOrderItemDraft(
            productId: item.productId!,
            variantId: item.variantId,
            note: item.note?.trim().isEmpty == true ? null : item.note?.trim(),
            toppings: [
              for (final topping in item.toppings)
                if (topping.id != null && topping.quantity > 0)
                  CreateOrderToppingDraft(
                    toppingId: topping.id!,
                    quantity: topping.quantity,
                  ),
            ],
          ),
        );
      }
    }
    return items;
  }

  String _tableName(VoiceOrderRecognition recognition) {
    final tableName = recognition.tableName?.trim();
    if (tableName != null && tableName.isNotEmpty) {
      return tableName;
    }
    return recognition.tableId == null ? '' : '${recognition.tableId}';
  }
}

const Object _unchanged = Object();
