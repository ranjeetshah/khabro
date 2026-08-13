import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart' as http_testing;
import 'package:mobile/core/network/api_client.dart';
import 'package:mobile/core/storage/token_storage.dart';
import 'package:mobile/features/auth/data/auth_exception.dart';
import 'package:mobile/features/chat/data/chat_service.dart';

class FakeTokenStorage extends TokenStorage {
  FakeTokenStorage([this.token]) : super(storage: null);
  String? token;

  @override
  Future<String?> getAccessToken() async => token;
}

ChatService serviceFor(
  FakeTokenStorage storage,
  http_testing.MockClientHandler handler,
) => ChatService(
  tokenStorage: storage,
  apiClient: ApiClient(httpClient: http_testing.MockClient(handler)),
);

void main() {
  test('createConversation posts the target user id with the bearer token', () async {
    final service = serviceFor(FakeTokenStorage('jwt'), (request) async {
      expect(request.method, 'POST');
      expect(request.url.path, '/conversations');
      expect(request.headers['Authorization'], 'Bearer jwt');
      expect(jsonDecode(request.body), {'userId': 'user-2'});
      return http.Response(
        jsonEncode({
          'id': 'conversation-1',
          'participant': {'id': 'user-2', 'name': 'Jane Doe'},
        }),
        201,
      );
    });

    final result = await service.createConversation('user-2');
    expect(result.id, 'conversation-1');
    expect(result.participant.id, 'user-2');
    expect(result.participant.name, 'Jane Doe');
  });

  test('getConversations requests pagination and parses the list', () async {
    final service = serviceFor(FakeTokenStorage('jwt'), (request) async {
      expect(request.url.path, '/conversations');
      expect(request.url.queryParameters['page'], '2');
      expect(request.url.queryParameters['limit'], '10');
      return http.Response(
        jsonEncode({
          'items': [
            {
              'id': 'conversation-1',
              'participant': {'id': 'user-2', 'name': 'Jane'},
              'unreadCount': 1,
              'updatedAt': '2026-08-13T12:00:00.000Z',
            },
          ],
          'page': 2,
          'limit': 10,
          'total': 11,
          'hasMore': true,
        }),
        200,
      );
    });

    final result = await service.getConversations(page: 2, limit: 10);
    expect(result.items.single.id, 'conversation-1');
    expect(result.page, 2);
    expect(result.hasMore, isTrue);
  });

  test('getUnreadCount parses the global unread count', () async {
    final service = serviceFor(FakeTokenStorage('jwt'), (request) async {
      expect(request.url.path, '/conversations/unread-count');
      return http.Response(jsonEncode({'unreadCount': 7}), 200);
    });

    expect(await service.getUnreadCount(), 7);
  });

  test('getConversationDetail parses participant info', () async {
    final service = serviceFor(FakeTokenStorage('jwt'), (request) async {
      expect(request.url.path, '/conversations/conversation-1');
      return http.Response(
        jsonEncode({
          'id': 'conversation-1',
          'participant': {'id': 'user-2', 'name': 'Jane Doe'},
        }),
        200,
      );
    });

    final detail = await service.getConversationDetail('conversation-1');
    expect(detail.participant.name, 'Jane Doe');
  });

  test('sendMessage posts content and parses the created message', () async {
    final service = serviceFor(FakeTokenStorage('jwt'), (request) async {
      expect(request.url.path, '/conversations/conversation-1/messages');
      final body = jsonDecode(request.body) as Map<String, dynamic>;
      expect(body['content'], 'Hello');
      expect(body['clientMessageId'], 'local-1');
      return http.Response(
        jsonEncode({
          'id': 'message-1',
          'conversationId': 'conversation-1',
          'senderId': 'user-1',
          'content': 'Hello',
          'createdAt': '2026-08-13T12:00:00.000Z',
        }),
        201,
      );
    });

    final message = await service.sendMessage(
      'conversation-1',
      'Hello',
      clientMessageId: 'local-1',
    );
    expect(message.id, 'message-1');
    expect(message.content, 'Hello');
  });

  test('getMessages requests pagination for the conversation', () async {
    final service = serviceFor(FakeTokenStorage('jwt'), (request) async {
      expect(request.url.path, '/conversations/conversation-1/messages');
      expect(request.url.queryParameters['page'], '1');
      return http.Response(
        jsonEncode({
          'items': [
            {
              'id': 'message-1',
              'senderId': 'user-2',
              'content': 'Hi',
              'createdAt': '2026-08-13T12:00:00.000Z',
              'deleted': false,
            },
          ],
          'page': 1,
          'limit': 20,
          'total': 1,
          'hasMore': false,
        }),
        200,
      );
    });

    final result = await service.getMessages('conversation-1');
    expect(result.items.single.content, 'Hi');
    expect(result.hasMore, isFalse);
  });

  test('markAsRead PATCHes the read endpoint', () async {
    final service = serviceFor(FakeTokenStorage('jwt'), (request) async {
      expect(request.method, 'PATCH');
      expect(request.url.path, '/conversations/conversation-1/read');
      return http.Response(jsonEncode({'read': true}), 200);
    });

    await service.markAsRead('conversation-1');
  });

  test('deleteMessage DELETEs the message endpoint', () async {
    final service = serviceFor(FakeTokenStorage('jwt'), (request) async {
      expect(request.method, 'DELETE');
      expect(request.url.path, '/conversations/conversation-1/messages/message-1');
      return http.Response(jsonEncode({'success': true}), 200);
    });

    await service.deleteMessage('conversation-1', 'message-1');
  });

  test('handles missing token, 401, and server errors', () async {
    final missing = serviceFor(FakeTokenStorage(), (request) async {
      fail('request should not be made');
    });
    expect(
      () => missing.getConversations(),
      throwsA(isA<AuthException>()),
    );

    final expired = serviceFor(FakeTokenStorage('jwt'), (request) async {
      return http.Response(jsonEncode({'message': 'Unauthorized'}), 401);
    });
    expect(
      () => expired.getConversations(),
      throwsA(
        isA<AuthException>().having((e) => e.statusCode, 'status', 401),
      ),
    );

    final failed = serviceFor(FakeTokenStorage('jwt'), (request) async {
      return http.Response(jsonEncode({'message': 'Conversations unavailable'}), 500);
    });
    expect(
      () => failed.getConversations(),
      throwsA(
        isA<AuthException>()
            .having((e) => e.message, 'message', 'Conversations unavailable'),
      ),
    );
  });
}