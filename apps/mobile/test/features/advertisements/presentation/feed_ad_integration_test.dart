import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/advertisements/data/advertisement_model.dart';
import 'package:mobile/features/advertisements/data/advertisement_service.dart';
import 'package:mobile/features/feed/data/feed_page_model.dart';
import 'package:mobile/features/feed/data/feed_service.dart';
import 'package:mobile/features/feed/presentation/feed_screen.dart';
import 'package:mobile/features/posts/data/post_model.dart';
import 'package:mobile/features/users/data/public_user_model.dart';

AdvertisementModel _atAd() => AdvertisementModel(
  id: 'at-ad-1',
  title: 'Tap-Tap Ad',
  advertiserName: 'Sponsor',
  creativeUrl: '',
  destinationUrl: 'https://example.com',
  placement: AdvertisementPlacement.feed,
  status: AdvertisementStatus.active,
  createdAt: DateTime.utc(2026, 8, 1),
  updatedAt: DateTime.utc(2026, 8, 1),
);

class FakeFeedService extends FeedService {
  FakeFeedService(this.pages) : super(apiClient: null, tokenStorage: null);

  final List<FeedPageModel> pages;
  int calls = 0;

  @override
  Future<FeedPageModel> getFeed({String? cursor, int? limit}) async {
    calls++;
    final index = cursor == null ? 0 : 1;
    return pages[index];
  }
}

class FakeAdvertisementService extends AdvertisementService {
  FakeAdvertisementService() : super(apiClient: null, tokenStorage: null);

  bool throwError = false;
  AdvertisementModel? ad;
  int impressionCalls = 0;
  int clickCalls = 0;

  @override
  Future<AdvertisementPageModel> getAdvertisements({
    required AdvertisementPlacement placement,
    int page = 1,
    int limit = 5,
  }) async {
    if (throwError) {
      throw Exception('ad fetch failed');
    }
    return AdvertisementPageModel(
      items: ad == null ? const [] : [ad!],
      page: 1,
      limit: limit,
      total: ad == null ? 0 : 1,
      hasMore: false,
    );
  }

  @override
  Future<void> recordImpression(String id) async {
    impressionCalls++;
  }

  @override
  Future<void> recordClick(String id) async {
    clickCalls++;
  }
}

PostModel _post(String id, String content) => PostModel(
  id: id,
  authorId: 'user-1',
  localityId: 'locality-a',
  content: content,
  createdAt: DateTime.parse('2026-08-09T08:00:00.000Z'),
  updatedAt: DateTime.parse('2026-08-09T08:00:01.000Z'),
  author: PublicUserModel(id: 'user-1', name: 'Jane'),
);

void main() {
  testWidgets('shows an ad card in the feed without blocking posts', (
    tester,
  ) async {
    final feed = FakeFeedService([
      FeedPageModel(
        items: [_post('post-1', 'A local post')],
        nextCursor: null,
      ),
    ]);
    final ads = FakeAdvertisementService()
      ..ad = _atAd();
    await tester.pumpWidget(
      MaterialApp(
        home: FeedScreen(
          feedService: feed,
          advertisementService: ads,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('A local post'), findsOneWidget);
    expect(find.text('Tap-Tap Ad'), findsOneWidget);
    expect(find.text('Sponsored'), findsOneWidget);
    expect(ads.impressionCalls, 1);
  });

  testWidgets('hides the ad when the fetch fails and keeps the feed usable', (
    tester,
  ) async {
    final feed = FakeFeedService([
      FeedPageModel(items: [_post('post-1', 'A local post')], nextCursor: null),
    ]);
    final ads = FakeAdvertisementService()..throwError = true;
    await tester.pumpWidget(
      MaterialApp(
        home: FeedScreen(
          feedService: feed,
          advertisementService: ads,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('A local post'), findsOneWidget);
    expect(find.text('Sponsored'), findsNothing);
  });
}
