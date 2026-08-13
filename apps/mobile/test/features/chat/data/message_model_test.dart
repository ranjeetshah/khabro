import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/chat/data/message_model.dart';

void main() {
  test('parses a full message from JSON', () {
    final json = {
      'id': 'message-1',
      'conversationId': 'conversation-1',
      'senderId': 'user-1',
      'content': 'Hello there',
      'createdAt': '2026-08-13T10:00:00.000Z',
      'deleted': false,
    };

    final model = MessageModel.fromJson(json);

    expect(model.id, 'message-1');
    expect(model.conversationId, 'conversation-1');
    expect(model.senderId, 'user-1');
    expect(model.content, 'Hello there');
    expect(model.createdAt, DateTime.parse('2026-08-13T10:00:00.000Z'));
    expect(model.deleted, isFalse);
  });

  test('handles missing and optional fields gracefully', () {
    final model = MessageModel.fromJson({'id': 'message-2'});

    expect(model.id, 'message-2');
    expect(model.conversationId, isNull);
    expect(model.senderId, '');
    expect(model.content, isNull);
    expect(model.deleted, isFalse);
    expect(model.createdAt, isA<DateTime>());
  });

  test('parses deleted messages with null content', () {
    final model = MessageModel.fromJson({
      'id': 'message-3',
      'senderId': 'user-1',
      'content': null,
      'createdAt': '2026-08-13T11:00:00.000Z',
      'deleted': true,
    });

    expect(model.deleted, isTrue);
    expect(model.content, isNull);
  });

  test('MessageListResult parses pagination metadata', () {
    final json = {
      'items': [
        {
          'id': 'message-1',
          'senderId': 'user-1',
          'content': 'Hi',
          'createdAt': '2026-08-13T10:00:00.000Z',
          'deleted': false,
        },
      ],
      'page': 2,
      'limit': 20,
      'total': 41,
      'hasMore': true,
    };

    final result = MessageListResult.fromJson(json);

    expect(result.items, hasLength(1));
    expect(result.page, 2);
    expect(result.limit, 20);
    expect(result.total, 41);
    expect(result.hasMore, isTrue);
  });

  test('MessageListResult defaults empty items and flags', () {
    final result = MessageListResult.fromJson(const {});
    expect(result.items, isEmpty);
    expect(result.page, 1);
    expect(result.limit, 20);
    expect(result.hasMore, isFalse);
  });
}