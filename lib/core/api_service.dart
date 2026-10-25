import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:smartfix_mobile/core/globals.dart';
import 'package:smartfix_mobile/features/auth/screens/login_screen.dart';

/// Service pusat untuk mengelola komunikasi Web Service REST API ke backend Laravel.
/// Fitur ini memenuhi kriteria projek PAM:
/// 1. HTTP Client modern menggunakan library Dio
/// 2. Konfigurasi Dynamic Base URL (fleksibel antara Android Emulator 10.0.2.2 dan Smartphone fisik via Wi-Fi)
/// 3. Auth Interceptor: Otomatis menyematkan Bearer Token dari [FlutterSecureStorage] pada setiap request
/// 4. Error Interceptor & Session Expiry: Otomatis mendeteksi HTTP 401, membersihkan sesi, dan redirect ke Login
/// 5. Notifikasi lokal saat sesi kedaluwarsa
class ApiService {
  // Flag pencegah redirect/notifikasi berulang saat banyak request 401 terjadi bersamaan
  static bool _isSessionLockActive = false;

  // ── Konfigurasi Jaringan & Base URL ───────────────────────────────────────

  /// Nilai boolean untuk beralih antara Smartphone fisik (IP Wi-Fi lokal) dan Android Emulator (10.0.2.2)
  static bool isPhysicalDevice = const bool.fromEnvironment(
    'IS_PHYSICAL_DEVICE',
    defaultValue: false,
  );

  /// Mengubah mode perangkat fisik / emulator secara dinamis saat runtime
  static void setIsPhysicalDevice(bool value) {
    isPhysicalDevice = value;
    _instance._dio.options.baseUrl = _normalizeBaseUrl(baseUrl);
  }

  /// IP Address lokal laptop/komputer server Laravel saat pengujian di smartphone fisik via Wi-Fi
  static String localNetworkIp = '192.168.100.12';

  /// Mengubah IP lokal laptop secara dinamis saat runtime
  static void setLocalNetworkIp(String ip) {
    localNetworkIp = ip;
    _instance._dio.options.baseUrl = _normalizeBaseUrl(baseUrl);
  }

  /// Port server web Laravel (default: 8000)
  static const String port = '8000';

  static const String _envBaseUrl = String.fromEnvironment('BASE_URL');
  static String? _customBaseUrl;

  /// Memungkinkan pengubahan Base URL secara dinamis saat runtime
  static void setBaseUrl(String? url) {
    _customBaseUrl = url;
    _instance._dio.options.baseUrl = _normalizeBaseUrl(baseUrl);
  }

  /// Getter Base URL dinamis berdasarkan jenis perangkat dan sistem operasi
  static String get baseUrl {
    if (_customBaseUrl != null && _customBaseUrl!.isNotEmpty) {
      return _customBaseUrl!;
    }
    if (_envBaseUrl.isNotEmpty) {
      return _envBaseUrl;
    }

    if (!kIsWeb && Platform.isAndroid) {
      final host = isPhysicalDevice ? localNetworkIp : '10.0.2.2';
      return 'http://$host:$port/api';
    } else if (!kIsWeb && Platform.isIOS) {
      final host = isPhysicalDevice ? localNetworkIp : 'localhost';
      return 'http://$host:$port/api';
    }

    return 'http://localhost:$port/api';
  }

  /// Memastikan URL diakhiri tanda garis miring (slash) untuk konsistensi routing Dio
  static String _normalizeBaseUrl(String url) {
    return url.endsWith('/') ? url : '$url/';
  }

  // ── Penyimpanan Token Aman (FlutterSecureStorage) ─────────────────────────

