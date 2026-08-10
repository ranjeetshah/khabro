import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/feed/data/feed_page_model.dart';
import 'package:mobile/features/feed/data/feed_service.dart';
import 'package:mobile/features/feed/presentation/feed_screen.dart';
import 'package:mobile/features/auth/data/auth_exception.dart';
import 'package:mobile/features/location/data/locality_model.dart';
import 'package:mobile/features/location/data/locality_service.dart';
import 'package:mobile/features/posts/data/post_model.dart';
import 'package:mobile/features/posts/data/posts_service.dart';
import 'package:mobile/features/posts/data/like_status_model.dart';
import 'package:mobile/features/posts/data/verification_status.dart';
import 'package:mobile/features/posts/data/witness_status_model.dart';
import 'package:mobile/features/users/data/public_user_model.dart';
import 'package:mobile/features/users/data/public_user_service.dart';

PostModel post(String id, String content) => PostModel(
  id: id,
  authorId: 'user-1',
  localityId: 'locality-a',
  content: content,
  createdAt: DateTime.parse('2026-08-09T08:00:00.000Z'),
  updatedAt: DateTime.parse('2026-08-09T08:00:01.000Z'),
);

PostModel authoredPost(
  String id,
  String content, {
  String? name,
  int? likeCount,
  bool? likedByMe,
  int? witnessCount,
  bool? witnessedByMe,
  VerificationStatus verificationStatus = VerificationStatus.reported,
}) => PostModel(
  id: id,
  authorId: 'private-author-id',
  localityId: 'private-locality-id',
  content: content,
  createdAt: DateTime.parse('2026-08-09T08:00:00.000Z'),
  updatedAt: DateTime.parse('2026-08-09T08:00:01.000Z'),
  author: PublicUserModel(id: 'private-author-id', name: name),
  likeCount: likeCount,
  likedByMe: likedByMe,
  witnessCount: witnessCount,
  witnessedByMe: witnessedByMe,
  verificationStatus: verificationStatus,
);

class FakeFeedService extends FeedService {
  FakeFeedService(this.pages) : super(apiClient: null, tokenStorage: null);

  final List<FeedPageModel> pages;
  var calls = 0;

  @override
  Future<FeedPageModel> getFeed({String? cursor, int? limit}) async {
    final page = pages[calls];
    calls++;
    return page;
  }
}

class FakeLocalityService extends LocalityService {
  FakeLocalityService(this.locality)
    : super(apiClient: null, tokenStorage: null);

  final LocalityModel? locality;

  @override
  Future<LocalityModel?> getMyLocality() async => locality;
}

class RetryingFeedService extends FeedService {
  RetryingFeedService() : super(apiClient: null, tokenStorage: null);

  var calls = 0;

  @override
  Future<FeedPageModel> getFeed({String? cursor, int? limit}) async {
    calls++;
    if (calls == 1) {
      throw const AuthException('Feed unavailable', statusCode: 500);
    }
    return FeedPageModel(
      items: [authoredPost('post-1', 'Recovered post', name: 'Test User')],
      nextCursor: null,
    );
  }
}

class FakeCreatePostsService extends PostsService {
  FakeCreatePostsService() : super(apiClient: null, tokenStorage: null);

  String? submittedContent;

  @override
  Future<PostModel> createPost(String content) async {
    submittedContent = content;
    return authoredPost('post-2', content, name: 'Test User');
  }
}

class FakeDeletePostsService extends PostsService {
  FakeDeletePostsService() : super(apiClient: null, tokenStorage: null);

  var calls = 0;

  @override
  Future<void> deletePost(String id) async => calls++;
}

class FakeLikePostsService extends PostsService {
  FakeLikePostsService({required this.status, this.likeResponse})
    : super(apiClient: null, tokenStorage: null);

  LikeStatusModel status;
  final Future<LikeStatusModel>? likeResponse;
  var likeCalls = 0;
  var unlikeCalls = 0;

