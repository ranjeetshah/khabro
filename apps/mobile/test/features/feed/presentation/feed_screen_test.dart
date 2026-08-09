import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/feed/data/feed_page_model.dart';
import 'package:mobile/features/feed/data/feed_service.dart';
import 'package:mobile/features/feed/presentation/feed_screen.dart';
import 'package:mobile/features/posts/data/post_model.dart';
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
  });
}
