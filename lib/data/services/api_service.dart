import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static const String _tokenKey = 'mart_pos_auth_token';
  static const String _baseUrlKey = 'mart_pos_api_base_url';

  // Default IP: 192.168.1.4 for real Wi-Fi device, localhost for Desktop/Web, 10.0.2.2 for Android Emulator
  static String defaultBaseUrl() {
    if (kIsWeb) return 'http://localhost:8080/api';
    if (Platform.isAndroid) {
      // 192.168.1.4 matches PC's local Wi-Fi IP so physical Android phones work directly
      return 'http://192.168.1.4:8080/api';
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

  static dynamic _processResponse(http.Response response) {
    debugPrint('API Response [${response.statusCode}]');
    final decoded = jsonDecode(utf8.decode(response.bodyBytes));
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return decoded;
    } else {
      final msg = decoded['message'] ?? 'API Error: ${response.statusCode}';
      throw Exception(msg);
    }
  }
}
