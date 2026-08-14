import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart' as http_testing;
import 'package:mobile/core/network/api_client.dart';
import 'package:mobile/core/storage/token_storage.dart';
import 'package:mobile/features/advertisements/data/advertisement_model.dart';
import 'package:mobile/features/advertisements/data/advertisement_service.dart';
import 'package:mobile/features/auth/data/auth_exception.dart';

class FakeTokenStorage extends TokenStorage {
  FakeTokenStorage([this.token]) : super(storage: null);
  String? token;

  @override
  Future<String?> getAccessToken() async => token;
}

AdvertisementService serviceFor(
  FakeTokenStorage storage,
  http_testing.MockClientHandler handler,
) => AdvertisementService(
  tokenStorage: storage,
  apiClient: ApiClient(httpClient: http_testing.MockClient(handler)),
);

Map<String, dynamic> _adJson([Map<String, dynamic>? overrides]) => {
  'id': 'ad-1',
  'title': 'Clean Water Drive',
  'description': 'Join us.',
  'advertiserName': 'CityWorks',
  'creativeUrl': 'https://cdn.example.com/ad.png',
  'destinationUrl': 'https://cityworks.example.com',
  'ctaLabel': 'Donate',
  'placement': 'FEED',
  'status': 'ACTIVE',
  'impressionCount': 10,
  'clickCount': 1,
  'createdAt': '2026-08-01T00:00:00.000Z',
  'updatedAt': '2026-08-01T00:00:00.000Z',
  ...?overrides,
};

