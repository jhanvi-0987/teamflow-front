import 'package:flutter_secure_storage/flutter_secure_storage.dart';

abstract class TokenStorage {
  Future<void> saveTokens({required String accessToken, required String refreshToken});
  Future<String?> getAccessToken();
  Future<String?> getRefreshToken();
  Future<void> saveUser(String userJson);
  Future<String?> getUser();
  Future<void> clearTokens();
}

class SecureTokenStorage implements TokenStorage {
  final FlutterSecureStorage _storage;

  static const _accessKey = 'teamflow_access_token';
  static const _refreshKey = 'teamflow_refresh_token';
  static const _userKey = 'teamflow_user_data';

  SecureTokenStorage([FlutterSecureStorage? storage])
      : _storage = storage ?? const FlutterSecureStorage();

  @override
  Future<void> saveTokens({required String accessToken, required String refreshToken}) async {
    await _storage.write(key: _accessKey, value: accessToken);
    await _storage.write(key: _refreshKey, value: refreshToken);
  }

  @override
  Future<String?> getAccessToken() async {
    return _storage.read(key: _accessKey);
  }

  @override
  Future<String?> getRefreshToken() async {
    return _storage.read(key: _refreshKey);
  }

  @override
  Future<void> saveUser(String userJson) async {
    await _storage.write(key: _userKey, value: userJson);
  }

  @override
  Future<String?> getUser() async {
    return _storage.read(key: _userKey);
  }

  @override
  Future<void> clearTokens() async {
    await _storage.delete(key: _accessKey);
    await _storage.delete(key: _refreshKey);
    await _storage.delete(key: _userKey);
  }
}

class InMemoryTokenStorage implements TokenStorage {
  String? _accessToken;
  String? _refreshToken;
  String? _userJson;

  @override
  Future<void> saveTokens({required String accessToken, required String refreshToken}) async {
    _accessToken = accessToken;
    _refreshToken = refreshToken;
  }

  @override
  Future<String?> getAccessToken() async => _accessToken;

  @override
  Future<String?> getRefreshToken() async => _refreshToken;

  @override
  Future<void> saveUser(String userJson) async {
    _userJson = userJson;
  }

  @override
  Future<String?> getUser() async => _userJson;

  @override
  Future<void> clearTokens() async {
    _accessToken = null;
    _refreshToken = null;
    _userJson = null;
  }
}
