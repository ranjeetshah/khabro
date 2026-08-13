import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/chat/data/chat_service.dart';
import 'package:mobile/features/chat/data/conversation_model.dart';
import 'package:mobile/features/chat/data/message_model.dart';
import 'package:mobile/features/chat/presentation/chat_detail_screen.dart';
import 'package:mobile/features/notifications/data/notification_model.dart';
import 'package:mobile/features/notifications/data/notifications_service.dart';
import 'package:mobile/features/notifications/presentation/notifications_screen.dart';

class FakeNotificationsService extends NotificationsService {
  FakeNotificationsService() : super(apiClient: null, tokenStorage: null);

  List<NotificationModel> notifications = [];
  int unreadCount = 0;
  bool shouldThrow = false;
  var getCalls = 0;
  var markReadCalls = 0;
  var markAllReadCalls = 0;

  @override
  Future<List<NotificationModel>> getNotifications({
    int page = 1,
    int limit = 20,
  }) async {
    getCalls++;
    if (shouldThrow) throw Exception("Couldn't load notifications.");
    return notifications;
  }

  @override
  Future<int> getUnreadNotificationCount() async {
    return unreadCount;
  }

  @override
  Future<bool> markNotificationAsRead(String id) async {
    markReadCalls++;
    return true;
  }

  @override
  Future<int> markAllNotificationsAsRead() async {
    markAllReadCalls++;
    return notifications.length;
  }
}

class FakeChatService extends ChatService {
  FakeChatService() : super(apiClient: null, tokenStorage: null);

  @override
  Future<MessageListResult> getMessages(
    String conversationId, {
    int page = 1,
    int limit = 20,
  }) async {
    return MessageListResult(
      items: const [],
      page: 1,
      limit: 20,
      total: 0,
      hasMore: false,
    );
  }

  @override
  Future<ConversationDetail> getConversationDetail(String conversationId) async {
    return const ConversationDetail(
      id: 'conversation-1',
      participant: ConversationParticipant(id: 'user-2', name: 'Jane Doe'),
    );
  }

  @override
  Future<void> markAsRead(String conversationId) async {}
}

void main() {
  test('NotificationModel parses JSON safely with unknown type fallback', () {
    final json = {
      'id': 'notif-1',
      'type': 'SOMETHING_NEW',
      'title': 'Test Title',
      'body': 'Test Body',
      'referenceType': 'CIVIC_COMPLAINT',
      'referenceId': 'KH-2026-000123',
      'isRead': false,
      'createdAt': '2026-08-13T10:00:00Z',
    };

    final model = NotificationModel.fromJson(json);

    expect(model.id, equals('notif-1'));
    expect(model.type, equals('SOMETHING_NEW'));
    expect(model.title, equals('Test Title'));
    expect(model.isRead, isFalse);
  });

  testWidgets('renders empty state when no notifications', (tester) async {
    final service = FakeNotificationsService();

    await tester.pumpWidget(
      MaterialApp(
        home: NotificationsScreen(notificationsService: service),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text("You're all caught up."), findsOneWidget);
  });

  testWidgets('renders error state and retries cleanly', (tester) async {
    final service = FakeNotificationsService();
    service.shouldThrow = true;

    await tester.pumpWidget(
      MaterialApp(
        home: NotificationsScreen(notificationsService: service),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text("Couldn't load notifications."), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);

    service.shouldThrow = false;
    service.notifications = [
      NotificationModel(
        id: 'n1',
        type: 'CIVIC_COMPLAINT_SENT',
        title: 'Civic complaint sent',
        body: 'Your civic complaint was sent.',
        referenceType: 'CIVIC_COMPLAINT',
        referenceId: 'KH-2026-000123',
        isRead: false,
        createdAt: DateTime.now(),
      ),
    ];

    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();

    expect(find.text('Civic complaint sent'), findsOneWidget);
    expect(find.text('Your civic complaint was sent.'), findsOneWidget);
  });

  testWidgets('tapping unread notification marks it as read', (tester) async {
    final service = FakeNotificationsService();
    service.notifications = [
      NotificationModel(
        id: 'n1',
        type: 'CIVIC_COMPLAINT_ACKNOWLEDGED',
        title: 'Complaint acknowledged',
        body: 'Your civic complaint was acknowledged.',
        referenceType: 'CIVIC_COMPLAINT',
        referenceId: 'KH-2026-000123',
        isRead: false,
        createdAt: DateTime.now(),
      ),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: NotificationsScreen(notificationsService: service),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Complaint acknowledged'), findsOneWidget);

    await tester.tap(find.text('Complaint acknowledged'));
    await tester.pumpAndSettle();

    expect(service.markReadCalls, equals(1));
  });

  testWidgets('tapping Mark all read updates all items', (tester) async {
    final service = FakeNotificationsService();
    service.notifications = [
      NotificationModel(
        id: 'n1',
        type: 'CIVIC_COMPLAINT_ACKNOWLEDGED',
        title: 'Complaint acknowledged',
        body: 'Acknowledged',
        referenceType: 'CIVIC_COMPLAINT',
        referenceId: 'KH-2026-000123',
        isRead: false,
        createdAt: DateTime.now(),
      ),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: NotificationsScreen(notificationsService: service),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Mark all read'), findsOneWidget);

    await tester.tap(find.text('Mark all read'));
    await tester.pumpAndSettle();

    expect(service.markAllReadCalls, equals(1));
    expect(find.text('Mark all read'), findsNothing);
  });

  testWidgets('tapping a message notification opens the conversation', (
    tester,
  ) async {
    final service = FakeNotificationsService();
    service.notifications = [
      NotificationModel(
        id: 'n-chat-1',
        type: 'MESSAGE_RECEIVED',
        title: 'New message',
        body: 'Jane Doe sent you a message.',
        referenceType: 'CONVERSATION',
        referenceId: 'conversation-1',
        isRead: false,
        createdAt: DateTime.now(),
      ),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: NotificationsScreen(
          notificationsService: service,
          chatService: FakeChatService(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('New message'));
    await tester.pumpAndSettle();

    expect(find.byType(ChatDetailScreen), findsOneWidget);
    expect(find.text('Jane Doe'), findsOneWidget);
  });
}