void main() {
  test('getAdvertisements sends placement, page and limit query params', () async {
    final service = serviceFor(FakeTokenStorage('jwt'), (request) async {
      expect(request.method, 'GET');
      expect(request.url.path, '/advertisements');
      expect(request.headers['Authorization'], 'Bearer jwt');
      expect(request.url.queryParameters['placement'], 'FEED');
      expect(request.url.queryParameters['page'], '1');
      expect(request.url.queryParameters['limit'], '5');
      return http.Response(
        jsonEncode({
          'items': [_adJson()],
          'page': 1,
          'limit': 5,
          'total': 1,
          'hasMore': false,
        }),
        200,
      );
    });

    final page = await service.getAdvertisements(
      placement: AdvertisementPlacement.feed,
    );
    expect(page.items, hasLength(1));
    expect(page.items.first.id, 'ad-1');
    expect(page.total, 1);
    expect(page.hasMore, isFalse);
  });

  test('getAdvertisements throws AuthException when not authenticated', () async {
    final service = serviceFor(FakeTokenStorage(null), (request) async {
      return http.Response('{}', 200);
    });

    expect(
      () => service.getAdvertisements(
        placement: AdvertisementPlacement.feed,
      ),
      throwsA(
        isA<AuthException>()
            .having((e) => e.statusCode, 'statusCode', 401),
      ),
    );
  });

  test('getAdvertisements surfaces a 401 as session expired', () async {
    final service = serviceFor(FakeTokenStorage('jwt'), (request) async {
      return http.Response('{"message":"Unauthorized"}', 401);
    });

    expect(
      () => service.getAdvertisements(
        placement: AdvertisementPlacement.feed,
      ),
      throwsA(
        isA<AuthException>()
            .having((e) => e.message, 'message', contains('Session expired')),
      ),
    );
  });

  test('recordImpression posts to the impression endpoint', () async {
    final service = serviceFor(FakeTokenStorage('jwt'), (request) async {
      expect(request.method, 'POST');
      expect(request.url.path, '/advertisements/ad-1/impression');
      expect(request.headers['Authorization'], 'Bearer jwt');
      return http.Response('{}', 204);
    });

    await service.recordImpression('ad-1');
  });

  test('recordClick posts to the click endpoint', () async {
    final service = serviceFor(FakeTokenStorage('jwt'), (request) async {
      expect(request.method, 'POST');
      expect(request.url.path, '/advertisements/ad-1/click');
      expect(request.headers['Authorization'], 'Bearer jwt');
      return http.Response('{}', 204);
    });

    await service.recordClick('ad-1');
  });

  test('getModeratorAdvertisements sends filters', () async {
    final service = serviceFor(FakeTokenStorage('jwt'), (request) async {
      expect(request.url.path, '/moderator/advertisements');
      expect(request.url.queryParameters['status'], 'ACTIVE');
      expect(request.url.queryParameters['placement'], 'FEED');
      expect(request.url.queryParameters['limit'], '20');
      return http.Response(
        jsonEncode({
          'items': [_adJson()],
          'page': 1,
          'limit': 20,
          'total': 1,
          'hasMore': false,
        }),
        200,
      );
    });

    final page = await service.getModeratorAdvertisements(
      status: 'ACTIVE',
      placement: 'FEED',
    );
    expect(page.items, hasLength(1));
  });

  test('getModeratorAdvertisementDetail parses a single ad', () async {
    final service = serviceFor(FakeTokenStorage('jwt'), (request) async {
      expect(request.url.path, '/moderator/advertisements/ad-1');
      return http.Response(jsonEncode(_adJson()), 200);
    });

    final ad = await service.getModeratorAdvertisementDetail('ad-1');
    expect(ad.id, 'ad-1');
    expect(ad.status, AdvertisementStatus.active);
  });

  test('createAdvertisement posts the payload', () async {
    final service = serviceFor(FakeTokenStorage('jwt'), (request) async {
      expect(request.method, 'POST');
      expect(request.url.path, '/moderator/advertisements');
      expect(
        (jsonDecode(request.body) as Map<String, dynamic>)['placement'],
        'FEED',
      );
      return http.Response(jsonEncode(_adJson()), 201);
    });

    final ad = await service.createAdvertisement({'placement': 'FEED'});
    expect(ad.id, 'ad-1');
  });

  test('updateAdvertisement patches the payload', () async {
    final service = serviceFor(FakeTokenStorage('jwt'), (request) async {
      expect(request.method, 'PATCH');
      expect(request.url.path, '/moderator/advertisements/ad-1');
      expect(
        (jsonDecode(request.body) as Map<String, dynamic>)['title'],
        'New title',
      );
      return http.Response(jsonEncode(_adJson({'title': 'New title'})), 200);
    });

    final ad = await service.updateAdvertisement('ad-1', {'title': 'New title'});
    expect(ad.title, 'New title');
  });

  test('activate and pause hit the lifecycle endpoints', () async {
    final activated = serviceFor(FakeTokenStorage('jwt'), (request) async {
      expect(request.method, 'POST');
      expect(request.url.path, '/moderator/advertisements/ad-1/activate');
      return http.Response(jsonEncode(_adJson({'status': 'ACTIVE'})), 200);
    });
    final active = await activated.activateAdvertisement('ad-1');
    expect(active.status, AdvertisementStatus.active);

    final paused = serviceFor(FakeTokenStorage('jwt'), (request) async {
      expect(request.method, 'POST');
      expect(request.url.path, '/moderator/advertisements/ad-1/pause');
      return http.Response(jsonEncode(_adJson({'status': 'PAUSED'})), 200);
    });
    final result = await paused.pauseAdvertisement('ad-1');
    expect(result.status, AdvertisementStatus.paused);
  });

  test('cancelAdvertisement deletes the ad', () async {
    final service = serviceFor(FakeTokenStorage('jwt'), (request) async {
      expect(request.method, 'DELETE');
      expect(request.url.path, '/moderator/advertisements/ad-1');
      return http.Response('{}', 204);
    });

    await service.cancelAdvertisement('ad-1');
  });

  test('surfaces backend error message on non-2xx response', () async {
    final service = serviceFor(FakeTokenStorage('jwt'), (request) async {
      return http.Response(
        '{"message":["Only DRAFT or PAUSED advertisements can be updated."]}',
        400,
      );
    });

    expect(
      () => service.updateAdvertisement('ad-1', {'title': 'x'}),
      throwsA(
        isA<AuthException>().having(
          (e) => e.message,
          'message',
          'Only DRAFT or PAUSED advertisements can be updated.',
        ),
      ),
    );
  });
}