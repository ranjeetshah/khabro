import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/feed/data/feed_page_model.dart';

const feedJson = {
  'items': [
    {
      'id': 'post-1',
      'authorId': 'user-1',
      'localityId': 'locality-a',
      'content': 'Local post',
      'createdAt': '2026-08-09T08:00:00.000Z',
      'updatedAt': '2026-08-09T08:00:01.000Z',
      'author': {
        'id': 'user-1',
        'name': 'Test User',
        'followerCount': 0,
        'followingCount': 0,
      },
    },
  ],
  'nextCursor': 'cursor-1',
};

void main() {
  test('parses a page with posts and cursor', () {
    final page = FeedPageModel.fromJson(feedJson);
    expect(page.items.single.content, 'Local post');
    expect(page.nextCursor, 'cursor-1');
    expect(page.toJson(), feedJson);
  });

  test('parses an empty page', () {
    final page = FeedPageModel.fromJson({'items': [], 'nextCursor': null});
    expect(page.items, isEmpty);
    expect(page.nextCursor, isNull);
  });
}
