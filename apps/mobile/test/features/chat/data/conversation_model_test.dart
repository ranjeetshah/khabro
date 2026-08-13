import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/chat/data/conversation_model.dart';

void main() {
  test('parses a full conversation from JSON', () {
    final json = {
      'id': 'conversation-1',
      'participant': {'id': 'user-2', 'name': 'Jane Doe'},
      'lastMessage': {
        'id': 'message-9',
        'content': 'See you soon',
        'createdAt': '2026-08-13T12:00:00.000Z',
        'senderId': 'user-2',
      },
      'unreadCount': 3,
      'updatedAt': '2026-08-13T12:00:00.000Z',
    };

    final model = ConversationModel.fromJson(json);

    expect(model.id, 'conversation-1');
    expect(model.participant.id, 'user-2');
    expect(model.participant.name, 'Jane Doe');
    expect(model.lastMessage!.content, 'See you soon');
    expect(model.lastMessage!.senderId, 'user-2');
    expect(model.unreadCount, 3);
  });

  test('defaults fields when participant and lastMessage are missing', () {
    final model = ConversationModel.fromJson({
      'id': 'conversation-2',
      'unreadCount': 0,
    });

    expect(model.id, 'conversation-2');
    expect(model.participant.id, '');
    expect(model.participant.name, 'Anonymous');
    expect(model.lastMessage, isNull);
    expect(model.unreadCount, 0);
    expect(model.updatedAt, isA<DateTime>());
  });

  test('ConversationListResult parses items and pagination', () {
    final json = {
      'items': [
        {
          'id': 'conversation-1',
          'participant': {'id': 'user-2', 'name': 'Jane Doe'},
          'unreadCount': 1,
          'updatedAt': '2026-08-13T12:00:00.000Z',
        },
      ],
      'page': 1,
      'limit': 20,
      'total': 5,
      'hasMore': true,
    };

    final result = ConversationListResult.fromJson(json);

    expect(result.items, hasLength(1));
    expect(result.page, 1);
    expect(result.total, 5);
    expect(result.hasMore, isTrue);
  });

  test('StartedConversation parses the created conversation', () {
    final result = StartedConversation.fromJson({
      'id': 'conversation-3',
      'participant': {'id': 'user-9', 'name': 'Ravi Kumar'},
    });

    expect(result.id, 'conversation-3');
    expect(result.participant.id, 'user-9');
    expect(result.participant.name, 'Ravi Kumar');
  });

  test('ConversationDetail parses participant info', () {
    final result = ConversationDetail.fromJson({
      'id': 'conversation-4',
      'participant': {'id': 'user-5', 'name': 'Priya Singh'},
    });

    expect(result.id, 'conversation-4');
    expect(result.participant.name, 'Priya Singh');
  });

  test('StartedConversation and ConversationDetail fall back safely', () {
    final started = StartedConversation.fromJson(const {});
    expect(started.id, '');
    expect(started.participant.name, 'Anonymous');

    final detail = ConversationDetail.fromJson(const {});
    expect(detail.participant.name, 'Anonymous');
  });
}