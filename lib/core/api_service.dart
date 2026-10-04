import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// Service for handling REST API communication with the Laravel backend.
///
/// Uses Laravel Sanctum token-based authentication. The bearer token is
/// persisted to [SharedPreferences] so sessions survive app restarts.
class ApiService {
  // ---------------------------------------------------------------------------
  // Base URL & Network Configuration
  // ---------------------------------------------------------------------------

  /// Set this to `true` when testing on a physical smartphone over local Wi-Fi.
  /// Set to `false` when testing on an Android Studio Emulator.
  static const bool isPhysicalDevice = false;

  /// Development machine's local IPv4 address (e.g. '192.168.1.5' or '192.168.100.12').
  /// Used when testing on physical devices connected to the same Wi-Fi network.
  static const String localNetworkIp = '192.168.100.12';

  /// Port on which the Laravel backend is serving (default: 8000).
  static const String port = '8000';

  /// Compile-time environment override (e.g., `flutter run --dart-define=BASE_URL=http://...`)
  static const String _envBaseUrl = String.fromEnvironment('BASE_URL');

  /// Runtime override for base URL (if configured programmatically).
  static String? _customBaseUrl;

  /// Allows setting or switching the base URL dynamically at runtime.
  static void setBaseUrl(String? url) {
    _customBaseUrl = url;
  }

  /// Dynamic Base URL resolver based on platform, environment, and device type:
  /// - Android Studio Emulator: `http://10.0.2.2:8000/api` (maps loopback to host)
  /// - Android Physical Smartphone: `http://<localNetworkIp>:8000/api` (when [isPhysicalDevice] = true)
  /// - iOS Simulator / Desktop: `http://localhost:8000/api` (or local IP for physical iOS)
  /// - Runtime/Compile-time override: Uses [_customBaseUrl] or `--dart-define=BASE_URL=...`
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

    // Fallback for Web / Desktop / other environments
    return 'http://localhost:$port/api';
  }

  /// Internal reference for backward compatibility
  static String get _baseUrl => baseUrl;

  static const String _tokenKey = 'auth_token';

  /// Getter for the SharedPreferences key used for the auth token.
  static String get tokenKey => _tokenKey;

  static String? _authToken;

  // ---------------------------------------------------------------------------
  // Singleton
  // ---------------------------------------------------------------------------
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  // ---------------------------------------------------------------------------
  // Token management
  // ---------------------------------------------------------------------------

  /// Updates or clears the in-memory auth token.
  static void setAuthToken(String? token) {
    _authToken = token;
  }

  /// Loads a previously-persisted token from disk into memory.
  static Future<void> loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    _authToken = prefs.getString(_tokenKey);
  }

  /// Persists [token] to disk and sets it in memory.
  static Future<void> saveToken(String token) async {
    _authToken = token;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  /// Clears the token from both memory and disk (used on logout and before re-login).
  static Future<void> clearToken() async {
    _authToken = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
  }

  /// Returns `true` when a valid token is present in memory.
  static bool get hasToken =>
      _authToken != null && _authToken!.trim().isNotEmpty;

  // ---------------------------------------------------------------------------
  // Headers
  // ---------------------------------------------------------------------------

  /// Default headers — includes Bearer token when available.
  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    if (_authToken != null) 'Authorization': 'Bearer $_authToken',
  };

  // ---------------------------------------------------------------------------
  // Generic HTTP helpers
  // ---------------------------------------------------------------------------

  /// Sends a GET request to [endpoint] (relative to [_baseUrl]).
  Future<dynamic> get(
    String endpoint, {
    Map<String, String>? queryParams,
  }) async {
    final uri = Uri.parse('$_baseUrl/$endpoint')
        .replace(queryParameters: queryParams);
    try {
      final response = await http.get(uri, headers: _headers);
      return _handleResponse(response);
    } catch (e) {
      throw Exception('GET request failed on $endpoint: $e');
    }
  }

  /// Sends a POST request to [endpoint] with a JSON [body].
  Future<dynamic> post(String endpoint, Map<String, dynamic> body) async {
    final uri = Uri.parse('$_baseUrl/$endpoint');
    try {
      final response = await http.post(
        uri,
        headers: _headers,
        body: jsonEncode(body),
      );
      return _handleResponse(response);
    } catch (e) {
      throw Exception('POST request failed on $endpoint: $e');
    }
  }

  /// Decodes JSON and throws a descriptive exception on non-2xx status codes.
  dynamic _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return null;
      return jsonDecode(response.body);
    } else {
      // Try to extract the backend validation message.
      String message = 'HTTP ${response.statusCode}: ${response.reasonPhrase}';
      try {
        final body = jsonDecode(response.body);
        if (body is Map && body.containsKey('message')) {
          message = body['message'] as String;
        }
      } catch (_) {
        // Body is not JSON – keep the default message.
      }
      throw Exception(message);
    }
  }

  // ---------------------------------------------------------------------------
  // Auth endpoints
  // ---------------------------------------------------------------------------

  /// Authenticates with the Laravel Sanctum backend.
  ///
  /// Resets any existing session or authorization header before sending the
  /// credentials to prevent post-logout authentication conflicts. On success,
  /// the Sanctum token is saved to persistent storage and applied to active headers.
  ///
  /// Returns the full JSON response body (includes `token`, `user`, etc.).
  Future<Map<String, dynamic>> login(String email, String password) async {
    // 1. Explicitly clear any stale session/token before sending new login request
    await clearToken();

    // 2. Perform authentication request without stale Authorization headers
    final data = await post('login', {
      'email': email.trim(),
      'password': password,
    });

    if (data is! Map<String, dynamic>) {
      throw Exception('Invalid response received from server.');
    }

    final responseMap = data;

    // 3. Extract the token cleanly across possible response keys
    String? token;
    if (responseMap['token'] != null) {
      token = responseMap['token'].toString();
    } else if (responseMap['access_token'] != null) {
      token = responseMap['access_token'].toString();
    } else if (responseMap['data'] is Map && responseMap['data']['token'] != null) {
      token = responseMap['data']['token'].toString();
    }

    if (token == null || token.isEmpty) {
      throw Exception('Authentication token missing from server response.');
    }

    // 4. Persist and apply the new session token
    await saveToken(token);

    return responseMap;
  }

  // ---------------------------------------------------------------------------
  // Inventory endpoints
  // ---------------------------------------------------------------------------

  /// Fetches the spare-part inventory list.
  ///
  /// Optionally filtered by [search] keyword and/or [category].
  Future<dynamic> getInventory({String? search, String? category}) async {
    final Map<String, String> params = {};
    if (search != null && search.isNotEmpty) params['search'] = search;
    if (category != null && category.isNotEmpty && category != 'All') {
      params['category'] = category;
    }

    return get('inventory', queryParams: params.isNotEmpty ? params : null);
  }

  /// Adds a new spare part to the inventory.
  ///
  /// [partData] should contain keys expected by the backend such as
  /// `name`, `sku`, `brand`, `category`, `stock`, `min_stock`, and `price`.
  Future<dynamic> addPart(Map<String, dynamic> partData) async {
    return post('inventory', partData);
  }
}
