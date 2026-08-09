import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/auth/data/auth_exception.dart';
import 'package:mobile/features/posts/data/post_model.dart';
import 'package:mobile/features/posts/data/posts_service.dart';
import 'package:mobile/features/posts/presentation/create_post_screen.dart';

class FakePostsService extends PostsService {
  FakePostsService({this.error}) : super(apiClient: null, tokenStorage: null);

  final AuthException? error;
  String? submittedContent;

  @override
  Future<PostModel> createPost(String content) async {
    if (error != null) throw error!;
    submittedContent = content;
    return PostModel(
      id: 'post-1',
      authorId: 'server-user',
      localityId: null,
      content: content,
      createdAt: DateTime.utc(2026, 8, 9),
      updatedAt: DateTime.utc(2026, 8, 9),
    );
  }
}

void main() {
  testWidgets('validates content and shows the character counter', (tester) async {
    final service = FakePostsService();
    await tester.pumpWidget(
      MaterialApp(home: CreatePostScreen(postsService: service)),
    );

    expect(find.text('0 / 5000'), findsOneWidget);
    expect(find.text('0/5000'), findsNothing);
    final postButton = find.ancestor(
      of: find.text('POST'),
      matching: find.byType(ElevatedButton),
    );
    expect(tester.widget<ElevatedButton>(postButton).onPressed, isNull);

    await tester.enterText(find.byType(TextField), '   ');
    await tester.pump();
    expect(tester.widget<ElevatedButton>(postButton).onPressed, isNull);

    await tester.enterText(find.byType(TextField), '  Hello locally  ');
    await tester.pump();
    expect(find.text('17 / 5000'), findsOneWidget);
    expect(find.text('17/5000'), findsNothing);
    expect(tester.widget<ElevatedButton>(postButton).onPressed, isNotNull);
  });

  testWidgets('enforces the 5000 character limit', (tester) async {
    await tester.pumpWidget(
      MaterialApp(home: CreatePostScreen(postsService: FakePostsService())),
    );
    await tester.enterText(find.byType(TextField), 'a' * 5001);
    await tester.pump();
    expect(find.text('5000 / 5000'), findsOneWidget);
  });

  testWidgets('submits trimmed content, clears, and returns to the feed', (tester) async {
    final service = FakePostsService();
    var created = false;
    await tester.pumpWidget(
      MaterialApp(
        home: CreatePostScreen(
          postsService: service,
          onPostCreated: () => created = true,
        ),
      ),
    );
    await tester.enterText(find.byType(TextField), '  Hello locally  ');
    await tester.pump();
    await tester.tap(find.text('POST'));
    await tester.pumpAndSettle();

    expect(service.submittedContent, 'Hello locally');
    expect(created, isTrue);
    expect(find.text('Create Post'), findsNothing);
  });

  testWidgets('displays server errors without exposing internals', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: CreatePostScreen(
          postsService: FakePostsService(
            error: const AuthException('Post rejected', statusCode: 400),
          ),
        ),
      ),
    );
    await tester.enterText(find.byType(TextField), 'Hello');
    await tester.pump();
    await tester.tap(find.text('POST'));
    await tester.pumpAndSettle();
    expect(find.text('Post rejected'), findsOneWidget);
    expect(find.textContaining('HTTP'), findsNothing);
  });
}