  static const FlutterSecureStorage _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(resetOnError: true),
  );

  static const String _tokenKey = 'auth_token';
  static String get tokenKey => _tokenKey;
  static String? _authToken;

  /// Menyimpan token di memori aplikasi
  static void setAuthToken(String? token) {
    _authToken = token;
  }

  /// Mengambil token tersimpan dari storage terenkripsi perangkat
  static Future<String?> getToken() async {
    try {
      _authToken = await _storage.read(key: _tokenKey);
      return _authToken;
    } catch (_) {
      return _authToken;
    }
  }

  static Future<void> loadToken() async {
    await getToken();
  }

  /// Menyimpan token autentikasi secara aman ke FlutterSecureStorage
  static Future<void> saveToken(String token) async {
    _authToken = token;
    try {
      await _storage.write(key: _tokenKey, value: token);
    } catch (_) {}
  }

  /// Menghapus token dari memori dan storage terenkripsi saat logout
  static Future<void> clearToken() async {
    _authToken = null;
    try {
      await _storage.delete(key: _tokenKey);
    } catch (_) {}
  }

  static bool get hasToken =>
      _authToken != null && _authToken!.trim().isNotEmpty;

  static Future<bool> hasStoredToken() async {
    final token = await getToken();
    return token != null && token.trim().isNotEmpty;
  }

  // ── Inisialisasi Singleton & Dio HTTP Client ──────────────────────────────

  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;

  late final Dio _dio;
  Dio get dio => _dio;

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();
  bool _isNotificationInitialized = false;

  /// Inisialisasi notifikasi lokal khusus penanda sesi API
  Future<void> initializeNotifications() async {
    if (_isNotificationInitialized) return;
    try {
      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('@mipmap/launcher_icon');

      const DarwinInitializationSettings initializationSettingsDarwin =
          DarwinInitializationSettings(
            requestAlertPermission: true,
            requestBadgePermission: true,
            requestSoundPermission: true,
          );

      const InitializationSettings initializationSettings =
          InitializationSettings(
            android: initializationSettingsAndroid,
            iOS: initializationSettingsDarwin,
          );

      await _notificationsPlugin.initialize(settings: initializationSettings);
      _isNotificationInitialized = true;
    } catch (e) {
      debugPrint('Gagal inisialisasi notifikasi ApiService: $e');
    }
  }

  /// Memicu push notifikasi lokal saat mendeteksi token kedaluwarsa (HTTP 401)
  Future<void> _showSessionExpiredNotification() async {
    try {
      if (!_isNotificationInitialized) {
        await initializeNotifications();
      }

      const AndroidNotificationDetails androidDetails =
          AndroidNotificationDetails(
            'session_expired_channel',
            'Pemberitahuan Sesi',
            channelDescription:
                'Pemberitahuan ketika sesi login pengguna telah kedaluwarsa atau berakhir',
            importance: Importance.max,
            priority: Priority.high,
            ticker: 'Sesi Berakhir',
          );

      const NotificationDetails platformDetails = NotificationDetails(
        android: androidDetails,
        iOS: DarwinNotificationDetails(),
      );

      await _notificationsPlugin.show(
        id: 401,
        title: 'Sesi Berakhir 🔒',
        body:
            'Kredensial atau token sesi Anda telah berakhir. Silakan masuk kembali ke akun teknisi Anda.',
        notificationDetails: platformDetails,
      );
    } catch (e) {
      debugPrint('Gagal memicu notifikasi sesi kedaluwarsa: $e');
    }
  }

  /// Konstruktor privat dengan konfigurasi interceptor onRequest, onResponse, onError
  ApiService._internal() {
    _dio = Dio(
      BaseOptions(
        baseUrl: _normalizeBaseUrl(baseUrl),
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        sendTimeout: const Duration(seconds: 15),
        headers: const {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        responseType: ResponseType.json,
      ),
    );

    initializeNotifications();

    _dio.interceptors.add(
      InterceptorsWrapper(
        // Interceptor Request: Otomatis menyematkan Authorization Header (Bearer Token)
        onRequest: (options, handler) async {
          if (options.baseUrl.isEmpty) {
            options.baseUrl = _normalizeBaseUrl(baseUrl);
          }

          final token = await getToken();
          if (token != null && token.trim().isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onResponse: (response, handler) {
          return handler.next(response);
        },
        // Interceptor Error: Menangkap 401 Unauthorized secara global
        onError: (DioException error, handler) async {
          if (error.response?.statusCode == 401) {
            if (!_isSessionLockActive) {
              _isSessionLockActive = true;

              await clearToken();
              await _showSessionExpiredNotification();

              // Auto-redirect kembali ke LoginScreen
              globalNavigatorKey.currentState?.pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => const LoginScreen()),
                (route) => false,
              );
            }
          }
          return handler.next(error);
        },
      ),
    );
  }

  String _cleanPath(String path) {
    return path.startsWith('/') ? path.substring(1) : path;
  }

  /// Menangani error Dio dan memformat pesan kegagalan agar mudah dipahami pengguna
  Never _handleDioError(DioException e, String contextInfo) {
    String message =
        'Terjadi kesalahan komunikasi dengan server ($contextInfo).';

    if (e.response != null && e.response?.data != null) {
      final dynamic data = e.response!.data;
      if (data is Map) {
        if (data['message'] != null && data['message'].toString().isNotEmpty) {
          message = data['message'].toString();

          if (data['errors'] is Map) {
            final errorsMap = data['errors'] as Map;
            final errorDetails = <String>[];
            for (final entry in errorsMap.entries) {
              if (entry.value is List && (entry.value as List).isNotEmpty) {
                errorDetails.add((entry.value as List).join(', '));
              } else if (entry.value != null) {
                errorDetails.add(entry.value.toString());
              }
            }
            if (errorDetails.isNotEmpty) {
              message = '$message: ${errorDetails.join(' | ')}';
            }
          }
        } else if (data['error'] != null) {
          message = data['error'].toString();
        }
      } else if (data is String && data.trim().isNotEmpty) {
        message = data.trim();
      }
    } else {
      switch (e.type) {
        case DioExceptionType.connectionTimeout:
          message = 'Koneksi ke server timeout (waktu koneksi habis).';
          break;
        case DioExceptionType.sendTimeout:
          message = 'Pengiriman data ke server timeout.';
          break;
        case DioExceptionType.receiveTimeout:
          message =
              'Server tidak merespons dalam batas waktu (receive timeout).';
          break;
        case DioExceptionType.connectionError:
          message =
              'Gagal terhubung ke backend ($baseUrl). Pastikan server Laravel aktif dan IP jaringan sesuai.';
          break;
        case DioExceptionType.badCertificate:
          message = 'Sertifikat keamanan server tidak valid.';
          break;
        case DioExceptionType.cancel:
          message = 'Permintaan dibatalkan.';
          break;
        case DioExceptionType.unknown:
        default:
          message = e.message ?? 'Kesalahan koneksi jaringan tidak diketahui.';
          break;
      }
    }

    throw Exception(message);
  }

  // ── Helper HTTP Generic (GET & POST) ──────────────────────────────────────

  /// Mengirim request HTTP GET ke endpoint Laravel backend
  Future<dynamic> get(
    String endpoint, {
    Map<String, dynamic>? queryParams,
  }) async {
    try {
      final response = await _dio.get(
        _cleanPath(endpoint),
        queryParameters: queryParams,
      );
      return response.data;
    } on DioException catch (e) {
      _handleDioError(e, 'GET $endpoint');
    } catch (e) {
      throw Exception('GET request failed on $endpoint: $e');
    }
  }

  /// Mengirim request HTTP POST dengan body JSON ke endpoint Laravel backend
  Future<dynamic> post(String endpoint, dynamic body) async {
    try {
      final response = await _dio.post(_cleanPath(endpoint), data: body);
      return response.data;
    } on DioException catch (e) {
      _handleDioError(e, 'POST $endpoint');
    } catch (e) {
      throw Exception('POST request failed on $endpoint: $e');
    }
  }

  // ── Fitur Autentikasi (Sanctum Login) ──────────────────────────────────────

  /// Mengotentikasi pengguna ke API Laravel Sanctum menggunakan Email dan Password.
  /// Mengembalikan data profil dan token akses yang langsung disimpan ke Secure Storage.
  Future<Map<String, dynamic>> login(String email, String password) async {
    await clearToken();

    final data = await post('login', {
      'email': email.trim(),
      'password': password,
    });

    Map<String, dynamic> responseMap;
    if (data is Map<String, dynamic>) {
      responseMap = data;
    } else if (data is Map) {
      responseMap = Map<String, dynamic>.from(data);
    } else {
      throw Exception('Format respons server tidak valid.');
    }

    String? token;
    if (responseMap['token'] != null) {
      token = responseMap['token'].toString();
    } else if (responseMap['access_token'] != null) {
      token = responseMap['access_token'].toString();
    } else if (responseMap['data'] is Map &&
        responseMap['data']['token'] != null) {
      token = responseMap['data']['token'].toString();
    }

    if (token == null || token.isEmpty) {
      throw Exception('Token otentikasi tidak ditemukan dalam respons server.');
    }

    await saveToken(token);
    _isSessionLockActive = false;

    return responseMap;
  }

  // ── Fitur Inventaris Suku Cadang (Inventory Management) ────────────────────

  /// Mengambil daftar suku cadang dari backend dengan dukungan filter pencarian & kategori
  Future<dynamic> getInventory({String? search, String? category}) async {
    final Map<String, dynamic> params = {};
    if (search != null && search.isNotEmpty) params['search'] = search;
    if (category != null &&
        category.isNotEmpty &&
        category != 'All' &&
        category != 'Semua') {
      params['category'] = category;
    }

    return get('inventory', queryParams: params.isNotEmpty ? params : null);
  }

  /// Mendaftarkan suku cadang baru ke backend dan menghasilkan hash SHA-256 blockchain
  Future<dynamic> addPart(Map<String, dynamic> partData) async {
    return post('inventory', partData);
  }

  // ── Fitur Tiket Servis & Perbaikan (Work Orders) ───────────────────────────

  /// Mengambil daftar pesanan kerja/tiket perbaikan pelanggan
  Future<dynamic> getWorkOrders({String? status, String? search}) async {
    final Map<String, dynamic> params = {};
    if (status != null &&
        status.isNotEmpty &&
        status != 'ALL' &&
        status != 'Semua') {
      params['status'] = status;
    }
    if (search != null && search.isNotEmpty) {
      params['search'] = search;
    }

    return get('work-orders', queryParams: params.isNotEmpty ? params : null);
  }

  /// Mencatat tiket perbaikan servis smartphone baru ke database server
  Future<dynamic> createWorkOrder(Map<String, dynamic> data) async {
    return post('work-orders', data);
  }

  /// Menyelesaikan pengerjaan servis (status COMPLETED) dan memotong stok suku cadang terkait
  Future<dynamic> completeWorkOrder(dynamic id) async {
    return post('work-orders/$id/complete', {});
  }

  // ── Fitur Statistik Kinerja Teknisi ───────────────────────────────────────

  /// Mengambil statistik perbaikan teknisi (jumlah servis selesai, part terverifikasi, tiket pending)
  Future<Map<String, dynamic>> getTechnicianStats() async {
    final response = await get('technician/stats');
    if (response is Map<String, dynamic> && response['data'] is Map) {
      return Map<String, dynamic>.from(response['data'] as Map);
    } else if (response is Map && response['data'] is Map) {
      return Map<String, dynamic>.from(response['data'] as Map);
    }
    return {'completed_repairs': 0, 'verified_parts': 0, 'pending_tickets': 0};
  }
}
