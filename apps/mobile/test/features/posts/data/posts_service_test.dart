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
