import 'package:dio/dio.dart';
import '../../storage/token_storage.dart';

class RefreshTokenInterceptor extends Interceptor {
  final Dio dio;
  final TokenStorage tokenStorage;

  RefreshTokenInterceptor({required this.dio, required this.tokenStorage});

  @override
  Future<void> onError(DioException err, ErrorInterceptorHandler handler) async {
    final status = err.response?.statusCode;
    if (status == 401) {
      try {
        final refreshToken = await tokenStorage.getRefreshToken();
        if (refreshToken == null) {
          await tokenStorage.clear();
          return handler.next(err);
        }

        final response = await dio.post(
          '/auth/refresh',
          data: {'refresh_token': refreshToken},
        );

        final resp = response.data;

        Map<String, dynamic>? map;
        if (resp is Map<String, dynamic>) {
          map = resp;
        }

        // support wrapped response: { data: { accessToken: '...' } }
        String? newAccessToken;
        if (map != null) {
          // top-level
          newAccessToken = (map['access_token'] ?? map['accessToken']) as String?;

          // nested under `data`
          if (newAccessToken == null) {
            final nested = map['data'];
            if (nested is Map<String, dynamic>) {
              newAccessToken = (nested['access_token'] ?? nested['accessToken']) as String?;
            }
          }
        }

        if (newAccessToken != null && newAccessToken.isNotEmpty) {
          await tokenStorage.saveAccessToken(newAccessToken);

          // retry original request
          final clonedRequest = await dio.fetch(err.requestOptions);
          return handler.resolve(clonedRequest);
        }
      } catch (_) {
        await tokenStorage.clear();
      }
    }

    handler.next(err);
  }
}
