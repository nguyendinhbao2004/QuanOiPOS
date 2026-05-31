import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quan_oi/core/network/dio/dio_client.dart';
import 'package:quan_oi/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:quan_oi/features/auth/data/models/change_password_request_model.dart';
import 'package:quan_oi/features/auth/data/models/update_current_user_profile_request_model.dart';
import 'package:quan_oi/features/auth/domain/entities/account_type.dart';

void main() {
  group('AuthRemoteDataSource.getCurrentUserProfile', () {
    test('gets and parses current user profile', () async {
      String? requestedPath;
      final dio = Dio();
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            requestedPath = options.path;
            handler.resolve(
              Response(
                requestOptions: options,
                data: {
                  'succeeded': true,
                  'message': 'Lấy thông tin người dùng hiện tại thành công',
                  'data': {
                    'id': 9,
                    'email': 'k92kiet@gmail.com',
                    'fullName': 'kiethnt',
                    'phone': '0707834552',
                    'accountType': 'StoreUser',
                    'status': 'Active',
                    'lastLogin': '2026-05-31T17:22:13.07183Z',
                  },
                  'errors': <String>[],
                },
              ),
            );
          },
        ),
      );

      final dataSource = AuthRemoteDataSource(DioClient(dio));

      final profile = await dataSource.getCurrentUserProfile();

      expect(requestedPath, '/auth/me');
      expect(profile.accountId, 9);
      expect(profile.email, 'k92kiet@gmail.com');
      expect(profile.fullName, 'kiethnt');
      expect(profile.phone, '0707834552');
      expect(profile.accountType, AccountType.storeUser);
      expect(profile.status, 'Active');
      expect(profile.lastLogin, DateTime.parse('2026-05-31T17:22:13.07183Z'));
    });

    test('throws backend message when loading profile fails', () async {
      final dio = Dio();
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            handler.resolve(
              Response(
                requestOptions: options,
                data: {
                  'succeeded': false,
                  'message': 'Không thể tải thông tin cá nhân',
                  'data': null,
                  'errors': <String>[],
                },
              ),
            );
          },
        ),
      );

      final dataSource = AuthRemoteDataSource(DioClient(dio));

      expect(
        dataSource.getCurrentUserProfile,
        throwsA(
          isA<Exception>().having(
            (error) => error.toString(),
            'message',
            contains('Không thể tải thông tin cá nhân'),
          ),
        ),
      );
    });
  });

  group('AuthRemoteDataSource.updateCurrentUserProfile', () {
    test('puts editable profile fields to profile endpoint', () async {
      String? requestedPath;
      Object? requestBody;
      final dio = Dio();
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            requestedPath = options.path;
            requestBody = options.data;
            handler.resolve(
              Response(
                requestOptions: options,
                data: {
                  'succeeded': true,
                  'message': 'Profile updated',
                  'data': null,
                  'errors': <String>[],
                },
              ),
            );
          },
        ),
      );

      final dataSource = AuthRemoteDataSource(DioClient(dio));

      await dataSource.updateCurrentUserProfile(
        const UpdateCurrentUserProfileRequestModel(
          fullName: 'Quan Oi User',
          phone: '0707834552',
        ),
      );

      expect(requestedPath, '/auth/me');
      expect(requestBody, {'fullName': 'Quan Oi User', 'phone': '0707834552'});
    });
  });

  group('AuthRemoteDataSource.changePassword', () {
    test(
      'posts current and new password to change password endpoint',
      () async {
        String? requestedPath;
        Object? requestBody;
        final dio = Dio();
        dio.interceptors.add(
          InterceptorsWrapper(
            onRequest: (options, handler) {
              requestedPath = options.path;
              requestBody = options.data;
              handler.resolve(
                Response(
                  requestOptions: options,
                  data: {
                    'succeeded': true,
                    'message': 'Password changed',
                    'data': null,
                    'errors': <String>[],
                  },
                ),
              );
            },
          ),
        );

        final dataSource = AuthRemoteDataSource(DioClient(dio));

        await dataSource.changePassword(
          const ChangePasswordRequestModel(
            currentPassword: 'OldP@ssw0rd123',
            newPassword: 'NewP@ssw0rd123',
          ),
        );

        expect(requestedPath, '/auth/change-password');
        expect(requestBody, {
          'currentPassword': 'OldP@ssw0rd123',
          'newPassword': 'NewP@ssw0rd123',
        });
      },
    );

    test('throws backend message when change password fails', () async {
      final dio = Dio();
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            handler.resolve(
              Response(
                requestOptions: options,
                data: {
                  'succeeded': false,
                  'message': 'Mật khẩu hiện tại không đúng',
                  'data': null,
                  'errors': <String>[],
                },
              ),
            );
          },
        ),
      );

      final dataSource = AuthRemoteDataSource(DioClient(dio));

      expect(
        () => dataSource.changePassword(
          const ChangePasswordRequestModel(
            currentPassword: 'wrong-pass',
            newPassword: 'NewP@ssw0rd123',
          ),
        ),
        throwsA(
          isA<Exception>().having(
            (error) => error.toString(),
            'message',
            contains('Mật khẩu hiện tại không đúng'),
          ),
        ),
      );
    });
  });
}
