import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
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

  /// Store session token upon successful login
  void setSession({required String token, required String username}) {
    _sessionToken = token;
    _currentUsername = username;
    ApiService.setAuthToken(token);
  }

  /// Clear session on logout
  void clearSession() {
    _sessionToken = null;
    _currentUsername = null;
    ApiService.setAuthToken(null);
  }
}
