import 'dart:convert';

import '../../../core/network/api_client.dart';
import '../../../core/storage/token_storage.dart';
import '../../auth/data/auth_exception.dart';
import 'feed_page_model.dart';

class FeedService {
  FeedService({ApiClient? apiClient, TokenStorage? tokenStorage})
    : _apiClient = apiClient ?? ApiClient(),
      _tokenStorage = tokenStorage ?? TokenStorage();

  final ApiClient _apiClient;
  final TokenStorage _tokenStorage;

  Future<FeedPageModel> getFeed({String? cursor, int? limit}) async {
    final token = await _tokenStorage.getAccessToken();
    if (token == null || token.isEmpty) {
      throw const AuthException(
        'Not authenticated. Please log in.',
        statusCode: 401,
      );
    }

    final query = <String, String>{};
    if (limit != null) query['limit'] = '$limit';
    if (cursor != null) query['cursor'] = cursor;
    final path = query.isEmpty
        ? '/feed'
        : '/feed?${query.entries.map((entry) => '${entry.key}=${Uri.encodeQueryComponent(entry.value)}').join('&')}';

    final response = await _apiClient.get(
      path,
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
        _extractErrorMessage(response.body, 'Failed to load feed'),
        statusCode: response.statusCode,
      );
    }

    return FeedPageModel.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
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
