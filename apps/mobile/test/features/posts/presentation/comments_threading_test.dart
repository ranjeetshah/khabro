import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/auth/data/auth_exception.dart';
import 'package:mobile/features/posts/data/comment_model.dart';
import 'package:mobile/features/posts/data/post_model.dart';
import 'package:mobile/features/posts/data/posts_service.dart';
import 'package:mobile/features/posts/presentation/post_detail_screen.dart';
import 'package:mobile/features/users/data/public_user_model.dart';
import 'package:mobile/features/posts/data/verification_status_model.dart';
import 'package:mobile/features/posts/data/verification_history_model.dart';
import 'package:mobile/features/posts/data/civic_complaint_model.dart';
import 'package:mobile/features/posts/data/verification_status.dart';

class FakeThreadedPostsService extends PostsService {
  FakeThreadedPostsService() : super(apiClient: null, tokenStorage: null);

  @override
  Future<VerificationStatusModel> getVerificationStatus(String id) async {
    return const VerificationStatusModel(
      status: VerificationStatus.reported,
      witnessCount: 0,
    );
  }

  @override
  Future<VerificationHistoryModel> getVerificationHistory(String id) async {
    return const VerificationHistoryModel(events: []);
  }

  @override
  Future<CivicComplaintModel?> getCivicComplaint(String id) async {
    return null;
  }

  bool throwRepliesError = false;
  bool throwCreateReplyError = false;
  int createReplyCalls = 0;
  int getRepliesCalls = 0;

  List<CommentModel> comments = [
    CommentModel(
      id: 'comment-1',
      content: 'This is root comment 1',
      createdAt: DateTime.now(),
      authorId: 'author-123',
      authorName: 'User One',
      replyCount: 2,
    ),
    CommentModel(
      id: 'comment-2',
      content: 'This is root comment 2',
      createdAt: DateTime.now(),
      authorId: 'author-456',
      authorName: 'User Two',
      replyCount: 0,
    ),
  ];

  List<CommentModel> replies = [
    CommentModel(
      id: 'reply-101',
      content: 'I agree with root 1',
      createdAt: DateTime.now(),
      authorId: 'author-Amit',
      authorName: 'Amit',
      parentId: 'comment-1',
      replyCount: 0,
    ),
  ];

  @override
  Future<List<CommentModel>> getComments(
    String postId, {
    int page = 1,
    int limit = 20,
  }) async {
    return comments;
  }

  @override
  Future<List<CommentModel>> getCommentReplies({
    required String postId,
    required String commentId,
    int page = 1,
    int limit = 20,
  }) async {
    getRepliesCalls++;
    if (throwRepliesError) {
      throw const AuthException("Couldn't load replies.", statusCode: 500);
    }
    return replies;
  }

  @override
  Future<CommentModel> createReply({
    required String postId,
    required String commentId,
    required String content,
  }) async {
    createReplyCalls++;
    if (throwCreateReplyError) {
      throw const AuthException("Couldn't post reply.", statusCode: 500);
    }
    return CommentModel(
      id: 'reply-new',
      content: content,
      createdAt: DateTime.now(),
      authorId: 'me-123',
      authorName: 'My Name',
      parentId: commentId,
    );
  }

  @override
  Future<void> deleteComment(String postId, String commentId) async {}
}

void main() {
  final post = PostModel(
    id: 'post-1',
    authorId: 'author-123',
    localityId: 'loc-1',
    content: 'Post Content',
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
    author: const PublicUserModel(id: 'author-123', name: 'User One'),
  );

  group('Deep Comment Threads widget tests', () {
    late FakeThreadedPostsService fakeService;

    testWidgets('renders comments and expands replies on tap', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      fakeService = FakeThreadedPostsService();

      await tester.pumpWidget(
        MaterialApp(
          home: PostDetailScreen(
            post: post,
            postsService: fakeService,
            currentUserId: 'me-123',
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('This is root comment 1'), findsOneWidget);
      expect(find.text('This is root comment 2'), findsOneWidget);

      // Verify replies count is shown
      expect(find.text('2 replies'), findsOneWidget);
      expect(find.text('Amit'), findsNothing); // Amit is in replies, not loaded yet

      // Tap to expand replies
      await tester.tap(find.text('2 replies'));
      await tester.pumpAndSettle();

      expect(fakeService.getRepliesCalls, 1);
      expect(find.text('Amit'), findsOneWidget);
      expect(find.text('I agree with root 1'), findsOneWidget);
      expect(find.text('Collapse replies'), findsOneWidget);

      // Tap to collapse
      await tester.tap(find.text('Collapse replies'));
      await tester.pumpAndSettle();
      expect(find.text('Amit'), findsNothing); // Collapsed
    });

    testWidgets('handles inline reply composition flow', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      fakeService = FakeThreadedPostsService();

      await tester.pumpWidget(
        MaterialApp(
          home: PostDetailScreen(
            post: post,
            postsService: fakeService,
            currentUserId: 'me-123',
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap Reply under comment-1
      final replyButton = find.text('Reply').first;
      await tester.tap(replyButton);
      await tester.pump();

      // Composer should state "Replying to User One"
      expect(find.text('Replying to User One'), findsOneWidget);

      // Enter text and submit
      await tester.enterText(find.byType(TextField), 'Testing my reply');
      await tester.tap(find.byIcon(Icons.send));
      await tester.pumpAndSettle();

      expect(fakeService.createReplyCalls, 1);
      // Keyboard input cleared, replyingTo cleared
      expect(find.text('Replying to User One'), findsNothing);
    });

    testWidgets('handles retry flow when loading replies fails', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      fakeService = FakeThreadedPostsService();
      fakeService.throwRepliesError = true;

      await tester.pumpWidget(
        MaterialApp(
          home: PostDetailScreen(
            post: post,
            postsService: fakeService,
            currentUserId: 'me-123',
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap to expand
      await tester.tap(find.text('2 replies'));
      await tester.pumpAndSettle();

      expect(find.text("Couldn't load replies."), findsOneWidget);
      expect(find.text('RETRY'), findsOneWidget);

      fakeService.throwRepliesError = false;
      await tester.tap(find.text('RETRY'));
      await tester.pumpAndSettle();

      expect(find.text('Amit'), findsOneWidget);
    });
  });
}
