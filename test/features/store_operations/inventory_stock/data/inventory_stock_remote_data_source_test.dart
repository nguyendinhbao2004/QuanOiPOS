import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quan_oi/core/network/dio/dio_client.dart';
import 'package:quan_oi/features/store_operations/inventory_stock/data/datasources/inventory_stock_remote_data_source.dart';
import 'package:quan_oi/features/store_operations/inventory_stock/domain/entities/inventory_stock.dart';

void main() {
  test('calls product list endpoint and unwraps API envelope', () async {
    late RequestOptions captured;
    final dataSource = _dataSource((options) {
      captured = options;
      return Response<dynamic>(
        requestOptions: options,
        statusCode: 200,
        data: {
          'succeeded': true,
          'data': [
            {'id': 20, 'storeId': 5, 'name': 'Coca', 'quantity': 4},
          ],
        },
      );
    });

    final items = await dataSource.getItems(
      storeId: 5,
      type: InventoryStockItemType.product,
      status: InventoryStockStatus.low,
    );

    expect(captured.path, '/inventory/products');
    expect(captured.queryParameters, {'storeId': 5, 'status': 'low'});
    expect(items.single.toEntity().name, 'Coca');
  });

  test('calls ingredient movement endpoint with date range', () async {
    late RequestOptions captured;
    final dataSource = _dataSource((options) {
      captured = options;
      return Response<dynamic>(
        requestOptions: options,
        statusCode: 200,
        data: {
          'succeeded': true,
          'data': [
            {'id': 1, 'ingredientId': 10, 'type': 'Import'},
          ],
        },
      );
    });

    final movements = await dataSource.getMovements(
      type: InventoryStockItemType.ingredient,
      itemId: 10,
      from: DateTime.utc(2026, 6),
      to: DateTime.utc(2026, 6, 25),
    );

    expect(captured.path, '/inventory/ingredients/10/movements');
    expect(captured.queryParameters['from'], '2026-06-01T00:00:00.000Z');
    expect(captured.queryParameters['to'], '2026-06-25T00:00:00.000Z');
    expect(movements.single.toEntity().ingredientId, 10);
  });

  test('surfaces envelope message when API returns succeeded false', () async {
    final dataSource = _dataSource((options) {
      return Response<dynamic>(
        requestOptions: options,
        statusCode: 200,
        data: {'succeeded': false, 'message': 'Không có quyền'},
      );
    });

    await expectLater(
      dataSource.getItems(
        storeId: 5,
        type: InventoryStockItemType.product,
        status: InventoryStockStatus.all,
      ),
      throwsA(
        predicate((error) => error.toString().contains('Không có quyền')),
      ),
    );
  });
}

InventoryStockRemoteDataSource _dataSource(
  Response<dynamic> Function(RequestOptions options) handler,
) {
  final dio = Dio();
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, interceptor) {
        interceptor.resolve(handler(options));
      },
    ),
  );
  return InventoryStockRemoteDataSource(DioClient(dio));
}
