import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/auth/data/auth_exception.dart';
import 'package:mobile/features/chat/data/chat_service.dart';
import 'package:mobile/features/chat/data/conversation_model.dart';
import 'package:mobile/features/chat/data/message_model.dart';
import 'package:mobile/features/chat/presentation/chat_detail_screen.dart';

class FakeChatService extends ChatService {
  FakeChatService() : super(apiClient: null, tokenStorage: null);

  bool throwError = false;
  bool throw401 = false;
  bool hasMoreFirstPage = false;
  List<MessageModel> pageOne = [];
  List<MessageModel> pageTwo = [];
  int getMessagesCalls = 0;
  int sendCalls = 0;
  String? sentContent;
  int deleteCalls = 0;
  int markReadCalls = 0;

  @override
  Future<MessageListResult> getMessages(
    String conversationId, {
    int page = 1,
    int limit = 20,
  }) async {
    getMessagesCalls++;
    if (throwError) {
      throw const AuthException('Failed to load messages', statusCode: 500);
    }
    if (throw401) {
      throw const AuthException('Session expired', statusCode: 401);
    }
    if (page == 1) {
      return MessageListResult(
        items: pageOne,
        page: 1,
        limit: limit,
        total: pageOne.length + pageTwo.length,
        hasMore: hasMoreFirstPage,
      );
    }
    return MessageListResult(
      items: pageTwo,
      page: page,
      limit: limit,
      total: pageOne.length + pageTwo.length,
      hasMore: false,
    );
  }

  @override
  Future<MessageModel> sendMessage(
    String conversationId,
    String content, {
    String? clientMessageId,
  }) async {
    sendCalls++;
    sentContent = content;
    return MessageModel(
      id: 'sent-$sendCalls',
      conversationId: conversationId,
      senderId: 'me',
      content: content,
      createdAt: DateTime.now(),
      deleted: false,
    );
  }

  @override
  Future<void> deleteMessage(String conversationId, String messageId) async {
    deleteCalls++;
  }

  @override
  Future<void> markAsRead(String conversationId) async {
    markReadCalls++;
  }

  @override
  Future<ConversationDetail> getConversationDetail(String conversationId) async {
    return const ConversationDetail(
      id: 'conversation-1',
      participant: ConversationParticipant(id: 'user-2', name: 'Jane Doe'),
    );
  }
}

MessageModel message(
  String id,
  String sender,
  String content, {
  bool deleted = false,
}) {
  return MessageModel(
    id: id,
    conversationId: 'conversation-1',
    senderId: sender,
    content: deleted ? null : content,
    createdAt: DateTime.now(),
    deleted: deleted,
  );
}

Future<void> scrollToEnd(WidgetTester tester) async {
  final scrollable = tester.state<ScrollableState>(
    find
        .descendant(
          of: find.byType(ListView),
          matching: find.byType(Scrollable),
        )
        .first,
  );
  scrollable.position.jumpTo(scrollable.position.maxScrollExtent);
  await tester.pumpAndSettle();
  scrollable.position.jumpTo(scrollable.position.maxScrollExtent);
  await tester.pumpAndSettle();
}

Widget buildScreen(
  FakeChatService service, {
  VoidCallback? onSessionExpired,
}) {
  return MaterialApp(
    home: ChatDetailScreen(
      conversationId: 'conversation-1',
      participantName: 'Jane Doe',
      currentUserId: 'me',
      chatService: service,
      onSessionExpired: onSessionExpired,
    ),
  );
}