  @override
  Future<LikeStatusModel> likePost(String id) async {
    likeCalls++;
    return likeResponse ?? status;
  }

  @override
  Future<LikeStatusModel> unlikePost(String id) async {
    unlikeCalls++;
    return status;
  }
}

class FakePublicUserService extends PublicUserService {
  FakePublicUserService() : super(apiClient: null, tokenStorage: null);

  @override
  Future<PublicUserModel> getPublicUser(String id) async =>
      const PublicUserModel(id: 'author-1', name: 'Test User');
}

class FakeWitnessPostsService extends PostsService {
  FakeWitnessPostsService({required this.status, this.failOnce = false})
    : super(apiClient: null, tokenStorage: null);

  WitnessStatusModel status;
  bool failOnce;
  var witnessCalls = 0;
  var unwitnessCalls = 0;

  @override
  Future<WitnessStatusModel> witnessPost(String id) async {
    witnessCalls++;
    if (failOnce) {
      failOnce = false;
      throw const AuthException('Witness unavailable', statusCode: 500);
    }
    return status;
  }

  @override
  Future<WitnessStatusModel> unwitnessPost(String id) async {
    unwitnessCalls++;
    return status;
  }
}

void main() {
  testWidgets(
    'renders local posts and loads the next page without duplicates',
    (tester) async {
      final service = FakeFeedService([
        FeedPageModel(
          items: [
            authoredPost('post-1', 'First local post', name: 'Test User'),
          ],
          nextCursor: 'next',
        ),
        FeedPageModel(
          items: [
            authoredPost('post-1', 'First local post', name: 'Test User'),
            authoredPost('post-2', 'Second local post', name: null),
          ],
          nextCursor: null,
        ),
      ]);
      await tester.pumpWidget(
        MaterialApp(home: FeedScreen(feedService: service)),
      );
      await tester.pumpAndSettle();

      expect(find.text('First local post'), findsOneWidget);
      expect(find.text('Test User'), findsOneWidget);
      expect(find.text('private-author-id'), findsNothing);
      final loadMore = find.text('LOAD MORE');
      await tester.tap(loadMore);
      await tester.pumpAndSettle();

      expect(find.text('First local post'), findsOneWidget);
      expect(find.text('Second local post'), findsOneWidget);
      expect(find.text('Khabro User'), findsOneWidget);
      expect(find.text('private-locality-id'), findsNothing);
      expect(find.text('LOAD MORE'), findsNothing);
      expect(service.calls, 2);
    },
  );

  testWidgets('renders the empty state', (tester) async {
    final service = FakeFeedService([
      const FeedPageModel(items: [], nextCursor: null),
    ]);
    await tester.pumpWidget(
      MaterialApp(home: FeedScreen(feedService: service)),
    );
    await tester.pumpAndSettle();
    expect(find.text('No local posts yet.'), findsOneWidget);
    expect(find.text('CREATE POST'), findsOneWidget);
  });

  testWidgets('shows a location state without requesting the feed', (
    tester,
  ) async {
    final service = FakeFeedService([]);
    var updateLocationTapped = false;
    await tester.pumpWidget(
      MaterialApp(
        home: FeedScreen(
          feedService: service,
          localityService: FakeLocalityService(null),
          onUpdateLocation: () => updateLocationTapped = true,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Set your location to see local posts.'), findsOneWidget);
    expect(find.text('UPDATE MY LOCATION'), findsOneWidget);
    expect(service.calls, 0);
    await tester.tap(find.text('UPDATE MY LOCATION'));
    expect(updateLocationTapped, isTrue);
  });

  testWidgets('shows an error and retries cleanly', (tester) async {
    final service = RetryingFeedService();
    await tester.pumpWidget(
      MaterialApp(home: FeedScreen(feedService: service)),
    );
    await tester.pumpAndSettle();

    expect(find.text('Feed unavailable'), findsOneWidget);
    await tester.tap(find.text('RETRY'));
    await tester.pumpAndSettle();
    expect(find.text('Recovered post'), findsOneWidget);
    expect(service.calls, 2);
  });

  testWidgets('creating a post refreshes the feed without duplicating items', (
    tester,
  ) async {
    final feedService = FakeFeedService([
      const FeedPageModel(items: [], nextCursor: null),
      FeedPageModel(
        items: [authoredPost('post-2', 'Created locally', name: 'Test User')],
        nextCursor: null,
      ),
    ]);
    final postsService = FakeCreatePostsService();
    await tester.pumpWidget(
      MaterialApp(
        home: FeedScreen(feedService: feedService, postsService: postsService),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('CREATE POST'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Created locally');
    await tester.pump();
    await tester.tap(find.text('POST'));
    await tester.pumpAndSettle();

    expect(postsService.submittedContent, 'Created locally');
    expect(find.text('Created locally'), findsOneWidget);
    expect(feedService.calls, 2);
  });

  testWidgets('tapping a post opens detail and preserves feed state', (
    tester,
  ) async {
    final service = FakeFeedService([
      FeedPageModel(
        items: [authoredPost('post-1', 'First local post', name: 'Test User')],
        nextCursor: null,
      ),
    ]);
    await tester.pumpWidget(
      MaterialApp(
        home: FeedScreen(
          feedService: service,
          publicUserService: FakePublicUserService(),
          currentUserId: 'private-author-id',
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('First local post'));
    await tester.pumpAndSettle();
    expect(find.text('Hello Khabro!'), findsNothing);
    expect(find.text('First local post'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('First local post'), findsOneWidget);
    expect(service.calls, 1);
  });

  testWidgets('successful delete refreshes feed and removes the post', (
    tester,
  ) async {
    final feedService = FakeFeedService([
      FeedPageModel(
        items: [authoredPost('post-1', 'Delete me', name: 'Test User')],
        nextCursor: null,
      ),
      const FeedPageModel(items: [], nextCursor: null),
    ]);
    final postsService = FakeDeletePostsService();
    await tester.pumpWidget(
      MaterialApp(
        home: FeedScreen(
          feedService: feedService,
          postsService: postsService,
          currentUserId: 'private-author-id',
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete me'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Delete post'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();

    expect(postsService.calls, 1);
    expect(feedService.calls, 2);
    expect(find.text('Delete me'), findsNothing);
    expect(find.text('No local posts yet.'), findsOneWidget);
  });

  testWidgets('like control displays and updates count and state', (
    tester,
  ) async {
    final feedService = FakeFeedService([
      FeedPageModel(
        items: [
          authoredPost(
            'post-1',
            'Like me',
            name: 'Test User',
            likeCount: 0,
            likedByMe: false,
          ),
        ],
        nextCursor: null,
      ),
    ]);
    final postsService = FakeLikePostsService(
      status: const LikeStatusModel(likeCount: 1, likedByMe: true),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: FeedScreen(feedService: feedService, postsService: postsService),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('0'), findsOneWidget);
    expect(find.byTooltip('Like'), findsOneWidget);
    await tester.tap(find.byTooltip('Like'));
    await tester.pumpAndSettle();
    expect(postsService.likeCalls, 1);
    expect(find.text('1'), findsOneWidget);
    expect(find.byTooltip('Unlike'), findsOneWidget);
  });

  testWidgets('rapid like taps do not create duplicate requests', (
    tester,
  ) async {
    final feedService = FakeFeedService([
      FeedPageModel(
        items: [
          authoredPost('post-1', 'Like once', likeCount: 0, likedByMe: false),
        ],
        nextCursor: null,
      ),
    ]);
    final response = Completer<LikeStatusModel>();
    final postsService = FakeLikePostsService(
      status: const LikeStatusModel(likeCount: 1, likedByMe: true),
      likeResponse: response.future,
    );
    await tester.pumpWidget(
      MaterialApp(
        home: FeedScreen(feedService: feedService, postsService: postsService),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Like'));
    await tester.tap(find.byTooltip('Like'));
    expect(postsService.likeCalls, 1);
    response.complete(const LikeStatusModel(likeCount: 1, likedByMe: true));
    await tester.pumpAndSettle();
    expect(postsService.likeCalls, 1);
  });

  testWidgets('witnesses a post and updates count and state', (tester) async {
    final feedService = FakeFeedService([
      FeedPageModel(
        items: [
          authoredPost(
            'post-1',
            'Witness me',
            witnessCount: 0,
            witnessedByMe: false,
          ),
        ],
        nextCursor: null,
      ),
    ]);
    final postsService = FakeWitnessPostsService(
      status: const WitnessStatusModel(witnessCount: 1, witnessedByMe: true),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: FeedScreen(feedService: feedService, postsService: postsService),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Witness 0'), findsOneWidget);
    await tester.tap(find.text('Witness 0'));
    await tester.pumpAndSettle();
    expect(postsService.witnessCalls, 1);
    expect(find.text('Witnessed 1'), findsOneWidget);
  });

  testWidgets('rapid witness taps do not create duplicate requests', (
    tester,
  ) async {
    final response = Completer<WitnessStatusModel>();
    final feedService = FakeFeedService([
      FeedPageModel(
        items: [
          authoredPost('post-1', 'Witness once', witnessCount: 0),
        ],
        nextCursor: null,
      ),
    ]);
    final pendingService = _PendingWitnessPostsService(response);
    await tester.pumpWidget(
      MaterialApp(
        home: FeedScreen(feedService: feedService, postsService: pendingService),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Witness 0'));
    await tester.tap(find.text('Witness 0'));
    expect(pendingService.witnessCalls, 1);
    response.complete(
      const WitnessStatusModel(witnessCount: 1, witnessedByMe: true),
    );
    await tester.pumpAndSettle();
    expect(pendingService.witnessCalls, 1);
  });

  testWidgets('witness errors show safe retry and recover', (tester) async {
    final feedService = FakeFeedService([
      FeedPageModel(
        items: [authoredPost('post-1', 'Retry witness', witnessCount: 0)],
        nextCursor: null,
      ),
    ]);
    final postsService = FakeWitnessPostsService(
      status: const WitnessStatusModel(witnessCount: 1, witnessedByMe: true),
      failOnce: true,
    );
    await tester.pumpWidget(
      MaterialApp(
        home: FeedScreen(feedService: feedService, postsService: postsService),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Witness 0'));
    await tester.pumpAndSettle();
    expect(find.text("Couldn't update witness."), findsOneWidget);
    expect(find.text('RETRY WITNESS'), findsOneWidget);
    await tester.tap(find.text('RETRY WITNESS'));
    await tester.pumpAndSettle();
    expect(postsService.witnessCalls, 2);
    expect(find.text('Witnessed 1'), findsOneWidget);
  });

  testWidgets('feed shows a compact badge only for active verification states', (
    tester,
  ) async {
    final feedService = FakeFeedService([
      FeedPageModel(
        items: [
          authoredPost('post-reported', 'Reported post'),
          authoredPost(
            'post-progress',
            'Verification in progress post',
            verificationStatus: VerificationStatus.underVerification,
          ),
          authoredPost(
            'post-verified',
            'Locally verified post',
            verificationStatus: VerificationStatus.locallyVerified,
          ),
        ],
        nextCursor: null,
      ),
    ]);
    await tester.pumpWidget(
      MaterialApp(home: FeedScreen(feedService: feedService)),
    );
    await tester.pumpAndSettle();

    expect(find.text('Community verification in progress'), findsOneWidget);
    expect(find.text('Locally verified'), findsOneWidget);
    expect(find.text('Reported locally'), findsNothing);
  });
}

class _PendingWitnessPostsService extends PostsService {
  _PendingWitnessPostsService(this.response)
    : super(apiClient: null, tokenStorage: null);

  final Completer<WitnessStatusModel> response;
  var witnessCalls = 0;

  @override
  Future<WitnessStatusModel> witnessPost(String id) {
    witnessCalls++;
    return response.future;
  }
}
