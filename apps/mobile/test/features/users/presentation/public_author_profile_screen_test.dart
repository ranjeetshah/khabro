import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/auth/data/auth_exception.dart';
import 'package:mobile/features/chat/data/chat_service.dart';
import 'package:mobile/features/chat/data/conversation_model.dart';
import 'package:mobile/features/chat/data/message_model.dart';
import 'package:mobile/features/chat/presentation/chat_detail_screen.dart';
import 'package:mobile/features/users/data/public_user_model.dart';
import 'package:mobile/features/users/data/public_user_service.dart';
import 'package:mobile/features/users/presentation/public_author_profile_screen.dart';

class FakePublicUserService extends PublicUserService {
  FakePublicUserService({this.user, this.error})
    : super(apiClient: null, tokenStorage: null);

  final PublicUserModel? user;
  final AuthException? error;
  var calls = 0;
  var reportCalls = 0;
  String? reportUserId;
  String? reportReason;

  @override
  Future<PublicUserModel> getPublicUser(String id) async {
    calls++;
    if (error != null) throw error!;
    return user!;
  }

  @override
  Future<void> reportUser(
    String id, {
    required String reason,
    String? description,
  }) async {
    reportCalls++;
    reportUserId = id;
    reportReason = reason;
  }
}

class FakeChatService extends ChatService {
  FakeChatService() : super(apiClient: null, tokenStorage: null);

  int createConversationCalls = 0;

  @override
  Future<StartedConversation> createConversation(String userId) async {
    createConversationCalls++;
    return StartedConversation(
      id: 'conversation-1',
      participant: const ConversationParticipant(id: 'author-1', name: 'Test User'),
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
  Future<void> markAsRead(String conversationId) async {}
}

void main() {
  testWidgets('renders only the public name', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: PublicAuthorProfileScreen(
          userId: 'author-1',
          publicUserService: FakePublicUserService(
            user: const PublicUserModel(id: 'author-1', name: 'Test User'),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Test User'), findsOneWidget);
    expect(find.text('author-1'), findsNothing);
    expect(find.textContaining('phone'), findsNothing);
    expect(find.textContaining('email'), findsNothing);
    expect(find.textContaining('trustScore'), findsNothing);
    expect(find.textContaining('latitude'), findsNothing);
  });

  testWidgets('uses the fallback for null names', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: PublicAuthorProfileScreen(
          userId: 'author-1',
          publicUserService: FakePublicUserService(
            user: const PublicUserModel(id: 'author-1', name: null),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Khabro User'), findsOneWidget);
  });

  testWidgets('handles not found and network errors safely', (tester) async {
    final notFound = FakePublicUserService(
      error: const AuthException('Public user not found', statusCode: 404),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: PublicAuthorProfileScreen(
          userId: 'missing',
          publicUserService: notFound,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('User not found.'), findsOneWidget);
    expect(find.text('RETRY'), findsNothing);

    final failed = FakePublicUserService(
      error: const AuthException('Server unavailable', statusCode: 500),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: PublicAuthorProfileScreen(
          userId: 'author-1',
          publicUserService: failed,
          key: const ValueKey('network-error-profile'),
        ),
      ),
    );
    await tester.pump();
    await tester.pumpAndSettle();
    expect(find.text("Couldn't load profile."), findsOneWidget);
    expect(find.text('RETRY'), findsOneWidget);
    await tester.tap(find.text('RETRY'));
    await tester.pumpAndSettle();
    expect(failed.calls, 2);
  });

  testWidgets('report user submits the selected reason safely', (tester) async {
    final service = FakePublicUserService(
      user: const PublicUserModel(id: 'author-1', name: 'Test User'),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: PublicAuthorProfileScreen(
          userId: 'author-1',
          publicUserService: service,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('More options'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Report user'));
    await tester.pumpAndSettle();
    expect(find.text('Why are you reporting this?'), findsOneWidget);

    await tester.tap(find.text('Harassment'));
    await tester.pump();
    await tester.tap(find.widgetWithText(FilledButton, 'Submit report'));
    await tester.pumpAndSettle();

    expect(service.reportCalls, 1);
    expect(service.reportUserId, 'author-1');
    expect(service.reportReason, 'HARASSMENT');
    expect(find.text('Report submitted'), findsOneWidget);
    expect(find.text('author-1'), findsNothing);
    expect(find.text('report-1'), findsNothing);
    expect(find.text('JWT'), findsNothing);
  });

  testWidgets('Message button starts a conversation and opens the chat', (
    tester,
  ) async {
    final chatService = FakeChatService();
    await tester.pumpWidget(
      MaterialApp(
        home: PublicAuthorProfileScreen(
          userId: 'author-1',
          currentUserId: 'me-1',
          publicUserService: FakePublicUserService(
            user: const PublicUserModel(id: 'author-1', name: 'Test User'),
          ),
          chatService: chatService,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Message'), findsOneWidget);
    await tester.tap(find.text('Message'));
    await tester.pumpAndSettle();

    expect(chatService.createConversationCalls, 1);
    expect(find.byType(ChatDetailScreen), findsOneWidget);
  });

  testWidgets('Message button is hidden when viewing oneself', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: PublicAuthorProfileScreen(
          userId: 'author-1',
          currentUserId: 'author-1',
          publicUserService: FakePublicUserService(
            user: const PublicUserModel(id: 'author-1', name: 'Test User'),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Message'), findsNothing);
  });
}
