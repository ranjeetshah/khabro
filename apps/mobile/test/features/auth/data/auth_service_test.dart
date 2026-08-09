import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart' as http_testing;
import 'package:mobile/core/network/api_client.dart';
import 'package:mobile/core/storage/token_storage.dart';
import 'package:mobile/features/auth/data/auth_exception.dart';
import 'package:mobile/features/auth/data/auth_service.dart';
import 'package:mobile/features/auth/data/models/user_model.dart';

/// In-memory fake for TokenStorage so tests don't need flutter_secure_storage.
class FakeTokenStorage extends TokenStorage {
  FakeTokenStorage() : super(storage: null);

  String? _token;

  @override
  Future<void> saveAccessToken(String token) async {
    _token = token;
  }

  @override
  Future<String?> getAccessToken() async {
    return _token;
  }

  @override
  Future<void> deleteAccessToken() async {
    _token = null;
  }
}

/// Helper to build an ApiClient backed by a mock HTTP handler.
ApiClient buildMockApiClient(http_testing.MockClientHandler handler) {
  return ApiClient(httpClient: http_testing.MockClient(handler));
}

const _validUserJson = {
  'id': 'user-123',
  'phone': '+919876543210',
  'name': 'Test User',
  'trustScore': 0,
  'status': 'ACTIVE',
};

const _validAuthResponseJson = {
  'accessToken': 'mock.jwt.token',
  'user': _validUserJson,
};

