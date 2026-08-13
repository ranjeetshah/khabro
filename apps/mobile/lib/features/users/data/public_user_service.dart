import 'dart:convert';

import '../../../core/network/api_client.dart';
import '../../../core/storage/token_storage.dart';
import '../../auth/data/auth_exception.dart';
import 'public_user_model.dart';

class PublicUserService {
  PublicUserService({ApiClient? apiClient, TokenStorage? tokenStorage})
    : _apiClient = apiClient ?? ApiClient(),
      _tokenStorage = tokenStorage ?? TokenStorage();

  final ApiClient _apiClient;
  final TokenStorage _tokenStorage;

  Future<PublicUserModel> getPublicUser(String id) async {
    final token = await _tokenStorage.getAccessToken();
    if (token == null || token.isEmpty) {
      throw const AuthException(
        'Not authenticated. Please log in.',
        statusCode: 401,
      );
    }

    final response = await _apiClient.get(
      '/users/$id/public',
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
        _extractErrorMessage(response.body, 'Failed to fetch public user'),
        statusCode: response.statusCode,
      );
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return PublicUserModel.fromJson(data['user'] as Map<String, dynamic>);
  }

  /// Submits a user report. The reporter is derived from the JWT on the
  /// backend; the safe response is discarded so the UI can never display an
  /// internal report id or moderation status.
  Future<void> reportUser(
    String id, {
    required String reason,
    String? description,
  }) async {
    final token = await _tokenStorage.getAccessToken();
    if (token == null || token.isEmpty) {
      throw const AuthException(
        'Not authenticated. Please log in.',
        statusCode: 401,
      );
    }

    final response = await _apiClient.post(
      '/users/$id/report',
      headers: {'Authorization': 'Bearer $token'},
      body: {
        'reason': reason,
        if (description != null && description.trim().isNotEmpty)
          'description': description,
      },
    );

    if (response.statusCode == 401) {
      throw const AuthException(
        'Session expired. Please log in again.',
        statusCode: 401,
      );
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw AuthException(
        _extractErrorMessage(response.body, 'Failed to report user'),
        statusCode: response.statusCode,
      );
    }
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
