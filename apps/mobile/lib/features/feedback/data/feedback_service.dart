import 'dart:convert';

import '../../../core/network/api_client.dart';
import '../../../core/storage/token_storage.dart';
import '../../auth/data/auth_exception.dart';
import '../data/feedback_model.dart';

class FeedbackService {
  FeedbackService({ApiClient? apiClient, TokenStorage? tokenStorage})
    : _apiClient = apiClient ?? ApiClient(),
      _tokenStorage = tokenStorage ?? TokenStorage();

  final ApiClient _apiClient;
  final TokenStorage _tokenStorage;

  Future<FeedbackModel> submitFeedback({
    required FeedbackType type,
    required String message,
    String? appVersion,
    String? platform,
  }) async {
    final response = await _request(
      (headers) => _apiClient.post(
        '/feedback',
        headers: headers,
        body: {
          'type': type.wire.toUpperCase(),
          'message': message,
          if (appVersion != null) 'appVersion': appVersion,
          if (platform != null) 'platform': platform,
        },
      ),
    );
    _checkStatus(response, 'Failed to submit feedback');
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return FeedbackModel.fromJson(data);
  }

  Future<FeedbackPageModel> getMyFeedback({
    int page = 1,
    int limit = 20,
  }) async {
    final uri = Uri(
      path: '/feedback/me',
      queryParameters: {
        'page': page.toString(),
        'limit': limit.toString(),
      },
    );

    final response = await _request(
      (headers) => _apiClient.get(uri.toString(), headers: headers),
    );
    _checkStatus(response, 'Failed to load feedback');
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return FeedbackPageModel.fromJson(data);
  }

  Future<FeedbackPageModel> getFeedbacks({
    int page = 1,
    int limit = 20,
    String? type,
    String? status,
  }) async {
    final queryParams = <String, String>{
      'page': page.toString(),
      'limit': limit.toString(),
    };
    if (type != null && type.isNotEmpty && type != 'ALL') {
      queryParams['type'] = type;
    }
    if (status != null && status.isNotEmpty) {
      queryParams['status'] = status;
    }

    final uri = Uri(
      path: '/moderator/feedback',
      queryParameters: queryParams,
    );

    final response = await _request(
      (headers) => _apiClient.get(uri.toString(), headers: headers),
    );
    _checkStatus(response, 'Failed to load feedback');
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return FeedbackPageModel.fromJson(data);
  }

  Future<FeedbackModel> getFeedbackDetail(String id) async {
    final response = await _request(
      (headers) => _apiClient.get('/moderator/feedback/$id', headers: headers),
    );
    _checkStatus(response, 'Failed to load feedback detail');
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return FeedbackModel.fromJson(data);
  }

  Future<void> updateFeedbackStatus(String id, String status) async {
    final response = await _request(
      (headers) => _apiClient.patch(
        '/moderator/feedback/$id/status',
        headers: headers,
        body: {'status': status},
      ),
    );
    _checkStatus(response, 'Failed to update feedback status');
  }

  Future<dynamic> _request(
    Future<dynamic> Function(Map<String, String> headers) request,
  ) async {
    final token = await _tokenStorage.getAccessToken();
    if (token == null || token.isEmpty) {
      throw const AuthException(
        'Not authenticated. Please log in.',
        statusCode: 401,
      );
    }
    return request({'Authorization': 'Bearer $token'});
  }

  void _checkStatus(dynamic response, String fallback) {
    if (response.statusCode == 401) {
      throw const AuthException(
        'Session expired. Please log in again.',
        statusCode: 401,
      );
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw AuthException(
        _extractErrorMessage(response.body, fallback),
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
