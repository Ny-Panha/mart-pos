import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static const String _tokenKey = 'mart_pos_auth_token';
  static const String _baseUrlKey = 'mart_pos_api_base_url';

  // Configurable base URL: prefers --dart-define=API_BASE_URL or SharedPreferences
  static String defaultBaseUrl() {
    const envUrl = String.fromEnvironment('API_BASE_URL');
    if (envUrl.isNotEmpty) return envUrl;

    if (kIsWeb) return 'http://localhost:8080/api';
    if (Platform.isAndroid) {
      // Standard Android emulator loopback to host machine
      return 'http://10.0.2.2:8080/api';
    }
    return 'http://localhost:8080/api';
  }

  static String _baseUrl = defaultBaseUrl();
  static String? _token;

  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString(_tokenKey);
    final savedUrl = prefs.getString(_baseUrlKey);
    if (savedUrl != null && savedUrl.isNotEmpty) {
      _baseUrl = savedUrl;
    }
  }

  static String get baseUrl => _baseUrl;

  static Future<void> setBaseUrl(String url) async {
    _baseUrl = url.trim();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_baseUrlKey, _baseUrl);
  }

  static Future<void> saveToken(String token) async {
    _token = token;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  static Future<void> clearToken() async {
    _token = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
  }

  static String? get token => _token;

  static Map<String, String> _headers() {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (_token != null && _token!.isNotEmpty) {
      headers['Authorization'] = 'Bearer $_token';
    }
    return headers;
  }

  static Future<dynamic> get(String endpoint) async {
    final uri = Uri.parse('$_baseUrl$endpoint');
    debugPrint('API GET: $uri');
    final response = await http.get(uri, headers: _headers()).timeout(const Duration(seconds: 10));
    return _processResponse(response);
  }

  static Future<dynamic> post(String endpoint, Map<String, dynamic> body) async {
    final uri = Uri.parse('$_baseUrl$endpoint');
    debugPrint('API POST: $uri');
    final response = await http
        .post(uri, headers: _headers(), body: jsonEncode(body))
        .timeout(const Duration(seconds: 10));
    return _processResponse(response);
  }

  static Future<dynamic> put(String endpoint, Map<String, dynamic> body) async {
    final uri = Uri.parse('$_baseUrl$endpoint');
    debugPrint('API PUT: $uri');
    final response = await http
        .put(uri, headers: _headers(), body: jsonEncode(body))
        .timeout(const Duration(seconds: 10));
    return _processResponse(response);
  }

  static Future<dynamic> delete(String endpoint) async {
    final uri = Uri.parse('$_baseUrl$endpoint');
    debugPrint('API DELETE: $uri');
    final response = await http.delete(uri, headers: _headers()).timeout(const Duration(seconds: 10));
    return _processResponse(response);
  }

  static dynamic processResponse(http.Response response) => _processResponse(response);

  static dynamic _processResponse(http.Response response) {
    debugPrint('API Response [${response.statusCode}]');
    dynamic decoded;
    try {
      decoded = jsonDecode(utf8.decode(response.bodyBytes));
    } catch (_) {
      throw Exception('Malformed server response (HTTP ${response.statusCode}): invalid JSON');
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (decoded is Map && decoded['success'] == false) {
        throw Exception(decoded['message'] ?? 'API Operation returned success: false');
      }
      return decoded;
    } else {
      final msg = decoded is Map ? (decoded['message'] ?? decoded['error']) : null;
      throw Exception(msg ?? 'API Error: HTTP ${response.statusCode}');
    }
  }
}
