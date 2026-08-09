import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart' as http_testing;
import 'package:mobile/core/network/api_client.dart';
import 'package:mobile/core/storage/token_storage.dart';
import 'package:mobile/features/auth/data/auth_exception.dart';
import 'package:mobile/features/feed/data/feed_service.dart';

class FakeTokenStorage extends TokenStorage {
  FakeTokenStorage([this.token]) : super(storage: null);
  String? token;

  @override
  Future<String?> getAccessToken() async => token;
}

const pageJson = {
  'items': [
    {
      'id': 'post-1',
      'authorId': 'user-1',
      'localityId': 'locality-a',
      'content': 'Local post',
      'createdAt': '2026-08-09T08:00:00.000Z',
      'updatedAt': '2026-08-09T08:00:01.000Z',
    },
  ],
  'nextCursor': 'cursor value',
};

FeedService serviceFor(
  FakeTokenStorage storage,
  http_testing.MockClientHandler handler,
) => FeedService(
  tokenStorage: storage,
  apiClient: ApiClient(httpClient: http_testing.MockClient(handler)),
);

void main() {
  test('loads the first page with a bearer token', () async {
    final service = serviceFor(FakeTokenStorage('jwt'), (request) async {
      expect(request.url.path, '/feed');
      expect(request.url.queryParameters['limit'], '20');
      expect(request.headers['Authorization'], 'Bearer jwt');
      return http.Response(jsonEncode(pageJson), 200);
    });

    final page = await service.getFeed(limit: 20);
    expect(page.items.single.id, 'post-1');
  });

  test('sends cursor for the next page', () async {
    final service = serviceFor(FakeTokenStorage('jwt'), (request) async {
      expect(request.url.queryParameters['cursor'], 'cursor value');
      return http.Response('{"items":[],"nextCursor":null}', 200);
    });
    expect((await service.getFeed(cursor: 'cursor value')).items, isEmpty);
  });

  test('handles missing token, 401, and server errors', () async {
    final missing = serviceFor(FakeTokenStorage(), (request) async {
      fail('request should not be made');
    });
    expect(() => missing.getFeed(), throwsA(isA<AuthException>()));

    final expired = serviceFor(FakeTokenStorage('jwt'), (request) async {
      return http.Response('{"message":"Unauthorized"}', 401);
    });
    expect(
      () => expired.getFeed(),
      throwsA(isA<AuthException>().having((e) => e.statusCode, 'status', 401)),
    );

    final failed = serviceFor(FakeTokenStorage('jwt'), (request) async {
      return http.Response('{"message":"Feed unavailable"}', 500);
    });
    expect(
      () => failed.getFeed(),
      throwsA(isA<AuthException>().having((e) => e.message, 'message', 'Feed unavailable')),
    );
  });
}