void main() {
  testWidgets('renders own and other message bubbles', (tester) async {
    final service = FakeChatService()
      ..pageOne = [
        message('m2', 'user-2', 'Hello!'),
        message('m1', 'me', 'Hi there'),
      ];

    await tester.pumpWidget(buildScreen(service));
    await tester.pumpAndSettle();

    expect(find.text('Hello!'), findsOneWidget);
    expect(find.text('Hi there'), findsOneWidget);
    expect(find.text('Jane Doe'), findsOneWidget); // AppBar title
  });

  testWidgets('shows Message deleted for deleted messages', (tester) async {
    final service = FakeChatService()
      ..pageOne = [
        message('m1', 'me', 'Secret', deleted: true),
        message('m2', 'user-2', 'Normal message'),
      ];

    await tester.pumpWidget(buildScreen(service));
    await tester.pumpAndSettle();

    expect(find.text('Message deleted'), findsOneWidget);
    expect(find.text('Normal message'), findsOneWidget);
  });

  testWidgets('renders the empty state', (tester) async {
    final service = FakeChatService();

    await tester.pumpWidget(buildScreen(service));
    await tester.pumpAndSettle();

    expect(find.text('No messages yet'), findsOneWidget);
  });

  testWidgets('sends a message and clears the composer', (tester) async {
    final service = FakeChatService();

    await tester.pumpWidget(buildScreen(service));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'Hello there');
    await tester.tap(find.byIcon(Icons.send));
    await tester.pumpAndSettle();

    expect(service.sendCalls, 1);
    expect(service.sentContent, 'Hello there');
    expect(find.text('Hello there'), findsOneWidget);

    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.controller!.text, isEmpty);
  });

  testWidgets('does not send empty or whitespace-only messages', (tester) async {
    final service = FakeChatService();

    await tester.pumpWidget(buildScreen(service));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), '   ');
    await tester.tap(find.byIcon(Icons.send));
    await tester.pumpAndSettle();

    expect(service.sendCalls, 0);
  });

  testWidgets('shows an error state and retries', (tester) async {
    final service = FakeChatService()..throwError = true;

    await tester.pumpWidget(buildScreen(service));
    await tester.pumpAndSettle();

    expect(find.text('Failed to load messages'), findsOneWidget);
    expect(find.text('RETRY'), findsOneWidget);

    service.throwError = false;
    service.pageOne = [message('m1', 'user-2', 'Finally works')];

    await tester.tap(find.text('RETRY'));
    await tester.pumpAndSettle();

    expect(find.text('Finally works'), findsOneWidget);
  });

  testWidgets('handles session expiry via 401', (tester) async {
    final service = FakeChatService()..throw401 = true;
    var sessionExpiredCalled = false;

    await tester.pumpWidget(
      buildScreen(service, onSessionExpired: () => sessionExpiredCalled = true),
    );
    await tester.pumpAndSettle();

    expect(sessionExpiredCalled, isTrue);
  });

  testWidgets('marks the conversation as read when opened', (tester) async {
    final service = FakeChatService()
      ..pageOne = [message('m1', 'user-2', 'Hello!')];

    await tester.pumpWidget(buildScreen(service));
    await tester.pumpAndSettle();

    expect(service.markReadCalls, greaterThanOrEqualTo(1));
  });

  testWidgets('deletes an own message via long-press', (tester) async {
    final service = FakeChatService()
      ..pageOne = [message('m1', 'me', 'Remove me')];

    await tester.pumpWidget(buildScreen(service));
    await tester.pumpAndSettle();

    await tester.longPress(find.text('Remove me'));
    await tester.pumpAndSettle();

    expect(find.text('Delete message'), findsOneWidget);

    await tester.tap(find.text('Delete message'));
    await tester.pumpAndSettle();

    expect(service.deleteCalls, 1);
    expect(find.text('Message deleted'), findsOneWidget);
    expect(find.text('Remove me'), findsNothing);
  });

  testWidgets('loads older messages when scrolled to the top', (tester) async {
    final service = FakeChatService()
      ..hasMoreFirstPage = true
      ..pageOne = [
        for (var i = 0; i < 15; i++) message('recent-$i', 'user-2', 'Recent $i'),
      ]
      ..pageTwo = [
        message('old-1', 'user-2', 'Old message one'),
        message('old-2', 'user-2', 'Old message two'),
      ];

    await tester.pumpWidget(buildScreen(service));
    await tester.pumpAndSettle();

    expect(find.text('Old message one'), findsNothing);

    await scrollToEnd(tester);

    expect(find.text('Old message one'), findsOneWidget);
    expect(find.text('Old message two'), findsOneWidget);
  });
}