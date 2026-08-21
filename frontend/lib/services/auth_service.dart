import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import 'api_client.dart';

class AuthService {
  final ApiClient _apiClient;
  static const String _keyToken = 'access_token';
  static const String _keyRefresh = 'refresh_token';

  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  AuthService(this._apiClient);

  Future<void> saveTokens({required String accessToken, String? refreshToken}) async {
    _apiClient.setAuthToken(accessToken);
    if (!kIsWeb) {
      await _secureStorage.write(key: _keyToken, value: accessToken);
      if (refreshToken != null) {
        await _secureStorage.write(key: _keyRefresh, value: refreshToken);
      }
    } else {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyToken, accessToken);
      if (refreshToken != null) {
        await prefs.setString(_keyRefresh, refreshToken);
      }
    }
  }

  Future<String?> getAccessToken() async {
    if (!kIsWeb) {
      return await _secureStorage.read(key: _keyToken);
    } else {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_keyToken);
    }
  }

  Future<String?> getRefreshToken() async {
    if (!kIsWeb) {
      return await _secureStorage.read(key: _keyRefresh);
    } else {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_keyRefresh);
    }
  }

  Future<void> clearTokens() async {
    _apiClient.setAuthToken(null);
    if (!kIsWeb) {
      await _secureStorage.delete(key: _keyToken);
      await _secureStorage.delete(key: _keyRefresh);
    } else {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_keyToken);
      await prefs.remove(_keyRefresh);
    }
  }

  Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await _apiClient.post('/api/auth/login', body: {
      'email': email,
      'password': password,
    });
    
    if (response is Map<String, dynamic> && response.containsKey('access_token')) {
      final token = response['access_token'];
      final refresh = response['refresh_token'];
      await saveTokens(accessToken: token, refreshToken: refresh);
    }
    return response;
  }

  Future<Map<String, dynamic>> register(String email, String password) async {
    final response = await _apiClient.post('/api/auth/register', body: {
      'email': email,
      'password': password,
    });
    return response;
  }

  Future<void> logout() async {
    try {
      await _apiClient.post('/api/auth/logout');
    } catch (_) {}
    await clearTokens();
  }
}
