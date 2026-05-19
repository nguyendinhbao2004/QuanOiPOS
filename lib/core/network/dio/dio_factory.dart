import 'package:dio/dio.dart';
import '../../storage/token_storage.dart';
import '../../network/interceptors/auth_interceptor.dart';
import '../../network/interceptors/refresh_token_interceptor.dart';
import '../../network/interceptors/logging_interceptor.dart';
import 'dio_options.dart';
import 'package:logger/logger.dart';

class DioFactory {
  static Dio createDio({
    required TokenStorage tokenStorage,
    required Logger logger,
    required bool enableLogging,
  }) {
    final dio = Dio(DioOptions.build());

    dio.interceptors.addAll([
      createLoggingInterceptor(enabled: enableLogging),
      AuthInterceptor(tokenStorage),
      RefreshTokenInterceptor(dio: dio, tokenStorage: tokenStorage),
    ]);

    return dio;
  }
}
