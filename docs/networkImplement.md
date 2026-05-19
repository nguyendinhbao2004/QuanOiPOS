# Flutter Enterprise Network + Auth Architecture Guideline

> Standard enterprise architecture for Flutter applications.
> All AI-generated code must follow this document.

---

# 1. Core Principles

## MUST

- Use Dio as HTTP client
- Use Repository Pattern
- Separate layers clearly
- Use centralized error handling
- Use interceptor for auth/logging
- Use immutable models
- Use environment variables for base URL
- Use secure storage for tokens
- Use typed response models
- Use timeout for all requests
- Use clean architecture
- Use Riverpod for state management
- Use dependency injection
- Use offline-capable architecture

---

## MUST NOT

- Do NOT call API directly inside Widgets/UI
- Do NOT hardcode tokens
- Do NOT hardcode base URLs
- Do NOT use dynamic everywhere
- Do NOT parse JSON manually in UI
- Do NOT store auth token in SharedPreferences
- Do NOT put business logic in interceptors
- Do NOT throw generic Exception()
- Do NOT put Dio inside controllers
- Do NOT mix repository and datasource responsibilities

---

# 2. Recommended Stack

```yaml
dio
flutter_secure_storage
freezed
json_serializable
riverpod
dartz
get_it
injectable
logger
pretty_dio_logger
flutter_dotenv
```

---

# 3. Recommended Folder Structure

```txt
lib/
├── core/
│   ├── network/
│   │   ├── dio/
│   │   │   ├── dio_client.dart
│   │   │   ├── dio_options.dart
│   │   │   └── dio_factory.dart
│   │   │
│   │   ├── interceptors/
│   │   │   ├── auth_interceptor.dart
│   │   │   ├── refresh_token_interceptor.dart
│   │   │   └── logging_interceptor.dart
│   │   │
│   │   ├── exceptions/
│   │   │   └── api_exception.dart
│   │   │
│   │   ├── failures/
│   │   │   └── network_failure.dart
│   │   │
│   │   ├── responses/
│   │   │   └── api_response.dart
│   │   │
│   │   └── mappers/
│   │       └── dio_error_mapper.dart
│   │
│   ├── storage/
│   ├── env/
│   └── utils/
│
├── features/
│   └── auth/
```

---

# 4. Environment Configuration

# env/.env.dev

```env
BASE_URL=https://dev-api.example.com
```

---

# env/.env.prod

```env
BASE_URL=https://api.example.com
```

---

# env/env.dart

```dart
class Env {

  static String get baseUrl {
    return dotenv.env['BASE_URL'] ?? '';
  }
}
```

---

# 5. Secure Token Storage

# token_storage.dart

```dart
abstract class TokenStorage {

  Future<void> saveAccessToken(
    String token,
  );

  Future<void> saveRefreshToken(
    String token,
  );

  Future<String?> getAccessToken();

  Future<String?> getRefreshToken();

  Future<void> clear();
}
```

---

# token_storage_impl.dart

```dart
class TokenStorageImpl
    implements TokenStorage {

  final FlutterSecureStorage storage;

  TokenStorageImpl(this.storage);

  static const _accessTokenKey =
      'access_token';

  static const _refreshTokenKey =
      'refresh_token';

  @override
  Future<void> saveAccessToken(
    String token,
  ) {
    return storage.write(
      key: _accessTokenKey,
      value: token,
    );
  }

  @override
  Future<void> saveRefreshToken(
    String token,
  ) {
    return storage.write(
      key: _refreshTokenKey,
      value: token,
    );
  }

  @override
  Future<String?> getAccessToken() {
    return storage.read(
      key: _accessTokenKey,
    );
  }

  @override
  Future<String?> getRefreshToken() {
    return storage.read(
      key: _refreshTokenKey,
    );
  }

  @override
  Future<void> clear() async {
    await storage.deleteAll();
  }
}
```

---

# 6. Dio Options

# dio_options.dart

