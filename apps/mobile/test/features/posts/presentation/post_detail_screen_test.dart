import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/auth/data/auth_exception.dart';
import 'package:mobile/features/posts/data/post_model.dart';
import 'package:mobile/features/posts/data/posts_service.dart';
import 'package:mobile/features/posts/data/like_status_model.dart';
import 'package:mobile/features/posts/presentation/post_detail_screen.dart';
import 'package:mobile/features/users/data/public_user_model.dart';
import 'package:mobile/features/users/data/public_user_service.dart';
import 'package:mobile/features/users/presentation/public_author_profile_screen.dart';

PostModel detailPost({String? name = 'Test User'}) => PostModel(
  id: 'post-1',
  authorId: 'private-author-id',
  localityId: 'private-locality-id',
  content: 'Hello Khabro!',
  createdAt: DateTime.parse('2026-08-09T08:00:00.000Z'),
  updatedAt: DateTime.parse('2026-08-09T08:00:01.000Z'),
  author: PublicUserModel(id: 'author-1', name: name),
);

class FakePublicUserService extends PublicUserService {
  FakePublicUserService({this.user, this.error})
    : super(apiClient: null, tokenStorage: null);

  final PublicUserModel? user;
  final AuthException? error;
  var calls = 0;

  @override
  Future<PublicUserModel> getPublicUser(String id) async {
    calls++;
    if (error != null) throw error!;
    return user!;
  }
}

class FakeDeletePostsService extends PostsService {
  FakeDeletePostsService({this.errors = const []})
    : super(apiClient: null, tokenStorage: null);

  final List<Object> errors;
  var calls = 0;
  String? deletedId;
  var likeCalls = 0;
  var unlikeCalls = 0;

  @override
  Future<void> deletePost(String id) async {
    calls++;
    deletedId = id;
    if (calls <= errors.length) throw errors[calls - 1];
  }

  @override
  Future<LikeStatusModel> likePost(String id) async {
    likeCalls++;
    return const LikeStatusModel(likeCount: 1, likedByMe: true);
  }

  @override
  Future<LikeStatusModel> unlikePost(String id) async {
    unlikeCalls++;
    return const LikeStatusModel(likeCount: 0, likedByMe: false);
  }
}

