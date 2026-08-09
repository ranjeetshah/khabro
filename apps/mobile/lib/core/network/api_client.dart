import 'dart:convert';

import 'package:http/http.dart' as http;

/// Centralized HTTP client for backend API communication.
class ApiClient {
  ApiClient({http.Client? httpClient})
      : _httpClient = httpClient ?? http.Client();

  static const String baseUrl = 'http://localhost:3000';

  final http.Client _httpClient;

  /// GET request. Optionally include [headers].
  Future<http.Response> get(
    String path, {
    Map<String, String>? headers,
  }) {
    return _httpClient.get(
      Uri.parse('$baseUrl$path'),
      headers: headers,
    );
  }

  /// POST request with JSON [body]. Sets Content-Type automatically.
  Future<http.Response> post(
    String path, {
    Map<String, dynamic>? body,
    Map<String, String>? headers,
  }) {
    final mergedHeaders = {
      'Content-Type': 'application/json',
      ...?headers,
    };

    return _httpClient.post(
      Uri.parse('$baseUrl$path'),
      headers: mergedHeaders,
      body: body != null ? jsonEncode(body) : null,
    );
  }

  /// PATCH request with JSON [body]. Sets Content-Type automatically.
  Future<http.Response> patch(
    String path, {
    Map<String, dynamic>? body,
    Map<String, String>? headers,
  }) {
    final mergedHeaders = {
      'Content-Type': 'application/json',
      ...?headers,
    };

    return _httpClient.patch(
      Uri.parse('$baseUrl$path'),
      headers: mergedHeaders,
      body: body != null ? jsonEncode(body) : null,
    );
  }
}
