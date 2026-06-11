import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quan_oi/core/network/dio/dio_client.dart';
import 'package:quan_oi/features/store_operations/table_management/data/datasources/table_management_remote_data_source.dart';

void main() {
  group('TableManagementRemoteDataSource.closeTableSession', () {
    test('succeeds when response contains table session data', () async {
      final request = _CloseSessionRequestCapture();
      final dataSource = _dataSourceWithResponse(
        request,
        data: {
          'succeeded': true,
          'data': {'id': 501, 'tableId': 10, 'status': 2, 'isDeleted': false},
          'errors': <String>[],
        },
      );

      await dataSource.closeTableSession(501);

      expect(request.path, '/table-sessions/501/close');
      expect(request.method, 'PUT');
      expect(request.body, isNull);
    });

    test('succeeds when response data is null', () async {
      final dataSource = _dataSourceWithResponse(
        _CloseSessionRequestCapture(),
        data: {
          'succeeded': true,
          'message': 'Đóng phiên thành công',
          'data': null,
          'errors': <String>[],
        },
      );

      await expectLater(dataSource.closeTableSession(501), completes);
    });

    test('throws backend message when close fails', () async {
      final dataSource = _dataSourceWithResponse(
        _CloseSessionRequestCapture(),
        data: {
          'succeeded': false,
          'message': 'Phiên bàn không thể đóng',
          'data': null,
          'errors': <String>[],
        },
      );

      expect(
        () => dataSource.closeTableSession(501),
        throwsA(
          isA<Exception>().having(
            (error) => error.toString(),
            'message',
            contains('Phiên bàn không thể đóng'),
          ),
        ),
      );
    });
  });
}

TableManagementRemoteDataSource _dataSourceWithResponse(
  _CloseSessionRequestCapture request, {
  required Object? data,
}) {
  final dio = Dio();
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) {
        request
          ..path = options.path
          ..method = options.method
          ..body = options.data;
        handler.resolve(Response(requestOptions: options, data: data));
      },
    ),
  );
  return TableManagementRemoteDataSource(DioClient(dio));
}

class _CloseSessionRequestCapture {
  String? path;
  String? method;
  Object? body;
}
