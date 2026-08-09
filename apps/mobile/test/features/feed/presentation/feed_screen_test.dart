import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/feed/data/feed_page_model.dart';
import 'package:mobile/features/feed/data/feed_service.dart';
import 'package:mobile/features/feed/presentation/feed_screen.dart';
import 'package:mobile/features/posts/data/post_model.dart';

PostModel post(String id, String content) => PostModel(
  id: id,
  authorId: 'user-1',
  localityId: 'locality-a',
  content: content,
  createdAt: DateTime.parse('2026-08-09T08:00:00.000Z'),
  updatedAt: DateTime.parse('2026-08-09T08:00:01.000Z'),
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
      FeedPageModel(items: [post('post-1', 'First local post')], nextCursor: 'next'),
      FeedPageModel(items: [post('post-1', 'First local post'), post('post-2', 'Second local post')], nextCursor: null),
    ]);
    await tester.pumpWidget(MaterialApp(home: FeedScreen(feedService: service)));
    await tester.pumpAndSettle();

    expect(find.text('First local post'), findsOneWidget);
    final loadMore = find.text('LOAD MORE');
    await tester.tap(loadMore);
    await tester.pumpAndSettle();

    expect(find.text('First local post'), findsOneWidget);
    expect(find.text('Second local post'), findsOneWidget);
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
