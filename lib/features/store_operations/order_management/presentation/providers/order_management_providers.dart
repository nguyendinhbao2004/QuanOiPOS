import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/di/injection.dart';
import '../../data/datasources/order_management_remote_data_source.dart';
import '../../domain/repositories/order_management_repository.dart';
import '../../domain/usecases/create_order_use_case.dart';
import '../../domain/usecases/load_order_detail_use_case.dart';
import '../../domain/usecases/load_orders_by_table_session_use_case.dart';
import '../controllers/order_notifiers.dart';
import '../controllers/order_states.dart';

final orderManagementRemoteDataSourceProvider =
    Provider<OrderManagementRemoteDataSource>((ref) {
      return locator<OrderManagementRemoteDataSource>();
    });

final orderManagementRepositoryProvider = Provider<OrderManagementRepository>((
  ref,
) {
  return locator<OrderManagementRepository>();
});

final loadOrdersByTableSessionUseCaseProvider =
    Provider<LoadOrdersByTableSessionUseCase>((ref) {
      return locator<LoadOrdersByTableSessionUseCase>();
    });

final loadOrderDetailUseCaseProvider = Provider<LoadOrderDetailUseCase>((ref) {
  return locator<LoadOrderDetailUseCase>();
});

final createOrderUseCaseProvider = Provider<CreateOrderUseCase>((ref) {
  return locator<CreateOrderUseCase>();
});

final orderListNotifierProvider = NotifierProvider.autoDispose
    .family<OrderListNotifier, OrderListState, OrderSessionAccess>(
      OrderListNotifier.new,
    );

final orderDetailNotifierProvider = NotifierProvider.autoDispose
    .family<OrderDetailNotifier, OrderDetailState, OrderDetailAccess>(
      OrderDetailNotifier.new,
    );

final orderCreateNotifierProvider = NotifierProvider.autoDispose
    .family<OrderCreateNotifier, OrderCreateState, OrderSessionAccess>(
      OrderCreateNotifier.new,
    );