void main() {
  group('AuthService.register', () {
    test('success — returns AuthResponse and saves token', () async {
      final tokenStorage = FakeTokenStorage();

      final apiClient = buildMockApiClient((request) async {
        expect(request.url.path, '/auth/register');
        expect(request.method, 'POST');
        return http.Response(
          jsonEncode(_validAuthResponseJson),
          201,
          headers: {'content-type': 'application/json'},
        );
      });

      final authService = AuthService(
        apiClient: apiClient,
        tokenStorage: tokenStorage,
      );

      final result = await authService.register('+919876543210', 'Test User');

      expect(result.accessToken, 'mock.jwt.token');
      expect(result.user.id, 'user-123');
      expect(await tokenStorage.getAccessToken(), 'mock.jwt.token');
    });

    test('duplicate phone — throws AuthException with 409', () async {
      final apiClient = buildMockApiClient((request) async {
        return http.Response(
          jsonEncode({'message': 'A user with this phone already exists'}),
          409,
          headers: {'content-type': 'application/json'},
        );
      });

      final authService = AuthService(
        apiClient: apiClient,
        tokenStorage: FakeTokenStorage(),
      );

      expect(
        () => authService.register('+919876543210', 'Test User'),
        throwsA(
          isA<AuthException>().having((e) => e.statusCode, 'statusCode', 409),
        ),
      );
    });

    test('server error — throws AuthException', () async {
      final apiClient = buildMockApiClient((request) async {
        return http.Response(
          jsonEncode({'message': 'Internal server error'}),
          500,
          headers: {'content-type': 'application/json'},
        );
      });

      final authService = AuthService(
        apiClient: apiClient,
        tokenStorage: FakeTokenStorage(),
      );

      expect(
        () => authService.register('+919876543210', 'Test User'),
        throwsA(isA<AuthException>()),
      );
    });
  });

  group('AuthService.devLogin', () {
    test('success — returns AuthResponse and saves token', () async {
      final tokenStorage = FakeTokenStorage();

      final apiClient = buildMockApiClient((request) async {
        expect(request.url.path, '/auth/dev-login');
        return http.Response(
          jsonEncode(_validAuthResponseJson),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final authService = AuthService(
        apiClient: apiClient,
        tokenStorage: tokenStorage,
      );

      final result = await authService.devLogin('+919876543210');

      expect(result.accessToken, 'mock.jwt.token');
      expect(result.user.phone, '+919876543210');
      expect(await tokenStorage.getAccessToken(), 'mock.jwt.token');
    });

    test('201 with a valid access token succeeds', () async {
      final tokenStorage = FakeTokenStorage();
      final authService = AuthService(
        apiClient: buildMockApiClient((request) async {
          return http.Response(
            jsonEncode(_validAuthResponseJson),
            201,
            headers: {'content-type': 'application/json'},
          );
        }),
        tokenStorage: tokenStorage,
      );

      final result = await authService.devLogin('+919876543210');

      expect(result.accessToken, 'mock.jwt.token');
      expect(await tokenStorage.getAccessToken(), 'mock.jwt.token');
    });

    test('unknown user — throws AuthException with 404', () async {
      final apiClient = buildMockApiClient((request) async {
        return http.Response(
          jsonEncode({'message': 'User not found'}),
          404,
          headers: {'content-type': 'application/json'},
        );
      });

      final authService = AuthService(
        apiClient: apiClient,
        tokenStorage: FakeTokenStorage(),
      );

      expect(
        () => authService.devLogin('+919876543210'),
        throwsA(
          isA<AuthException>().having((e) => e.statusCode, 'statusCode', 404),
        ),
      );
    });

    test('unauthorized response throws AuthException with 401', () async {
      final authService = AuthService(
        apiClient: buildMockApiClient((request) async {
          return http.Response(jsonEncode({'message': 'Unauthorized'}), 401);
        }),
        tokenStorage: FakeTokenStorage(),
      );

      expect(
        () => authService.devLogin('+919876543210'),
        throwsA(
          isA<AuthException>().having((e) => e.statusCode, 'statusCode', 401),
        ),
      );
    });

    test('successful response without an access token fails', () async {
      final authService = AuthService(
        apiClient: buildMockApiClient((request) async {
          return http.Response(jsonEncode({'user': _validUserJson}), 200);
        }),
        tokenStorage: FakeTokenStorage(),
      );

      expect(
        () => authService.devLogin('+919876543210'),
        throwsA(
          isA<AuthException>()
              .having((e) => e.statusCode, 'statusCode', 200)
              .having(
                (e) => e.message,
                'message',
                'Authentication response was invalid',
              ),
        ),
      );
    });
  });

  group('AuthService.getMe', () {
    test('success — returns UserModel', () async {
      final tokenStorage = FakeTokenStorage();
      await tokenStorage.saveAccessToken('valid.token');

      final apiClient = buildMockApiClient((request) async {
        expect(request.url.path, '/auth/me');
        expect(request.headers['Authorization'], 'Bearer valid.token');
        return http.Response(
          jsonEncode({'user': _validUserJson}),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final authService = AuthService(
        apiClient: apiClient,
        tokenStorage: tokenStorage,
      );

      final user = await authService.getMe();

      expect(user, isA<UserModel>());
      expect(user.id, 'user-123');
    });

    test('no token — throws AuthException with 401', () async {
      final authService = AuthService(
        apiClient: buildMockApiClient((request) async {
          fail('Should not make HTTP request without token');
          // ignore: dead_code
          return http.Response('', 500);
        }),
        tokenStorage: FakeTokenStorage(),
      );

      expect(
        () => authService.getMe(),
        throwsA(
          isA<AuthException>().having((e) => e.statusCode, 'statusCode', 401),
        ),
      );
    });

    test('expired token — throws AuthException with 401', () async {
      final tokenStorage = FakeTokenStorage();
      await tokenStorage.saveAccessToken('expired.token');

      final apiClient = buildMockApiClient((request) async {
        return http.Response(
          jsonEncode({'message': 'Unauthorized'}),
          401,
          headers: {'content-type': 'application/json'},
        );
      });

      final authService = AuthService(
        apiClient: apiClient,
        tokenStorage: tokenStorage,
      );

      expect(
        () => authService.getMe(),
        throwsA(
          isA<AuthException>().having((e) => e.statusCode, 'statusCode', 401),
        ),
      );
    });
  });
}
