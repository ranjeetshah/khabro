import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart' as http_testing;
import 'package:mobile/core/network/api_client.dart';
import 'package:mobile/core/storage/token_storage.dart';
import 'package:mobile/features/auth/data/auth_exception.dart';
import 'package:mobile/features/posts/data/posts_service.dart';

class FakeTokenStorage extends TokenStorage {
  FakeTokenStorage([this.token]) : super(storage: null);
  String? token;

  @override
  Future<String?> getAccessToken() async => token;
}

const postJson = {
  'id': 'post-1',
  'authorId': 'user-1',
  'localityId': 'development-locality-a',
  'content': 'Hello Khabro!',
  'createdAt': '2026-08-09T08:00:00.000Z',
  'updatedAt': '2026-08-09T08:00:01.000Z',
};

PostsService serviceFor(
  FakeTokenStorage storage,
  http_testing.MockClientHandler handler,
) => PostsService(
  tokenStorage: storage,
  apiClient: ApiClient(httpClient: http_testing.MockClient(handler)),
);

void main() {
  test('createPost sends content and parses response', () async {
    final service = serviceFor(FakeTokenStorage('jwt'), (request) async {
      expect(request.method, 'POST');
      expect(request.url.path, '/posts');
      expect(request.headers['Authorization'], 'Bearer jwt');
      expect(jsonDecode(request.body), {'content': 'Hello'});
      return http.Response(jsonEncode({'post': postJson}), 201);
    });

    final post = await service.createPost('Hello');
    expect(post.id, 'post-1');
  });

  test('getMyPosts parses list', () async {
    final service = serviceFor(FakeTokenStorage('jwt'), (request) async {
      expect(request.url.path, '/posts/me');
      return http.Response(
        jsonEncode({
          'posts': [postJson],
        }),
        200,
      );
    });
    expect((await service.getMyPosts()).single.content, 'Hello Khabro!');
  });

  test('getPost parses a post', () async {
    final service = serviceFor(FakeTokenStorage('jwt'), (request) async {
      expect(request.url.path, '/posts/post-1');
      return http.Response(jsonEncode({'post': postJson}), 200);
    });
    expect((await service.getPost('post-1')).id, 'post-1');
  });

  test('deletePost sends authenticated delete', () async {
    final service = serviceFor(FakeTokenStorage('jwt'), (request) async {
      expect(request.method, 'DELETE');
      expect(request.url.path, '/posts/post-1');
      return http.Response('{}', 200);
    });
    await service.deletePost('post-1');
  });

  test(
    'like and unlike use authenticated endpoints and parse metadata',
    () async {
      var call = 0;
      final service = serviceFor(FakeTokenStorage('jwt'), (request) async {
        call++;
        expect(request.headers['Authorization'], 'Bearer jwt');
        if (call == 1) {
          expect(request.method, 'POST');
          expect(request.url.path, '/posts/post-1/like');
          return http.Response(
            '{"like":{"likeCount":1,"likedByMe":true}}',
            200,
          );
        }
        expect(request.method, 'DELETE');
        expect(request.url.path, '/posts/post-1/like');
        return http.Response('{"like":{"likeCount":0,"likedByMe":false}}', 200);
      });
      expect((await service.likePost('post-1')).likedByMe, isTrue);
      expect((await service.unlikePost('post-1')).likeCount, 0);
    },
  );

  test('like errors preserve status for safe UI handling', () async {
    final service = serviceFor(FakeTokenStorage('jwt'), (request) async {
      return http.Response('{"message":"Conflict"}', 409);
    });
    expect(
      () => service.likePost('post-1'),
      throwsA(isA<AuthException>().having((e) => e.statusCode, 'status', 409)),
    );
  });

  test('witness APIs use authenticated endpoints and parse metadata', () async {
    var call = 0;
    final service = serviceFor(FakeTokenStorage('jwt'), (request) async {
      call++;
      expect(request.headers['Authorization'], 'Bearer jwt');
      if (call == 1) {
        expect(request.method, 'POST');
        expect(request.url.path, '/posts/post-1/witness');
        return http.Response(
          '{"witness":{"witnessCount":1,"witnessedByMe":true}}',
          201,
        );
      }
      if (call == 2) {
        expect(request.method, 'DELETE');
        expect(request.url.path, '/posts/post-1/witness');
        return http.Response(
          '{"witness":{"witnessCount":0,"witnessedByMe":false}}',
          200,
        );
      }
      expect(request.method, 'GET');
      expect(request.url.path, '/posts/post-1/witnesses');
      return http.Response(
        '{"witness":{"witnessCount":2,"witnessedByMe":false}}',
        200,
      );
    });
    expect((await service.witnessPost('post-1')).witnessedByMe, isTrue);
    expect((await service.unwitnessPost('post-1')).witnessCount, 0);
    expect((await service.getWitnessStatus('post-1')).witnessCount, 2);
  });

  test('witness errors preserve status', () async {
    final service = serviceFor(FakeTokenStorage('jwt'), (request) async {
      return http.Response('{"message":"Not found"}', 404);
    });
    expect(
      () => service.witnessPost('post-1'),
      throwsA(isA<AuthException>().having((e) => e.statusCode, 'status', 404)),
    );
  });

  test('getVerificationStatus parses safe verification metadata', () async {
    final service = serviceFor(FakeTokenStorage('jwt'), (request) async {
      expect(request.method, 'GET');
      expect(request.url.path, '/posts/post-1/verification');
      expect(request.headers['Authorization'], 'Bearer jwt');
      return http.Response(
        '{"status":"LOCALLY_VERIFIED","witnessCount":2}',
        200,
      );
    });

    final status = await service.getVerificationStatus('post-1');
    expect(status.status.isLocallyVerified, isTrue);
    expect(status.witnessCount, 2);
  });

  test('getVerificationStatus tolerates unknown future statuses', () async {
    final service = serviceFor(FakeTokenStorage('jwt'), (request) async {
      return http.Response('{"status":"AUTHORITY_CONFIRMED","witnessCount":5}', 200);
    });

    final status = await service.getVerificationStatus('post-1');
    expect(status.status.isUnknown, isTrue);
    expect(status.status.isLocallyVerified, isFalse);
    expect(status.witnessCount, 5);
  });

  test('getVerificationHistory uses the authenticated history endpoint', () async {
    final service = serviceFor(FakeTokenStorage('jwt'), (request) async {
      expect(request.method, 'GET');
      expect(request.url.path, '/posts/post-1/verification/history');
      expect(request.headers['Authorization'], 'Bearer jwt');
      return http.Response(
        '{"events":[{"type":"POST_CREATED","toStatus":"REPORTED",'
        '"createdAt":"2026-08-09T08:00:00.000Z"},'
        '{"type":"STATUS_CHANGED","fromStatus":"REPORTED",'
        '"toStatus":"UNDER_VERIFICATION",'
        '"createdAt":"2026-08-09T09:00:00.000Z"}]}',
        200,
      );
    });

    final history = await service.getVerificationHistory('post-1');
    expect(history.events, hasLength(2));
    expect(history.events.first.type.isPostCreated, isTrue);
    expect(history.events.first.toStatus?.isReported, isTrue);
    expect(history.events.first.fromStatus, isNull);
    expect(history.events.last.type.isStatusChanged, isTrue);
    expect(history.events.last.fromStatus?.isReported, isTrue);
    expect(history.events.last.toStatus?.isUnderVerification, isTrue);
  });

  test('getVerificationHistory parses an empty history', () async {
    final service = serviceFor(FakeTokenStorage('jwt'), (request) async {
      return http.Response('{"events":[]}', 200);
    });

    final history = await service.getVerificationHistory('post-1');
    expect(history.events, isEmpty);
  });

  test('getVerificationHistory tolerates unknown future event types', () async {
    final service = serviceFor(FakeTokenStorage('jwt'), (request) async {
      return http.Response(
        '{"events":[{"type":"AUTHORITY_REVIEWED",'
        '"createdAt":"2026-08-09T08:00:00.000Z"}]}',
        200,
      );
    });

    final history = await service.getVerificationHistory('post-1');
    expect(history.events.single.type.isUnknown, isTrue);
  });

  test('getVerificationHistory never exposes witness identity fields', () async {
    final service = serviceFor(FakeTokenStorage('jwt'), (request) async {
      return http.Response(
        '{"events":[{"type":"WITNESS_ADDED",'
        '"createdAt":"2026-08-09T08:00:00.000Z"}]}',
        200,
      );
    });

    final history = await service.getVerificationHistory('post-1');
    final event = history.events.single;
    expect(event.type.isWitnessAdded, isTrue);
    expect(history.events.single.toMap().keys.any((key) =>
        key.contains('userId') || key.contains('phone')), isFalse);
  });

  test('getVerificationHistory errors preserve status', () async {
    final service = serviceFor(FakeTokenStorage('jwt'), (request) async {
      return http.Response('{"message":"Not found"}', 404);
    });
    expect(
      () => service.getVerificationHistory('post-1'),
      throwsA(isA<AuthException>().having((e) => e.statusCode, 'status', 404)),
    );
  });

  test('witness responses expose no private witness rows', () async {
    final service = serviceFor(FakeTokenStorage('jwt'), (request) async {
      return http.Response(
        '{"witness":{"witnessCount":2,"witnessedByMe":false,'
        '"verification":{"status":"LOCALLY_VERIFIED","witnessCount":2}}}',
        200,
      );
    });

    final status = await service.getWitnessStatus('post-1');
    expect(status.witnessCount, 2);
    expect(status.witnessedByMe, isFalse);
    expect(status.verification?.status.isLocallyVerified, isTrue);
  });

  test('missing token and 401 are handled', () async {
    final missing = serviceFor(FakeTokenStorage(), (request) async {
      fail('request should not run');
    });
    expect(() => missing.getMyPosts(), throwsA(isA<AuthException>()));

    final expired = serviceFor(FakeTokenStorage('expired'), (request) async {
      return http.Response('{"message":"Unauthorized"}', 401);
    });
    expect(
      () => expired.getMyPosts(),
      throwsA(isA<AuthException>().having((e) => e.statusCode, 'status', 401)),
    );
  });

  test('server errors preserve the backend message', () async {
    final service = serviceFor(FakeTokenStorage('jwt'), (request) async {
      return http.Response('{"message":"Database unavailable"}', 500);
    });
    expect(
      () => service.getMyPosts(),
      throwsA(
        isA<AuthException>().having(
          (e) => e.message,
          'message',
          'Database unavailable',
        ),
      ),
    );
  });
}
