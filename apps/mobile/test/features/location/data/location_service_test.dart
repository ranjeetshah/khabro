import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart' as http_testing;
import 'package:mobile/core/network/api_client.dart';
import 'package:mobile/core/storage/token_storage.dart';
import 'package:mobile/features/auth/data/auth_exception.dart';
import 'package:mobile/features/location/data/location_model.dart';
import 'package:mobile/features/location/data/location_service.dart';

class FakeTokenStorage extends TokenStorage {
  FakeTokenStorage([this.token]) : super(storage: null);

  String? token;

  @override
  Future<String?> getAccessToken() async => token;
}

const locationJson = {
  'id': 'location-123',
  'latitude': 28.7041,
  'longitude': 77.1025,
  'accuracyMeters': 25,
  'capturedAt': '2026-08-09T08:00:00.000Z',
  'createdAt': '2026-08-09T08:00:01.000Z',
  'updatedAt': '2026-08-09T08:00:02.000Z',
};

LocationService serviceFor(
  FakeTokenStorage storage,
  http_testing.MockClientHandler handler,
) {
  return LocationService(
    tokenStorage: storage,
    apiClient: ApiClient(httpClient: http_testing.MockClient(handler)),
  );
}

void main() {
  group('LocationService', () {
    test('getMyLocation success sends bearer token', () async {
      final service = serviceFor(FakeTokenStorage('jwt-value'), (
        request,
      ) async {
        expect(request.method, 'GET');
        expect(request.url.path, '/location/me');
        expect(request.headers['Authorization'], 'Bearer jwt-value');
        return http.Response(jsonEncode({'location': locationJson}), 200);
      });

      final location = await service.getMyLocation();

      expect(location, isA<LocationModel>());
      expect(location!.latitude, 28.7041);
    });

    test('getMyLocation returns null when no location exists', () async {
      final service = serviceFor(FakeTokenStorage('jwt-value'), (
        request,
      ) async {
        return http.Response(jsonEncode({'location': null}), 200);
      });

      expect(await service.getMyLocation(), isNull);
    });

    test('updateMyLocation success sends location payload', () async {
      final capturedAt = DateTime.parse('2026-08-09T08:00:00.000Z');
      final service = serviceFor(FakeTokenStorage('jwt-value'), (
        request,
      ) async {
        expect(request.method, 'PUT');
        expect(request.url.path, '/location/me');
        expect(request.headers['Authorization'], 'Bearer jwt-value');
        expect(jsonDecode(request.body), {
          'latitude': 28.7041,
          'longitude': 77.1025,
          'accuracyMeters': 25.0,
          'capturedAt': capturedAt.toIso8601String(),
        });
        return http.Response(jsonEncode({'location': locationJson}), 200);
      });

      final location = await service.updateMyLocation(
        latitude: 28.7041,
        longitude: 77.1025,
        accuracyMeters: 25,
        capturedAt: capturedAt,
      );

      expect(location.id, 'location-123');
    });

    test('missing token throws 401 without making a request', () async {
      final service = serviceFor(FakeTokenStorage(null), (request) async {
        fail('No request should be made without a token');
      });

      expect(
        () => service.getMyLocation(),
        throwsA(
          isA<AuthException>().having((e) => e.statusCode, 'status', 401),
        ),
      );
    });

    test('401 throws an authentication error', () async {
      final service = serviceFor(FakeTokenStorage('expired'), (request) async {
        return http.Response(jsonEncode({'message': 'Unauthorized'}), 401);
      });

      expect(
        () => service.getMyLocation(),
        throwsA(
          isA<AuthException>().having((e) => e.statusCode, 'status', 401),
        ),
      );
    });

    test('validation error preserves backend message', () async {
      final service = serviceFor(FakeTokenStorage('jwt-value'), (
        request,
      ) async {
        return http.Response(
          jsonEncode({
            'message': ['latitude must not be less than -90'],
          }),
          400,
        );
      });

      expect(
        () => service.updateMyLocation(
          latitude: 100,
          longitude: 77,
          capturedAt: DateTime.parse('2026-08-09T08:00:00.000Z'),
        ),
        throwsA(
          isA<AuthException>().having(
            (e) => e.message,
            'message',
            'latitude must not be less than -90',
          ),
        ),
      );
    });

    test('server error throws an AuthException with status code', () async {
      final service = serviceFor(FakeTokenStorage('jwt-value'), (
        request,
      ) async {
        return http.Response(
          jsonEncode({'message': 'Database unavailable'}),
          500,
        );
      });

      expect(
        () => service.updateMyLocation(
          latitude: 28.7041,
          longitude: 77.1025,
          capturedAt: DateTime.parse('2026-08-09T08:00:00.000Z'),
        ),
        throwsA(
          isA<AuthException>()
              .having((e) => e.statusCode, 'status', 500)
              .having((e) => e.message, 'message', 'Database unavailable'),
        ),
      );
    });
  });
}
