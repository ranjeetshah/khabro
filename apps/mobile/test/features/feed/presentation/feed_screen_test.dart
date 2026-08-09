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
import 'package:mobile/features/users/data/public_user_model.dart';

PostModel post(String id, String content) => PostModel(
  id: id,
  authorId: 'user-1',
  localityId: 'locality-a',
  content: content,
  createdAt: DateTime.parse('2026-08-09T08:00:00.000Z'),
  updatedAt: DateTime.parse('2026-08-09T08:00:01.000Z'),
);

PostModel authoredPost(String id, String content, {String? name}) => PostModel(
  id: id,
  authorId: 'private-author-id',
  localityId: 'private-locality-id',
  content: content,
  createdAt: DateTime.parse('2026-08-09T08:00:00.000Z'),
  updatedAt: DateTime.parse('2026-08-09T08:00:01.000Z'),
  author: PublicUserModel(id: 'private-author-id', name: name),
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
  FakeLocalityService(this.locality) : super(apiClient: null, tokenStorage: null);

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

void main() {
  testWidgets('renders local posts and loads the next page without duplicates', (tester) async {
    final service = FakeFeedService([
      FeedPageModel(items: [authoredPost('post-1', 'First local post', name: 'Test User')], nextCursor: 'next'),
      FeedPageModel(items: [authoredPost('post-1', 'First local post', name: 'Test User'), authoredPost('post-2', 'Second local post', name: null)], nextCursor: null),
    ]);
    await tester.pumpWidget(MaterialApp(home: FeedScreen(feedService: service)));
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
  });

  testWidgets('renders the empty state', (tester) async {
    final service = FakeFeedService([
      const FeedPageModel(items: [], nextCursor: null),
    ]);
    await tester.pumpWidget(MaterialApp(home: FeedScreen(feedService: service)));
    await tester.pumpAndSettle();
    expect(find.text('No local posts yet.'), findsOneWidget);
    expect(find.text('CREATE POST'), findsOneWidget);
  });

  testWidgets('shows a location state without requesting the feed', (tester) async {
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
    await tester.pumpWidget(MaterialApp(home: FeedScreen(feedService: service)));
    await tester.pumpAndSettle();

    expect(find.text('Feed unavailable'), findsOneWidget);
    await tester.tap(find.text('RETRY'));
    await tester.pumpAndSettle();
    expect(find.text('Recovered post'), findsOneWidget);
    expect(service.calls, 2);
  });

  testWidgets('creating a post refreshes the feed without duplicating items', (tester) async {
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
        home: FeedScreen(
          feedService: feedService,
          postsService: postsService,
        ),
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
}
