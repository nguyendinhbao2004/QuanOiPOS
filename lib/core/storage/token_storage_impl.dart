import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'token_storage.dart';

class TokenStorageImpl implements TokenStorage {
  final FlutterSecureStorage storage;

  TokenStorageImpl(this.storage);

  static const _accessTokenKey = 'access_token';
  static const _refreshTokenKey = 'refresh_token';

  @override
  Future<void> saveAccessToken(String token) {
    return storage.write(key: _accessTokenKey, value: token);
  }

  @override
  Future<void> saveRefreshToken(String token) {
    return storage.write(key: _refreshTokenKey, value: token);
  }

  @override
  Future<String?> getAccessToken() => _readToken(_accessTokenKey);

  @override
  Future<String?> getRefreshToken() => _readToken(_refreshTokenKey);

  @override
  Future<void> clear() async {
    await storage.delete(key: _accessTokenKey);
    await storage.delete(key: _refreshTokenKey);
  }

  Future<String?> _readToken(String key) async {
    try {
      return await storage.read(key: key);
    } on PlatformException catch (error) {
      if (!_isRecoverableReadError(error)) {
        rethrow;
      }

      await storage.delete(key: key);
      return null;
    }
  }

  bool _isRecoverableReadError(PlatformException error) {
    final message = '${error.code} ${error.message} ${error.details}'
        .toUpperCase();
    return message.contains('BAD_DECRYPT') ||
        message.contains('FAILED TO UNWRAP KEY') ||
        message.contains('INVALIDKEYEXCEPTION');
  }
}
