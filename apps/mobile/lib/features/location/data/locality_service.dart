import 'dart:convert';

import '../../../core/network/api_client.dart';
import '../../../core/storage/token_storage.dart';
import '../../auth/data/auth_exception.dart';
import 'locality_model.dart';

/// Service for resolving the authenticated user's current locality.
class LocalityService {
  LocalityService({ApiClient? apiClient, TokenStorage? tokenStorage})
    : _apiClient = apiClient ?? ApiClient(),
      _tokenStorage = tokenStorage ?? TokenStorage();

  final ApiClient _apiClient;
  final TokenStorage _tokenStorage;

  Future<LocalityModel?> getMyLocality() async {
    final token = await _tokenStorage.getAccessToken();

    if (token == null || token.isEmpty) {
      throw const AuthException(
        'Not authenticated. Please log in.',
        statusCode: 401,
      );
    }

    final response = await _apiClient.get(
      '/location/me/locality',
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 401) {
      throw const AuthException(
        'Session expired. Please log in again.',
        statusCode: 401,
      );
    }

    if (response.statusCode != 200) {
      throw AuthException(
        _extractErrorMessage(response.body, 'Failed to fetch locality'),
        statusCode: response.statusCode,
      );
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final locality = data['locality'];
    return locality == null
        ? null
        : LocalityModel.fromJson(locality as Map<String, dynamic>);
  }

  String _extractErrorMessage(String body, String fallback) {
    try {
      final data = jsonDecode(body) as Map<String, dynamic>;
      final message = data['message'];
      if (message is String) return message;
      if (message is List) return message.join(', ');
      return fallback;
    } catch (_) {
      return fallback;
    }
  }
}
