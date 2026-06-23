import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/di/injection.dart';
import '../../data/datasources/kitchen_remote_data_source.dart';
import '../../domain/repositories/kitchen_repository.dart';
import '../../domain/usecases/bulk_cancel_kitchen_items_use_case.dart';
import '../../domain/usecases/bulk_update_kitchen_items_use_case.dart';
import '../../domain/usecases/cancel_kitchen_item_use_case.dart';
import '../../domain/usecases/load_kitchen_items_use_case.dart';
import '../../domain/usecases/update_kitchen_item_status_use_case.dart';
import '../controllers/kitchen_notifier.dart';
import '../controllers/kitchen_state.dart';

final kitchenRemoteDataSourceProvider = Provider<KitchenRemoteDataSource>((ref) {
  return locator<KitchenRemoteDataSource>();
});

final kitchenRepositoryProvider = Provider<KitchenRepository>((ref) {
  return locator<KitchenRepository>();
});

final loadKitchenItemsUseCaseProvider = Provider<LoadKitchenItemsUseCase>((ref) {
  return locator<LoadKitchenItemsUseCase>();
});

final updateKitchenItemStatusUseCaseProvider =
    Provider<UpdateKitchenItemStatusUseCase>((ref) {
      return locator<UpdateKitchenItemStatusUseCase>();
    });

final cancelKitchenItemUseCaseProvider =
    Provider<CancelKitchenItemUseCase>((ref) {
      return locator<CancelKitchenItemUseCase>();
    });

final bulkUpdateKitchenItemsUseCaseProvider =
    Provider<BulkUpdateKitchenItemsUseCase>((ref) {
      return locator<BulkUpdateKitchenItemsUseCase>();
    });

final bulkCancelKitchenItemsUseCaseProvider =
    Provider<BulkCancelKitchenItemsUseCase>((ref) {
      return locator<BulkCancelKitchenItemsUseCase>();
    });

final kitchenNotifierProvider = NotifierProvider.autoDispose
    .family<KitchenNotifier, KitchenState, KitchenAccess>(KitchenNotifier.new);
