import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/auth/data/auth_exception.dart';
import 'package:mobile/features/chat/data/chat_service.dart';
import 'package:mobile/features/chat/data/conversation_model.dart';
import 'package:mobile/features/chat/data/message_model.dart';
import 'package:mobile/features/chat/presentation/chat_detail_screen.dart';
import 'package:mobile/features/chat/presentation/conversations_screen.dart';

class FakeChatService extends ChatService {
  FakeChatService() : super(apiClient: null, tokenStorage: null);

  bool throwError = false;
  bool throw401 = false;
  bool hasMoreFirstPage = false;
  List<ConversationModel> conversations = [];
  List<ConversationModel> pageTwo = [];
  int getConversationsCalls = 0;

  @override
  Future<ConversationListResult> getConversations({
    int page = 1,
    int limit = 20,
  }) async {
    getConversationsCalls++;
    if (throwError) {
      throw const AuthException('Failed to load conversations', statusCode: 500);
    }
    if (throw401) {
      throw const AuthException('Session expired', statusCode: 401);
    }
    if (page == 1) {
      return ConversationListResult(
        items: conversations,
        page: 1,
        limit: limit,
        total: conversations.length + pageTwo.length,
        hasMore: hasMoreFirstPage,
      );
    }
    return ConversationListResult(
      items: pageTwo,
      page: page,
      limit: limit,
      total: conversations.length + pageTwo.length,
      hasMore: false,
    );
  }

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

ConversationModel conversation(String id, String name, int unread, String preview) {
  return ConversationModel(
    id: id,
    participant: ConversationParticipant(id: 'participant-$id', name: name),
    lastMessage: LastMessagePreview(
      id: 'last-$id',
      content: preview,
      createdAt: DateTime.now(),
      senderId: 'participant-$id',
    ),
    unreadCount: unread,
    updatedAt: DateTime.now(),
  );
}

void main() {
  testWidgets('renders conversations with names and previews', (tester) async {
    final service = FakeChatService()
      ..conversations = [
        conversation('c1', 'Jane Doe', 0, 'See you soon'),
        conversation('c2', 'Ravi Kumar', 0, 'Thanks!'),
      ];

    await tester.pumpWidget(
      MaterialApp(home: ConversationsScreen(chatService: service)),
    );
    await tester.pumpAndSettle();

    expect(find.text('Messages'), findsOneWidget);
    expect(find.text('Jane Doe'), findsOneWidget);
    expect(find.text('Ravi Kumar'), findsOneWidget);
    expect(find.text('See you soon'), findsOneWidget);
    expect(find.text('Thanks!'), findsOneWidget);
  });

  testWidgets('shows an unread badge on conversations with unread messages', (
    tester,
  ) async {
    final service = FakeChatService()
      ..conversations = [
        conversation('c1', 'Jane Doe', 3, 'See you soon'),
        conversation('c2', 'Ravi Kumar', 0, 'Thanks!'),
      ];

    await tester.pumpWidget(
      MaterialApp(home: ConversationsScreen(chatService: service)),
    );
    await tester.pumpAndSettle();

    expect(find.text('3'), findsOneWidget);
    expect(find.text('0'), findsNothing);
  });

  testWidgets('renders the empty state', (tester) async {
    final service = FakeChatService();

    await tester.pumpWidget(
      MaterialApp(home: ConversationsScreen(chatService: service)),
    );
    await tester.pumpAndSettle();

    expect(find.text('No conversations yet.'), findsOneWidget);
  });

  testWidgets('shows error state and retries cleanly', (tester) async {
    final service = FakeChatService()..throwError = true;

    await tester.pumpWidget(
      MaterialApp(home: ConversationsScreen(chatService: service)),
    );
    await tester.pumpAndSettle();

    expect(find.text('Failed to load conversations'), findsOneWidget);
    expect(find.text('RETRY'), findsOneWidget);

    service.throwError = false;
    service.conversations = [conversation('c1', 'Jane Doe', 0, 'Hey')];

    await tester.tap(find.text('RETRY'));
    await tester.pumpAndSettle();

    expect(find.text('Jane Doe'), findsOneWidget);
  });

  testWidgets('handles session expiry via 401', (tester) async {
    final service = FakeChatService()..throw401 = true;
    var sessionExpiredCalled = false;

    await tester.pumpWidget(
      MaterialApp(
        home: ConversationsScreen(
          chatService: service,
          onSessionExpired: () {
            sessionExpiredCalled = true;
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(sessionExpiredCalled, isTrue);
  });

  testWidgets('loads the next page when scrolled to the bottom', (tester) async {
    final service = FakeChatService()
      ..hasMoreFirstPage = true
      ..conversations = [
        for (var i = 0; i < 12; i++) conversation('c$i', 'User $i', 0, 'Preview $i'),
      ]
      ..pageTwo = [
        conversation('c-extra-1', 'Priya Singh', 0, 'Hello'),
        conversation('c-extra-2', 'Ali Khan', 0, 'Yo'),
      ];

    await tester.pumpWidget(
      MaterialApp(home: ConversationsScreen(chatService: service)),
    );
    await tester.pumpAndSettle();

    expect(find.text('Priya Singh'), findsNothing);

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

    expect(find.text('Priya Singh'), findsOneWidget);
    expect(find.text('Ali Khan'), findsOneWidget);
  });

  testWidgets('tapping a conversation opens the chat detail screen', (
    tester,
  ) async {
    final service = FakeChatService()
      ..conversations = [conversation('c1', 'Jane Doe', 0, 'See you soon')];

    await tester.pumpWidget(
      MaterialApp(home: ConversationsScreen(chatService: service)),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Jane Doe'));
    await tester.pumpAndSettle();

    expect(find.byType(ChatDetailScreen), findsOneWidget);
  });
}