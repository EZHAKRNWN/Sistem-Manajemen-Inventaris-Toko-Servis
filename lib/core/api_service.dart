import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// Service for handling REST API communication with the Laravel backend.
///
/// Uses Laravel Sanctum token-based authentication. The bearer token is
/// persisted to [SharedPreferences] so sessions survive app restarts.
class ApiService {
  static const String _baseUrl = 'http://127.0.0.1:8000/api';
  static const String _tokenKey = 'auth_token';

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
  static Future<void> _saveToken(String token) async {
    _authToken = token;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  /// Clears the token from both memory and disk (used on logout).
  static Future<void> clearToken() async {
    _authToken = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
  }

  /// Returns `true` when a token is present in memory.
  static bool get hasToken => _authToken != null;

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
  Future<dynamic> get(String endpoint,
      {Map<String, String>? queryParams}) async {
    final uri =
        Uri.parse('$_baseUrl/$endpoint').replace(queryParameters: queryParams);
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
  /// On success the Sanctum plain-text token is persisted and set as the
  /// active auth header for all subsequent requests.
  ///
  /// Returns the full JSON response body (includes `token`, `user`, etc.).
  Future<Map<String, dynamic>> login(String email, String password) async {
    final data = await post('login', {
      'email': email,
      'password': password,
    });

    final responseMap = data as Map<String, dynamic>;

    // The Laravel backend returns the token under the `token` key.
    final String token = responseMap['token'] as String;
    await _saveToken(token);

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
