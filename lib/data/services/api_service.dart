import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiException implements Exception {
  final int statusCode;
  final String message;
  final dynamic body;

  ApiException({
    required this.statusCode,
    required this.message,
    this.body,
  });

  @override
  String toString() => message;
}

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
  static http.Client? _client;

  static set client(http.Client? c) => _client = c;

  static Future<http.Response> _httpGet(Uri uri, {Map<String, String>? headers}) {
    if (_client != null) return _client!.get(uri, headers: headers);
    return http.get(uri, headers: headers);
  }

  static Future<http.Response> _httpPost(Uri uri, {Map<String, String>? headers, Object? body}) {
    if (_client != null) return _client!.post(uri, headers: headers, body: body);
    return http.post(uri, headers: headers, body: body);
  }

  static Future<http.Response> _httpPut(Uri uri, {Map<String, String>? headers, Object? body}) {
    if (_client != null) return _client!.put(uri, headers: headers, body: body);
    return http.put(uri, headers: headers, body: body);
  }

  static Future<http.Response> _httpDelete(Uri uri, {Map<String, String>? headers}) {
    if (_client != null) return _client!.delete(uri, headers: headers);
    return http.delete(uri, headers: headers);
  }

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
    final response = await _httpGet(uri, headers: _headers()).timeout(const Duration(seconds: 10));
    return _processResponse(response);
  }

  static Future<dynamic> post(String endpoint, Map<String, dynamic> body) async {
    final uri = Uri.parse('$_baseUrl$endpoint');
    debugPrint('API POST: $uri');
    final response = await _httpPost(uri, headers: _headers(), body: jsonEncode(body))
        .timeout(const Duration(seconds: 10));
    return _processResponse(response);
  }

  static Future<dynamic> put(String endpoint, Map<String, dynamic> body) async {
    final uri = Uri.parse('$_baseUrl$endpoint');
    debugPrint('API PUT: $uri');
    final response = await _httpPut(uri, headers: _headers(), body: jsonEncode(body))
        .timeout(const Duration(seconds: 10));
    return _processResponse(response);
  }

  static Future<dynamic> delete(String endpoint) async {
    final uri = Uri.parse('$_baseUrl$endpoint');
    debugPrint('API DELETE: $uri');
    final response = await _httpDelete(uri, headers: _headers()).timeout(const Duration(seconds: 10));
    return _processResponse(response);
  }

  static dynamic processResponse(http.Response response) => _processResponse(response);

  static dynamic _processResponse(http.Response response) {
    debugPrint('API Response [${response.statusCode}]');
    dynamic decoded;
    try {
      decoded = jsonDecode(utf8.decode(response.bodyBytes));
    } catch (_) {
      throw ApiException(
        statusCode: response.statusCode,
        message: 'Malformed server response (HTTP ${response.statusCode}): invalid JSON',
      );
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (decoded is Map && decoded['success'] == false) {
        throw ApiException(
          statusCode: response.statusCode,
          message: decoded['message']?.toString() ?? 'API Operation returned success: false',
          body: decoded,
        );
      }
      return decoded;
    } else {
      final msg = decoded is Map ? (decoded['message'] ?? decoded['error']) : null;
      throw ApiException(
        statusCode: response.statusCode,
        message: msg?.toString() ?? 'API Error: HTTP ${response.statusCode}',
        body: decoded,
      );
    }
  }
}
