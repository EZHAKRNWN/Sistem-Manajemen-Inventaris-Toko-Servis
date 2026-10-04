import 'dart:convert';
import 'package:http/http.dart' as http;

/// Service for handling REST API communication with remote / local servers.
class ApiService {
  static const String _baseUrl = 'https://api.smartfix.local/v1';
  static String? _authToken;

  // Singleton instance
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  /// Updates or sets the current session authentication token
  static void setAuthToken(String? token) {
    _authToken = token;
  }

  /// Default headers with token-based authorization
  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        if (_authToken != null) 'Authorization': 'Bearer $_authToken',
      };

  /// Send GET request
  Future<dynamic> get(String endpoint) async {
    final uri = Uri.parse('$_baseUrl/$endpoint');
    try {
      final response = await http.get(uri, headers: _headers);
      return _handleResponse(response);
    } catch (e) {
      throw Exception('GET request failed on $endpoint: $e');
    }
  }

  /// Send POST request
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

  /// Helper to decode JSON response and handle status codes
  dynamic _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return null;
      return jsonDecode(response.body);
    } else {
      throw Exception(
        'HTTP error ${response.statusCode}: ${response.reasonPhrase}',
      );
    }
  }
}
