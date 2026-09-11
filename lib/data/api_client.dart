// Thin HTTP client for the DODOMED backend (see `backend/README.md`). Every
// method returns decoded JSON (a `Map`/`List`) or throws an [ApiException]
// with the server's own error message so callers can show it directly.
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Thrown when the backend responds with a non-2xx status. [message] is the
/// server's own `error` field when present, else a generic fallback.
class ApiException implements Exception {
  ApiException(this.message, {this.statusCode});
  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}

/// Where the API lives. Android emulators can't reach the host machine via
/// `localhost` (it means the emulator itself), so it gets `10.0.2.2`
/// instead — everything else (web, iOS simulator, desktop) uses `localhost`.
String _defaultBaseUrl() {
  if (kIsWeb) return 'http://localhost:4000/api';
  if (defaultTargetPlatform == TargetPlatform.android) {
    return 'http://10.0.2.2:4000/api';
  }
  return 'http://localhost:4000/api';
}

class ApiClient {
  ApiClient({String? baseUrl, http.Client? client})
      : baseUrl = baseUrl ?? _defaultBaseUrl(),
        _client = client ?? http.Client();

  final String baseUrl;
  final http.Client _client;

  /// Set after login/signup; sent as `Authorization: Bearer <token>` on
  /// every subsequent request. `null` for anonymous (public) calls.
  String? token;

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };

  Uri _uri(String path, [Map<String, String>? query]) =>
      Uri.parse('$baseUrl$path').replace(queryParameters: query);

  dynamic _decode(http.Response res) {
    final body = res.body.isEmpty ? <String, dynamic>{} : jsonDecode(res.body);
    if (res.statusCode < 200 || res.statusCode >= 300) {
      final message = (body is Map && body['error'] is String)
          ? body['error'] as String
          : 'Request failed (${res.statusCode}).';
      throw ApiException(message, statusCode: res.statusCode);
    }
    return body;
  }

  Future<dynamic> get(String path, {Map<String, String>? query}) async {
    final res = await _client.get(_uri(path, query), headers: _headers);
    return _decode(res);
  }

  Future<dynamic> post(String path, [Map<String, dynamic>? body]) async {
    final res = await _client.post(_uri(path), headers: _headers, body: jsonEncode(body ?? {}));
    return _decode(res);
  }

  Future<dynamic> put(String path, [Map<String, dynamic>? body]) async {
    final res = await _client.put(_uri(path), headers: _headers, body: jsonEncode(body ?? {}));
    return _decode(res);
  }

  Future<dynamic> delete(String path) async {
    final res = await _client.delete(_uri(path), headers: _headers);
    return _decode(res);
  }
}
