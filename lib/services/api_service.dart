// Tek noktadan API erişimi: baseUrl, JWT okuma, ortak header'lar ve
// PagedResponse / hata yönetimi yardımcı fonksiyonları burada toplanıyor.
// Tüm ekranlar bu dosyayı kullanmalı; baseUrl'yi bir yerde değiştirmek
// (ör. localhost yerine 10.0.2.2 ya da deploy adresi) tüm uygulamayı etkiler.

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  // Backend HTTPS adresi. Geliştirici makinesinde Docker SQL + .NET API
  // bu adreste ayağa kalkıyor. Android emülatörde 10.0.2.2 gerekirse
  // burayı tek noktadan değiştirmek yeterli.
  static const String baseUrl = 'https://localhost:9001';

  // Login ekranı SharedPreferences'a 'jwt_token' anahtarıyla yazıyor;
  // tüm istekler aynı anahtardan okuyor.
  static const String _tokenKey = 'jwt_token';

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  static Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
  }

  // requireAuth=false olduğunda Authorization header eklenmez —
  // anonim erişilebilen Product GET endpoint'leri için kullanılır.
  static Future<Map<String, String>> _headers({bool requireAuth = true}) async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (requireAuth) {
      final token = await getToken();
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
    }
    return headers;
  }

  // Generic GET — hata yönetimi ve JSON parse'ını tek noktada yapar.
  // Dönen değer JSON tipini olduğu gibi verir (Map ya da List olabilir).
  static Future<dynamic> get(
    String path, {
    Map<String, String>? query,
    bool requireAuth = true,
  }) async {
    final uri = Uri.parse('$baseUrl$path').replace(queryParameters: query);
    final response = await http.get(uri, headers: await _headers(requireAuth: requireAuth));
    return _parse(response);
  }

  static Future<dynamic> post(
    String path, {
    Object? body,
    bool requireAuth = true,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl$path'),
      headers: await _headers(requireAuth: requireAuth),
      body: body == null ? null : jsonEncode(body),
    );
    return _parse(response);
  }

  static Future<dynamic> put(
    String path, {
    Object? body,
    bool requireAuth = true,
  }) async {
    final response = await http.put(
      Uri.parse('$baseUrl$path'),
      headers: await _headers(requireAuth: requireAuth),
      body: body == null ? null : jsonEncode(body),
    );
    return _parse(response);
  }

  static Future<dynamic> delete(
    String path, {
    bool requireAuth = true,
  }) async {
    final response = await http.delete(
      Uri.parse('$baseUrl$path'),
      headers: await _headers(requireAuth: requireAuth),
    );
    return _parse(response);
  }

  // Status code 2xx ise body'yi JSON olarak çözer; aksi halde
  // backend'in döndürdüğü message alanını okuyup ApiException fırlatır.
  static dynamic _parse(http.Response response) {
    final code = response.statusCode;
    final body = response.body;

    if (code >= 200 && code < 300) {
      if (body.isEmpty) return null;
      return jsonDecode(body);
    }

    String message = 'Request failed ($code)';
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map && decoded['message'] is String) {
        message = decoded['message'];
      } else if (decoded is Map && decoded['Message'] is String) {
        message = decoded['Message'];
      }
    } catch (_) {/* body JSON değilse görmezden gel */}

    throw ApiException(message, statusCode: code);
  }
}

class ApiException implements Exception {
  final String message;
  final int? statusCode;
  ApiException(this.message, {this.statusCode});

  @override
  String toString() => message;
}
