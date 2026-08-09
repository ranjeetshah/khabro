import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart' as http_testing;
import 'package:mobile/core/network/api_client.dart';
import 'package:mobile/core/storage/token_storage.dart';
import 'package:mobile/features/auth/data/auth_exception.dart';
import 'package:mobile/features/users/data/users_service.dart';

class FakeTokenStorage extends TokenStorage {
  FakeTokenStorage([this.token]) : super(storage: null);

  String? token;

  @override
  Future<String?> getAccessToken() async => token;
}

const userJson = {
  'id': 'user-123',
  'phone': '+919876543210',
  'name': 'Test User',
  'trustScore': 10,
  'status': 'ACTIVE',
  'createdAt': '2026-08-08T10:20:30.000Z',
  'updatedAt': '2026-08-09T11:21:31.000Z',
};

UsersService serviceFor(
  FakeTokenStorage storage,
  http_testing.MockClientHandler handler,
) {
  return UsersService(
    tokenStorage: storage,
    apiClient: ApiClient(httpClient: http_testing.MockClient(handler)),
  );
}

void main() {
  group('UsersService', () {
    test('getMe success sends bearer token and parses user', () async {
      final storage = FakeTokenStorage('jwt-value');
      final service = serviceFor(storage, (request) async {
        expect(request.method, 'GET');
        expect(request.url.path, '/users/me');
        expect(request.headers['Authorization'], 'Bearer jwt-value');
        return http.Response(jsonEncode({'user': userJson}), 200);
      });

      final user = await service.getMe();

      expect(user.name, 'Test User');
      expect(user.createdAt, isNotNull);
    });

    test('getMe with missing token throws 401 without a request', () async {
      final service = serviceFor(FakeTokenStorage(null), (request) async {
        fail('No request should be made without a token');
      });

      expect(
        () => service.getMe(),
        throwsA(
          isA<AuthException>().having((e) => e.statusCode, 'status', 401),
        ),
      );
    });

    test('getMe 401 throws a session error', () async {
      final service = serviceFor(FakeTokenStorage('expired'), (request) async {
        return http.Response(jsonEncode({'message': 'Unauthorized'}), 401);
      });

      expect(
        () => service.getMe(),
        throwsA(
          isA<AuthException>().having((e) => e.statusCode, 'status', 401),
        ),
      );
    });

    test('updateMe success sends name and returns updated user', () async {
      final storage = FakeTokenStorage('jwt-value');
      final service = serviceFor(storage, (request) async {
        expect(request.method, 'PATCH');
        expect(request.url.path, '/users/me');
        expect(request.headers['Authorization'], 'Bearer jwt-value');
        expect(jsonDecode(request.body), {'name': 'Updated Name'});
        return http.Response(
          jsonEncode({
            'user': {...userJson, 'name': 'Updated Name'},
          }),
          200,
        );
      });

      final user = await service.updateMe('Updated Name');

      expect(user.name, 'Updated Name');
    });

    test('updateMe validation error preserves backend message', () async {
      final service = serviceFor(FakeTokenStorage('jwt-value'), (
        request,
      ) async {
        return http.Response(
          jsonEncode({'message': 'name must not be empty'}),
          400,
        );
      });

      expect(
        () => service.updateMe(''),
        throwsA(
          isA<AuthException>().having(
            (e) => e.message,
            'message',
            'name must not be empty',
          ),
        ),
      );
    });

    test('updateMe 401 throws a session error', () async {
      final service = serviceFor(FakeTokenStorage('expired'), (request) async {
        return http.Response('', 401);
      });

      expect(
        () => service.updateMe('Updated Name'),
        throwsA(
          isA<AuthException>().having((e) => e.statusCode, 'status', 401),
        ),
      );
    });
  });
}
