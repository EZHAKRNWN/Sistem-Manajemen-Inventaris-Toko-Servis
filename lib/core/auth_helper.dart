import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smartfix_mobile/core/api_service.dart';

/// Helper class for managing authentication session and biometric authentication.
class AuthHelper {
  static final AuthHelper _instance = AuthHelper._internal();
  factory AuthHelper() => _instance;
  AuthHelper._internal();

  final LocalAuthentication _localAuth = LocalAuthentication();

  // Session state
  String? _sessionToken;
  String? _currentUsername;

  bool get isAuthenticated => _sessionToken != null;
  String? get sessionToken => _sessionToken;
  String? get currentUsername => _currentUsername;

  /// Check whether biometric sensors are available and configured
  Future<bool> canCheckBiometrics() async {
    try {
      final bool canAuthenticateWithBiometrics =
          await _localAuth.canCheckBiometrics;
      final bool canAuthenticate =
          canAuthenticateWithBiometrics || await _localAuth.isDeviceSupported();
      return canAuthenticate;
    } on PlatformException {
      return false;
    }
  }

  /// Trigger biometric authentication (Fingerprint / Face ID)
  Future<bool> authenticateWithBiometrics({
    String reason = 'Scan your fingerprint or face to authenticate',
  }) async {
    try {
      final bool didAuthenticate = await _localAuth.authenticate(
        localizedReason: reason,
        biometricOnly: true,
        persistAcrossBackgrounding: true,
      );
      return didAuthenticate;
    } on PlatformException {
      return false;
    }
  }

  /// Loads saved username from SharedPreferences if not already cached in memory
  Future<String> getUsername() async {
    if (_currentUsername != null && _currentUsername!.isNotEmpty) {
      return _currentUsername!;
    }
    final prefs = await SharedPreferences.getInstance();
    _currentUsername = prefs.getString('user_name') ?? 'Technician';
    return _currentUsername!;
  }

  /// Store session token upon successful login
  void setSession({required String token, required String username}) async {
    _sessionToken = token;
    _currentUsername = username;
    ApiService.setAuthToken(token);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_name', username);
  }

  /// Clear session on logout
  Future<void> clearSession() async {
    _sessionToken = null;
    _currentUsername = null;
    ApiService.setAuthToken(null);
    await ApiService.clearToken();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_name');
  }
}

