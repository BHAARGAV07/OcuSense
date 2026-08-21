import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/api_client.dart';
import '../services/personalization_service.dart';

enum AuthStatus { uninitialized, authenticated, unauthenticated }

class AuthProvider extends ChangeNotifier {
  final AuthService _authService;
  final ApiClient _apiClient;
  final PersonalizationService _personalizationService;

  AuthStatus _status = AuthStatus.uninitialized;
  bool _isLoading = false;
  bool _isOnboarded = true;
  String? _errorMessage;

  AuthProvider(this._authService, this._apiClient, {PersonalizationService? personalizationService})
      : _personalizationService = personalizationService ?? PersonalizationService(_apiClient) {
    _setupAuthHandlers();
  }

  void _setupAuthHandlers() {
    _apiClient.setAuthHandlers(
      onRefreshToken: () => _authService.refreshToken(),
      onUnauthenticated: () {
        _status = AuthStatus.unauthenticated;
        notifyListeners();
      },
    );
  }

  AuthStatus get status => _status;
  bool get isAuthenticated => _status == AuthStatus.authenticated;
  bool get isOnboarded => _isOnboarded;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> checkOnboardingStatus() async {
    try {
      final profile = await _personalizationService.getProfile();
      _isOnboarded = profile.isOnboarded;
      notifyListeners();
    } catch (_) {
      _isOnboarded = true; // Fallback to avoid blocking
    }
  }

  Future<void> initializeAuth() async {
    _isLoading = true;
    notifyListeners();

    try {
      final token = await _authService.getAccessToken();
      if (token != null && token.isNotEmpty) {
        _apiClient.setAuthToken(token);
        _status = AuthStatus.authenticated;
        await checkOnboardingStatus();
      } else {
        _status = AuthStatus.unauthenticated;
      }
    } catch (_) {
      _status = AuthStatus.unauthenticated;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _authService.login(email, password);
      _status = AuthStatus.authenticated;
      await checkOnboardingStatus();
      _isLoading = false;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'An unexpected login error occurred.';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> register(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _authService.register(email, password);
      // Auto login after successful registration
      return await login(email, password);
    } on ApiException catch (e) {
      _errorMessage = e.message;
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'An unexpected registration error occurred.';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();
    await _authService.logout();
    _status = AuthStatus.unauthenticated;
    _isLoading = false;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
