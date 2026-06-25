import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/di/injection.dart';
import '../../../../../core/network/dio/dio_client.dart';
import '../../data/datasources/inventory_stock_remote_data_source.dart';
import '../../data/repositories/inventory_stock_repository_impl.dart';
import '../../domain/repositories/inventory_stock_repository.dart';
import '../../domain/usecases/inventory_stock_use_cases.dart';
import '../controllers/inventory_stock_notifiers.dart';
import '../controllers/inventory_stock_state.dart';

final inventoryStockRemoteDataSourceProvider =
    Provider<InventoryStockRemoteDataSource>(
      (ref) => InventoryStockRemoteDataSource(locator<DioClient>()),
    );

final inventoryStockRepositoryProvider = Provider<InventoryStockRepository>(
  (ref) => InventoryStockRepositoryImpl(
    ref.read(inventoryStockRemoteDataSourceProvider),
  ),
);

final loadInventoryStockItemsUseCaseProvider =
    Provider<LoadInventoryStockItemsUseCase>(
      (ref) => LoadInventoryStockItemsUseCase(
        ref.read(inventoryStockRepositoryProvider),
      ),
    );

final loadInventoryMovementsUseCaseProvider =
    Provider<LoadInventoryMovementsUseCase>(
      (ref) => LoadInventoryMovementsUseCase(
        ref.read(inventoryStockRepositoryProvider),
      ),
    );

final inventoryStockListNotifierProvider = NotifierProvider.autoDispose
    .family<
      InventoryStockListNotifier,
      InventoryStockListState,
      InventoryStockListArgs
    >(InventoryStockListNotifier.new);

final inventoryMovementNotifierProvider = NotifierProvider.autoDispose
    .family<
      InventoryMovementNotifier,
      InventoryMovementState,
      InventoryMovementArgs
    >(InventoryMovementNotifier.new);
