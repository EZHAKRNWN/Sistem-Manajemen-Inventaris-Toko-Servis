import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smartfix_mobile/core/api_service.dart';

/// Helper class untuk manajemen sesi autentikasi dan otentikasi biometrik (Fingerprint / Face ID).
/// Fitur ini memenuhi kriteria projek PAM:
/// 1. Login sesi berbasis token aman menggunakan [FlutterSecureStorage] & [SharedPreferences]
/// 2. Integrasi sensor biometrik perangkat via package [local_auth]
/// 3. Mekanisme penyimpanan kredensial terenkripsi untuk fitur "Masuk Cepat dengan Biometrik"
class AuthHelper {
  static final AuthHelper _instance = AuthHelper._internal();
  factory AuthHelper() => _instance;
  AuthHelper._internal();

  final LocalAuthentication _localAuth = LocalAuthentication();
  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage(
    aOptions: AndroidOptions(resetOnError: true),
  );

  static const String _bioEmailKey = 'biometric_saved_email';
  static const String _bioPasswordKey = 'biometric_saved_password';

  // Status sesi aktif di memori
  String? _sessionToken;
  String? _currentUsername;

  bool get isAuthenticated => _sessionToken != null;
  String? get sessionToken => _sessionToken;
  String? get currentUsername => _currentUsername;

  /// Memeriksa apakah perangkat keras memiliki sensor biometrik (fingerprint/face unlock) yang aktif
  Future<bool> canCheckBiometrics() async {
    try {
      final bool canAuthenticateWithBiometrics =
          await _localAuth.canCheckBiometrics;
      final bool canAuthenticate =
          canAuthenticateWithBiometrics || await _localAuth.isDeviceSupported();
      return canAuthenticate;
    } on PlatformException {
      return false;
    } catch (_) {
      return false;
    }
  }

  /// Memicu prompt dialog biometrik sistem operasi (Fingerprint / Face ID / PIN fallback)
  Future<bool> authenticateWithBiometrics({
    String reason = 'Scan fingerprint atau wajah untuk masuk ke SmartFix',
  }) async {
    try {
      final bool didAuthenticate = await _localAuth.authenticate(
        localizedReason: reason,
        biometricOnly: false,
        sensitiveTransaction: false,
        persistAcrossBackgrounding: true,
      );
      return didAuthenticate;
    } on PlatformException catch (e) {
      debugPrint('Biometric PlatformException: ${e.message} (code: ${e.code})');
      rethrow;
    } catch (e) {
      throw Exception('Biometric authentication failed: $e');
    }
  }

  /// Menghentikan proses pemindaian biometrik jika sedang berlangsung
  Future<void> stopAuthentication() async {
    try {
      await _localAuth.stopAuthentication();
    } catch (_) {}
  }

  /// Mengambil nama pengguna/teknisi yang tersimpan dari SharedPreferences
  Future<String> getUsername() async {
    if (_currentUsername != null && _currentUsername!.isNotEmpty) {
      return _currentUsername!;
    }
    final prefs = await SharedPreferences.getInstance();
    _currentUsername = prefs.getString('user_name') ?? 'Technician';
    return _currentUsername!;
  }

  /// Memulihkan status sesi login ke memori dan mengaitkan token ke ApiService
  void restoreSession({required String token, required String username}) {
    _sessionToken = token;
    _currentUsername = username;
    ApiService.setAuthToken(token);
  }

  /// Memeriksa dan memuat sesi login tersimpan saat aplikasi pertama kali dijalankan (auto-login)
  Future<bool> initSession() async {
    String? token = await ApiService.getToken();
    final prefs = await SharedPreferences.getInstance();
    token ??= prefs.getString(ApiService.tokenKey);
    final username = prefs.getString('user_name');
    if (token != null && token.trim().isNotEmpty) {
      restoreSession(token: token, username: username ?? 'Technician');
      return true;
    }
    return false;
  }

  /// Menyimpan token sesi dan identitas teknisi setelah autentikasi berhasil
  Future<void> setSession({
    required String token,
    required String username,
  }) async {
    _sessionToken = token;
    _currentUsername = username;
    ApiService.setAuthToken(token);
    await ApiService.saveToken(token);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_name', username);
  }

  /// Menghapus seluruh sesi login teknisi saat melakukan Logout aman
  Future<void> clearSession() async {
    _sessionToken = null;
    _currentUsername = null;
    ApiService.setAuthToken(null);
    await ApiService.clearToken();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_name');
  }

  /// Menyimpan kredensial email & password ke Secure Storage untuk otentikasi biometrik selanjutnya
  Future<void> saveBiometricCredentials({
    required String email,
    required String password,
    required String username,
  }) async {
    try {
      await _secureStorage.write(key: _bioEmailKey, value: email);
      await _secureStorage.write(key: _bioPasswordKey, value: password);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_name', username);
      _currentUsername = username;
    } catch (_) {}
  }

  /// Memeriksa apakah sudah ada akun yang terdaftar untuk fitur login biometrik
  Future<bool> hasBiometricCredentials() async {
    try {
      final email = await _secureStorage.read(key: _bioEmailKey);
      final pass = await _secureStorage.read(key: _bioPasswordKey);
      return email != null &&
          email.isNotEmpty &&
          pass != null &&
          pass.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  /// Mengambil kredensial login terenkripsi untuk proses otentikasi biometrik
  Future<Map<String, String>?> getBiometricCredentials() async {
    try {
      final email = await _secureStorage.read(key: _bioEmailKey);
      final pass = await _secureStorage.read(key: _bioPasswordKey);
      if (email != null &&
          email.isNotEmpty &&
          pass != null &&
          pass.isNotEmpty) {
        final username = await getUsername();
        return {'email': email, 'password': pass, 'username': username};
      }
    } catch (_) {}
    return null;
  }

  /// Menghapus kredensial biometrik yang tersimpan di Secure Storage
  Future<void> clearBiometricCredentials() async {
    try {
      await _secureStorage.delete(key: _bioEmailKey);
      await _secureStorage.delete(key: _bioPasswordKey);
    } catch (_) {}
  }
}
