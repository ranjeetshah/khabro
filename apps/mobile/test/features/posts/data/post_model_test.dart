import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/posts/data/post_model.dart';

const postJson = {
  'id': 'post-1',
  'authorId': 'user-1',
  'localityId': 'development-locality-a',
  'content': 'Hello Khabro!',
  'createdAt': '2026-08-09T08:00:00.000Z',
  'updatedAt': '2026-08-09T08:00:01.000Z',
};

void main() {
  test('parses and serializes a post', () {
    final post = PostModel.fromJson(postJson);
    expect(post.content, 'Hello Khabro!');
    expect(post.localityId, 'development-locality-a');
    expect(post.toJson(), postJson);
  });

  test('supports a post without locality', () {
    final post = PostModel.fromJson({...postJson, 'localityId': null});
    expect(post.localityId, isNull);
  });

  test(
    'parses an optional public author and remains compatible without one',
    () {
      final post = PostModel.fromJson({
        ...postJson,
        'author': {'id': 'user-1', 'name': 'Test User'},
      });
      expect(post.author?.name, 'Test User');
      expect(PostModel.fromJson(postJson).author, isNull);
    },
  );

  test('parses like count and current-user state', () {
    final post = PostModel.fromJson({
      ...postJson,
      'likeCount': 12,
      'likedByMe': true,
    });
    expect(post.likeCount, 12);
    expect(post.likedByMe, isTrue);
    expect(post.toJson()['likeCount'], 12);
    expect(post.toJson()['likedByMe'], isTrue);
  });
}
