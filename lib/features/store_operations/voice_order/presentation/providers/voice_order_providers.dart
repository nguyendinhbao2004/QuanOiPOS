import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/di/injection.dart';
import '../../../product_management/domain/entities/product.dart';
import '../../../product_management/presentation/providers/product_management_providers.dart';
import '../../../table_management/domain/entities/dining_table.dart';
import '../../../table_management/domain/usecases/load_table_groups_use_case.dart';
import '../../../table_management/presentation/providers/table_management_providers.dart';
import '../../data/datasources/voice_order_remote_data_source.dart';
import '../../domain/repositories/voice_order_repository.dart';
import '../../domain/usecases/recognize_voice_order_use_case.dart';
import '../controllers/voice_order_notifier.dart';
import '../controllers/voice_order_state.dart';
import '../services/voice_order_audio_recorder.dart';
import '../services/voice_order_speech_preview_service.dart';

final voiceOrderRemoteDataSourceProvider = Provider<VoiceOrderRemoteDataSource>(
  (ref) {
    return locator<VoiceOrderRemoteDataSource>();
  },
);

final voiceOrderRepositoryProvider = Provider<VoiceOrderRepository>((ref) {
  return locator<VoiceOrderRepository>();
});

final recognizeVoiceOrderUseCaseProvider = Provider<RecognizeVoiceOrderUseCase>(
  (ref) {
    return locator<RecognizeVoiceOrderUseCase>();
  },
);

final voiceOrderAudioRecorderProvider = Provider<VoiceOrderAudioRecorder>((
  ref,
) {
  return RecordVoiceOrderAudioRecorder();
});

final voiceOrderSpeechPreviewServiceProvider =
    Provider<VoiceOrderSpeechPreviewService>((ref) {
      return SpeechToTextVoiceOrderSpeechPreviewService();
    });

final voiceOrderProductsProvider = FutureProvider.autoDispose
    .family<List<Product>, int>((ref, storeId) {
      final loadProducts = ref.watch(loadProductsUseCaseProvider);
      return loadProducts(storeId);
    });

final voiceOrderTablesProvider = FutureProvider.autoDispose
    .family<List<DiningTable>, int>((ref, storeId) {
      final loadTableGroups = ref.watch(loadTableGroupsUseCaseProvider);
      return _loadVoiceOrderTables(loadTableGroups, storeId);
    });

final voiceOrderNotifierProvider =
    NotifierProvider.autoDispose<VoiceOrderNotifier, VoiceOrderState>(
      VoiceOrderNotifier.new,
    );

Future<List<DiningTable>> _loadVoiceOrderTables(
  LoadTableGroupsUseCase loadTableGroups,
  int storeId,
) async {
  final groups = await loadTableGroups(storeId: storeId);
  return [
    for (final group in groups)
      for (final table in group.tables)
        if (!table.isDeleted) table,
  ];
}
