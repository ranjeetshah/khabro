import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../core/network/api_client.dart';
import '../../../core/storage/token_storage.dart';
import '../../auth/data/auth_exception.dart';
import 'conversation_model.dart';
import 'message_model.dart';

/// Service for 1-on-1 chat operations against the Khabro backend.
class ChatService {
  ChatService({ApiClient? apiClient, TokenStorage? tokenStorage})
    : _apiClient = apiClient ?? ApiClient(),
      _tokenStorage = tokenStorage ?? TokenStorage();

  final ApiClient _apiClient;
  final TokenStorage _tokenStorage;

  /// Start (or reuse) a conversation with [userId] via POST /conversations.
  Future<StartedConversation> createConversation(String userId) async {
    final response = await _request(
      (headers) => _apiClient.post(
        '/conversations',
        body: {'userId': userId},
        headers: headers,
      ),
    );
    _checkStatus(response, 'Failed to start chat');
    return StartedConversation.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  /// Fetch the current user's conversations via GET /conversations.
  Future<ConversationListResult> getConversations({
    int page = 1,
    int limit = 20,
  }) async {
    final response = await _request(
      (headers) =>
          _apiClient.get('/conversations?page=$page&limit=$limit', headers: headers),
    );
    _checkStatus(response, "Couldn't load conversations.");
    return ConversationListResult.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  /// Fetch the total unread message count via GET /conversations/unread-count.
  Future<int> getUnreadCount() async {
    final response = await _request(
      (headers) =>
          _apiClient.get('/conversations/unread-count', headers: headers),
    );
    _checkStatus(response, "Couldn't load unread count.");
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return (data['unreadCount'] as num?)?.toInt() ?? 0;
  }

  /// Fetch conversation detail (participant info) via GET /conversations/:id.
  Future<ConversationDetail> getConversationDetail(String conversationId) async {
    final response = await _request(
      (headers) => _apiClient.get('/conversations/$conversationId', headers: headers),
    );
    _checkStatus(response, "Couldn't load conversation.");
    return ConversationDetail.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  /// Send a message via POST /conversations/:id/messages.
  Future<MessageModel> sendMessage(
    String conversationId,
    String content, {
    String? clientMessageId,
  }) async {
    final body = <String, dynamic>{'content': content};
    if (clientMessageId != null) body['clientMessageId'] = clientMessageId;
    final response = await _request(
      (headers) => _apiClient.post(
        '/conversations/$conversationId/messages',
        body: body,
        headers: headers,
      ),
    );
    _checkStatus(response, 'Failed to send message.');
    return MessageModel.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  /// Fetch paginated messages via GET /conversations/:id/messages.
  Future<MessageListResult> getMessages(
    String conversationId, {
    int page = 1,
    int limit = 20,
  }) async {
    final response = await _request(
      (headers) => _apiClient.get(
        '/conversations/$conversationId/messages?page=$page&limit=$limit',
        headers: headers,
      ),
    );
    _checkStatus(response, "Couldn't load messages.");
    return MessageListResult.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  /// Mark a conversation as read via PATCH /conversations/:id/read.
  Future<void> markAsRead(String conversationId) async {
    final response = await _request(
      (headers) =>
          _apiClient.patch('/conversations/$conversationId/read', headers: headers),
    );
    _checkStatus(response, 'Failed to mark conversation as read.');
  }

  /// Soft-delete a message via DELETE /conversations/:cid/messages/:mid.
  Future<void> deleteMessage(String conversationId, String messageId) async {
    final response = await _request(
      (headers) => _apiClient.delete(
        '/conversations/$conversationId/messages/$messageId',
        headers: headers,
      ),
    );
    _checkStatus(response, 'Failed to delete message.');
  }

  Future<http.Response> _request(
    Future<http.Response> Function(Map<String, String> headers) action,
  ) async {
    final token = await _tokenStorage.getAccessToken();
    if (token == null || token.isEmpty) {
      throw const AuthException('Not authenticated', statusCode: 401);
    }
    final headers = {'Authorization': 'Bearer $token'};
    final response = await action(headers);

    if (response.statusCode == 401) {
      try {
        await _tokenStorage.deleteAccessToken();
      } catch (_) {}
      throw const AuthException('Session expired', statusCode: 401);
    }

    return response;
  }

  void _checkStatus(http.Response response, String defaultErrorMsg) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return;
    }
    throw AuthException(
      _extractErrorMessage(response.body, defaultErrorMsg),
      statusCode: response.statusCode,
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