```dart
class DioOptions {

  static BaseOptions build() {

    return BaseOptions(
      baseUrl: Env.baseUrl,

      connectTimeout:
          const Duration(seconds: 30),

      receiveTimeout:
          const Duration(seconds: 30),

      sendTimeout:
          const Duration(seconds: 30),

      headers: {
        'Accept': 'application/json',
        'Content-Type':
            'application/json',
      },
    );
  }
}
```

---

# 7. Logging Interceptor

# logging_interceptor.dart

```dart
class LoggingInterceptor
    extends Interceptor {

  final Logger logger;

  LoggingInterceptor(this.logger);

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) {

    logger.i(
      '[REQUEST] ${options.method} ${options.path}',
    );

    super.onRequest(options, handler);
  }

  @override
  void onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) {

    logger.e(
      '[ERROR] ${err.requestOptions.path}',
    );

    super.onError(err, handler);
  }
}
```

---

# 8. Auth Interceptor

# auth_interceptor.dart

```dart
class AuthInterceptor
    extends Interceptor {

  final TokenStorage tokenStorage;

  AuthInterceptor(this.tokenStorage);

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {

    final token =
        await tokenStorage.getAccessToken();

    if (token != null) {

      options.headers['Authorization'] =
          'Bearer $token';
    }

    handler.next(options);
  }
}
```

---

# 9. Refresh Token Interceptor

# refresh_token_interceptor.dart

```dart
class RefreshTokenInterceptor
    extends Interceptor {

  final Dio dio;
  final TokenStorage tokenStorage;

  RefreshTokenInterceptor({
    required this.dio,
    required this.tokenStorage,
  });

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {

    if (err.response?.statusCode == 401) {

      try {

        final refreshToken =
            await tokenStorage
                .getRefreshToken();

        final response = await dio.post(
          '/auth/refresh',
          data: {
            'refresh_token':
                refreshToken,
          },
        );

        final newAccessToken =
            response.data['access_token'];

        await tokenStorage
            .saveAccessToken(
          newAccessToken,
        );

        final clonedRequest =
            await dio.fetch(
          err.requestOptions,
        );

        return handler.resolve(
          clonedRequest,
        );

      } catch (_) {

        await tokenStorage.clear();
      }
    }

    handler.next(err);
  }
}
```

---

# IMPORTANT RULE

## Interceptor MUST NOT

❌ contain business logic

❌ navigate UI

❌ show snackbar

❌ parse entities

❌ call repositories

---

# 10. Dio Factory

# dio_factory.dart

```dart
class DioFactory {

  static Dio create({
    required TokenStorage tokenStorage,
    required Logger logger,
  }) {

    final dio = Dio(
      DioOptions.build(),
    );

    dio.interceptors.addAll([
      LoggingInterceptor(logger),
      AuthInterceptor(tokenStorage),

      RefreshTokenInterceptor(
        dio: dio,
        tokenStorage: tokenStorage,
      ),
    ]);

    return dio;
  }
}
```

---

# 11. Centralized API Exception

# api_exception.dart

```dart
class ApiException
    implements Exception {

  final String message;
  final int? statusCode;

  ApiException({
    required this.message,
    this.statusCode,
  });
}
```

---

# 12. Dio Error Mapper

# dio_error_mapper.dart

```dart
class DioErrorMapper {

  static ApiException map(
    DioException error,
  ) {

    switch (error.type) {

      case DioExceptionType.connectionTimeout:
        return ApiException(
          message: 'Connection timeout',
        );

      case DioExceptionType.receiveTimeout:
        return ApiException(
          message: 'Receive timeout',
        );

      default:
        return ApiException(
          message:
              error.response?.data['message']
              ?? 'Unknown error',
          statusCode:
              error.response?.statusCode,
        );
    }
  }
}
```

---

# 13. Generic API Response

# api_response.dart

```dart
class ApiResponse<T> {

  final bool success;
  final T data;
  final String? message;

  ApiResponse({
    required this.success,
    required this.data,
    this.message,
  });
}
```

---