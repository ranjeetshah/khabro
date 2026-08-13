import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../core/network/api_client.dart';
import '../../../core/storage/token_storage.dart';
import '../../auth/data/auth_exception.dart';
import 'notification_model.dart';

class NotificationsService {
  NotificationsService({ApiClient? apiClient, TokenStorage? tokenStorage})
    : _apiClient = apiClient ?? ApiClient(),
      _tokenStorage = tokenStorage ?? TokenStorage();

  final ApiClient _apiClient;
  final TokenStorage _tokenStorage;

  Future<List<NotificationModel>> getNotifications({
    int page = 1,
    int limit = 20,
  }) async {
    final response = await _request(
      (headers) => _apiClient.get(
        '/notifications?page=$page&limit=$limit',
        headers: headers,
      ),
    );
    _checkStatus(response, "Couldn't load notifications.");
    final list = jsonDecode(response.body) as List<dynamic>;
    return list
        .map(
          (item) => NotificationModel.fromJson(item as Map<String, dynamic>),
        )
        .toList();
  }

  Future<int> getUnreadNotificationCount() async {
    final response = await _request(
      (headers) => _apiClient.get('/notifications/unread-count', headers: headers),
    );
    _checkStatus(response, "Couldn't load unread count.");
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return (data['unreadCount'] as num?)?.toInt() ?? 0;
  }

  Future<bool> markNotificationAsRead(String id) async {
    final response = await _request(
      (headers) => _apiClient.patch('/notifications/$id/read', headers: headers),
    );
    _checkStatus(response, 'Failed to mark notification as read.');
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return data['isRead'] as bool? ?? true;
  }

  Future<int> markAllNotificationsAsRead() async {
    final response = await _request(
      (headers) => _apiClient.patch('/notifications/read-all', headers: headers),
    );
    _checkStatus(response, 'Failed to mark all as read.');
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return (data['updatedCount'] as num?)?.toInt() ?? 0;
  }

  Future<http.Response> _request(
    Future<http.Response> Function(Map<String, String> headers) action,
  ) async {
    final token = await _tokenStorage.getAccessToken();
    if (token == null || token.isEmpty) {
      throw const AuthException('Not authenticated');
    }
    final headers = {'Authorization': 'Bearer $token'};
    final response = await action(headers);

    if (response.statusCode == 401) {
      await _tokenStorage.deleteAccessToken();
      throw const AuthException('Session expired');
    }

    return response;
  }

  void _checkStatus(http.Response response, String defaultErrorMsg) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return;
    }
    String message = defaultErrorMsg;
    try {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      if (body['message'] is String) {
        message = body['message'] as String;
      } else if (body['message'] is List) {
        message = (body['message'] as List).join(', ');
      }
    } catch (_) {}
    throw Exception(message);
  }
}
