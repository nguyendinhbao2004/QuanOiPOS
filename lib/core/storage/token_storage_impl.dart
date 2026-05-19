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
  Future<String?> getAccessToken() {
    return storage.read(key: _accessTokenKey);
  }

  @override
  Future<String?> getRefreshToken() {
    return storage.read(key: _refreshTokenKey);
  }

  @override
  Future<void> clear() async {
    await storage.deleteAll();
  }
}
