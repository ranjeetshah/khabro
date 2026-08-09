import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart' as http_testing;
import 'package:mobile/core/network/api_client.dart';
import 'package:mobile/core/storage/token_storage.dart';
import 'package:mobile/features/auth/data/auth_exception.dart';
import 'package:mobile/features/location/data/locality_model.dart';
import 'package:mobile/features/location/data/locality_service.dart';

class FakeTokenStorage extends TokenStorage {
  FakeTokenStorage([this.token]) : super(storage: null);

  String? token;

  @override
  Future<String?> getAccessToken() async => token;
}

const localityJson = {
  'id': 'development-locality-a',
  'name': 'Test Locality A',
  'city': 'Delhi',
  'state': 'Delhi',
  'country': 'India',
};

LocalityService serviceFor(
  FakeTokenStorage storage,
  http_testing.MockClientHandler handler,
) {
  return LocalityService(
    tokenStorage: storage,
    apiClient: ApiClient(httpClient: http_testing.MockClient(handler)),
  );
}

void main() {
  group('LocalityService', () {
    test('success returns locality and sends bearer token', () async {
      final service = serviceFor(FakeTokenStorage('jwt-value'), (
        request,
      ) async {
        expect(request.method, 'GET');
        expect(request.url.path, '/location/me/locality');
        expect(request.headers['Authorization'], 'Bearer jwt-value');
        return http.Response(jsonEncode({'locality': localityJson}), 200);
      });

      final locality = await service.getMyLocality();

      expect(locality, isA<LocalityModel>());
      expect(locality!.name, 'Test Locality A');
    });

    test('null locality is returned as null', () async {
      final service = serviceFor(FakeTokenStorage('jwt-value'), (
        request,
      ) async {
        return http.Response(jsonEncode({'locality': null}), 200);
      });

      expect(await service.getMyLocality(), isNull);
    });

    test('401 throws an authentication error', () async {
      final service = serviceFor(FakeTokenStorage('expired'), (request) async {
        return http.Response(jsonEncode({'message': 'Unauthorized'}), 401);
      });

      expect(
        () => service.getMyLocality(),
        throwsA(
          isA<AuthException>().having((e) => e.statusCode, 'status', 401),
        ),
      );
    });

    test('server error preserves the backend message', () async {
      final service = serviceFor(FakeTokenStorage('jwt-value'), (
        request,
      ) async {
        return http.Response(
          jsonEncode({'message': 'Resolver unavailable'}),
          500,
        );
      });

      expect(
        () => service.getMyLocality(),
        throwsA(
          isA<AuthException>()
              .having((e) => e.statusCode, 'status', 500)
              .having((e) => e.message, 'message', 'Resolver unavailable'),
        ),
      );
    });

    test('missing token fails without making a request', () async {
      final service = serviceFor(FakeTokenStorage(null), (request) async {
        fail('No request should be made without a token');
      });

      expect(
        () => service.getMyLocality(),
        throwsA(
          isA<AuthException>().having((e) => e.statusCode, 'status', 401),
        ),
      );
    });
  });
}
