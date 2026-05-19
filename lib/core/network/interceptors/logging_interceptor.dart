import 'package:pretty_dio_logger/pretty_dio_logger.dart';
import 'package:dio/dio.dart';

Interceptor createLoggingInterceptor({required bool enabled}) {
  if (!enabled) return InterceptorsWrapper();

  return PrettyDioLogger(
    requestHeader: true,
    requestBody: true,
    responseBody: true,
    responseHeader: false,
    compact: true,
  );
}
