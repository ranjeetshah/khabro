import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Secure storage wrapper for JWT access tokens.
class TokenStorage {
  TokenStorage({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  static const String _tokenKey = 'access_token';

  final FlutterSecureStorage _storage;

  /// Save the access token securely.
  Future<void> saveAccessToken(String token) {
    return _storage.write(key: _tokenKey, value: token);
  }

  /// Retrieve the stored access token, or null if none.
  Future<String?> getAccessToken() {
    return _storage.read(key: _tokenKey);
  }

  /// Delete the stored access token.
  Future<void> deleteAccessToken() {
    return _storage.delete(key: _tokenKey);
  }
}
