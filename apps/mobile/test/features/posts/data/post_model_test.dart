import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/posts/data/post_model.dart';
import 'package:mobile/features/posts/data/verification_status.dart';

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

  test('parses witness count and current-user state', () {
    final post = PostModel.fromJson({
      ...postJson,
      'witnessCount': 3,
      'witnessedByMe': true,
    });
    expect(post.witnessCount, 3);
    expect(post.witnessedByMe, isTrue);
    expect(post.toJson()['witnessCount'], 3);
    expect(post.toJson()['witnessedByMe'], isTrue);
  });

  test('defaults to REPORTED when verification status is absent', () {
    final post = PostModel.fromJson(postJson);
    expect(post.verificationStatus, VerificationStatus.reported);
    expect(post.toJson().containsKey('verificationStatus'), isFalse);
  });

  test('parses known verification statuses', () {
    final under = PostModel.fromJson({
      ...postJson,
      'verificationStatus': 'UNDER_VERIFICATION',
    });
    expect(under.verificationStatus, VerificationStatus.underVerification);
    expect(under.toJson()['verificationStatus'], 'UNDER_VERIFICATION');

    final verified = PostModel.fromJson({
      ...postJson,
      'verificationStatus': 'LOCALLY_VERIFIED',
    });
    expect(verified.verificationStatus, VerificationStatus.locallyVerified);
    expect(verified.toJson()['verificationStatus'], 'LOCALLY_VERIFIED');
  });

  test('unknown future verification statuses never crash parsing', () {
    final post = PostModel.fromJson({
      ...postJson,
      'verificationStatus': 'AUTHORITY_CONFIRMED',
    });
    expect(post.verificationStatus, VerificationStatus.reported);
    expect(post.verificationStatus.isUnknown, isFalse);
  });

  test('copyWith preserves and overrides verification status', () {
    final post = PostModel.fromJson({
      ...postJson,
      'verificationStatus': 'UNDER_VERIFICATION',
    });
    final promoted = post.copyWith(
      verificationStatus: VerificationStatus.locallyVerified,
    );
    expect(promoted.verificationStatus, VerificationStatus.locallyVerified);
    expect(post.verificationStatus, VerificationStatus.underVerification);
  });
}