void main() {
  testWidgets('renders safe post detail fields', (tester) async {
    await tester.pumpWidget(
      MaterialApp(home: PostDetailScreen(post: detailPost())),
    );

    expect(find.text('Test User'), findsOneWidget);
    expect(find.text('Hello Khabro!'), findsOneWidget);
    expect(find.textContaining('2026-08-09'), findsOneWidget);
    expect(find.text('private-author-id'), findsNothing);
    expect(find.text('latitude'), findsNothing);
    expect(find.text('longitude'), findsNothing);
    expect(find.text('private-locality-id'), findsNothing);
  });

  testWidgets(
    'author tap opens the public profile and back returns to detail',
    (tester) async {
      final service = FakePublicUserService(
        user: const PublicUserModel(id: 'author-1', name: 'Test User'),
      );
      await tester.pumpWidget(
        MaterialApp(
          home: PostDetailScreen(
            post: detailPost(),
            publicUserService: service,
          ),
        ),
      );

      await tester.tap(find.text('Test User'));
      await tester.pumpAndSettle();
      expect(find.byType(PublicAuthorProfileScreen), findsOneWidget);
      expect(find.text('Test User'), findsOneWidget);
      expect(service.calls, 1);

      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.text('Hello Khabro!'), findsOneWidget);
    },
  );

  testWidgets('uses the safe fallback when author name is empty', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: PostDetailScreen(post: detailPost(name: '')),
      ),
    );
    expect(find.text('Khabro User'), findsOneWidget);
    expect(find.text('author-1'), findsNothing);
  });

  testWidgets('only the owner sees delete and cancel makes no request', (
    tester,
  ) async {
    final service = FakeDeletePostsService();
    await tester.pumpWidget(
      MaterialApp(
        home: PostDetailScreen(
          post: detailPost(),
          currentUserId: 'private-author-id',
          postsService: service,
        ),
      ),
    );
    expect(find.byTooltip('Delete post'), findsOneWidget);
    await tester.tap(find.byTooltip('Delete post'));
    await tester.pumpAndSettle();
    expect(find.text('Delete post?'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(service.calls, 0);
    expect(find.text('Hello Khabro!'), findsOneWidget);

    await tester.pumpWidget(
      MaterialApp(
        home: PostDetailScreen(
          post: detailPost(),
          currentUserId: 'different-user',
          postsService: service,
        ),
      ),
    );
    expect(find.byTooltip('Delete post'), findsNothing);
  });

  testWidgets('confirming delete calls the service and closes detail', (
    tester,
  ) async {
    final service = FakeDeletePostsService();
    await tester.pumpWidget(
      MaterialApp(
        home: PostDetailScreen(
          post: detailPost(),
          currentUserId: 'private-author-id',
          postsService: service,
        ),
      ),
    );
    await tester.tap(find.byTooltip('Delete post'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();

    expect(service.calls, 1);
    expect(service.deletedId, 'post-1');
    expect(find.text('Hello Khabro!'), findsNothing);
  });

  testWidgets('delete errors are safe and retry works', (tester) async {
    final service = FakeDeletePostsService(
      errors: [
        const AuthException('Forbidden', statusCode: 403),
        const AuthException('Not found', statusCode: 404),
      ],
    );
    await tester.pumpWidget(
      MaterialApp(
        home: PostDetailScreen(
          post: detailPost(),
          currentUserId: 'private-author-id',
          postsService: service,
        ),
      ),
    );
    await tester.tap(find.byTooltip('Delete post'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();
    expect(find.text('You can only delete your own posts.'), findsOneWidget);
    expect(find.text('private-author-id'), findsNothing);

    await tester.tap(find.text('RETRY'));
    await tester.pumpAndSettle();
    expect(find.text('Post not found.'), findsOneWidget);
    expect(find.text('Hello Khabro!'), findsOneWidget);
  });

  testWidgets('like and unlike work without leaving post detail', (
    tester,
  ) async {
    final service = FakeDeletePostsService();
    await tester.pumpWidget(
      MaterialApp(
        home: PostDetailScreen(post: detailPost(), postsService: service),
      ),
    );
    expect(find.text('0'), findsOneWidget);
    await tester.tap(find.byTooltip('Like'));
    await tester.pumpAndSettle();
    expect(service.likeCalls, 1);
    expect(find.text('1'), findsOneWidget);
    expect(find.byTooltip('Unlike'), findsOneWidget);
    await tester.tap(find.byTooltip('Unlike'));
    await tester.pumpAndSettle();
    expect(service.unlikeCalls, 1);
    expect(find.text('0'), findsOneWidget);
    expect(find.text('Hello Khabro!'), findsOneWidget);
  });

  testWidgets('handles session expiry and network failures safely', (
    tester,
  ) async {
    var sessionExpired = false;
    final service = FakeDeletePostsService(
      errors: [
        const AuthException('Unauthorized', statusCode: 401),
        Exception('network failure'),
      ],
    );
    await tester.pumpWidget(
      MaterialApp(
        home: PostDetailScreen(
          post: detailPost(),
          currentUserId: 'private-author-id',
          postsService: service,
          onSessionExpired: () => sessionExpired = true,
        ),
      ),
    );
    await tester.tap(find.byTooltip('Delete post'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();
    expect(sessionExpired, isTrue);
    expect(find.text("Couldn't delete this post."), findsOneWidget);

    await tester.tap(find.text('RETRY'));
    await tester.pumpAndSettle();
    expect(find.text("Couldn't delete this post."), findsOneWidget);
    expect(find.text('Hello Khabro!'), findsOneWidget);
  });
}
