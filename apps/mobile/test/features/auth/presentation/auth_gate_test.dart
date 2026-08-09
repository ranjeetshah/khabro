import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart' as http_testing;

import 'package:mobile/core/network/api_client.dart';
import 'package:mobile/core/storage/token_storage.dart';
import 'package:mobile/features/auth/data/auth_service.dart';
import 'package:mobile/features/auth/presentation/auth_gate.dart';
import 'package:mobile/features/auth/presentation/home_screen.dart';
import 'package:mobile/features/auth/presentation/login_screen.dart';

class FakeTokenStorage extends TokenStorage {
  FakeTokenStorage([this._token]) : super(storage: null);

  String? _token;

  String? get currentToken => _token;

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

ApiClient buildMockApiClient(http_testing.MockClientHandler handler) {
  return ApiClient(httpClient: http_testing.MockClient(handler));
}

const _validUserJson = {
  'id': 'user-123',
  'phone': '+919876543210',
  'name': 'Test User',
  'trustScore': 10,
  'status': 'ACTIVE',
};

const _validAuthResponseJson = {
  'accessToken': 'secret.jwt.token.value',
  'user': _validUserJson,
};

void main() {
  group('AuthGate Session Restoration & State Transitions', () {
    testWidgets('no token -> renders LoginScreen', (WidgetTester tester) async {
      final tokenStorage = FakeTokenStorage(null);
      final apiClient = buildMockApiClient((request) async {
        fail('No HTTP call should be made when no token exists');
      });
      final authService = AuthService(
        apiClient: apiClient,
        tokenStorage: tokenStorage,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: AuthGate(authService: authService, tokenStorage: tokenStorage),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(LoginScreen), findsOneWidget);
      expect(find.byType(HomeScreen), findsNothing);
      expect(find.text('DEV LOGIN'), findsOneWidget);
    });

    testWidgets(
      'valid token + successful /auth/me -> renders HomeScreen with user data',
      (WidgetTester tester) async {
        final tokenStorage = FakeTokenStorage('secret.jwt.token.value');
        final apiClient = buildMockApiClient((request) async {
          expect(request.url.path, '/auth/me');
          expect(
            request.headers['Authorization'],
            'Bearer secret.jwt.token.value',
          );
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

        await tester.pumpWidget(
          MaterialApp(
            home: AuthGate(
              authService: authService,
              tokenStorage: tokenStorage,
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byType(HomeScreen), findsOneWidget);
        expect(find.byType(LoginScreen), findsNothing);
        expect(find.text('Logged in'), findsOneWidget);
        expect(find.text('Test User'), findsOneWidget);
        expect(find.text('+919876543210'), findsOneWidget);
      },
    );

    testWidgets(
      'invalid/expired token (401) -> deletes token and renders LoginScreen',
      (WidgetTester tester) async {
        final tokenStorage = FakeTokenStorage('expired.jwt.token');
        final apiClient = buildMockApiClient((request) async {
          expect(request.url.path, '/auth/me');
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

        await tester.pumpWidget(
          MaterialApp(
            home: AuthGate(
              authService: authService,
              tokenStorage: tokenStorage,
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(tokenStorage.currentToken, isNull);
        expect(find.byType(LoginScreen), findsOneWidget);
        expect(find.byType(HomeScreen), findsNothing);
      },
    );

    testWidgets('logout -> deletes token and transitions to LoginScreen', (
      WidgetTester tester,
    ) async {
      final tokenStorage = FakeTokenStorage('secret.jwt.token.value');
      final apiClient = buildMockApiClient((request) async {
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

      await tester.pumpWidget(
        MaterialApp(
          home: AuthGate(authService: authService, tokenStorage: tokenStorage),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(HomeScreen), findsOneWidget);

      final logoutButton = find.widgetWithText(ElevatedButton, 'LOGOUT');
      await tester.ensureVisible(logoutButton);
      await tester.tap(logoutButton);
      await tester.pumpAndSettle();

      expect(tokenStorage.currentToken, isNull);
      expect(find.byType(LoginScreen), findsOneWidget);
      expect(find.byType(HomeScreen), findsNothing);
    });

    testWidgets('successful login -> transitions to authenticated HomeScreen', (
      WidgetTester tester,
    ) async {
      final tokenStorage = FakeTokenStorage(null);
      final apiClient = buildMockApiClient((request) async {
        if (request.url.path == '/auth/dev-login') {
          return http.Response(
            jsonEncode(_validAuthResponseJson),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        fail('Unexpected path: ${request.url.path}');
      });
      final authService = AuthService(
        apiClient: apiClient,
        tokenStorage: tokenStorage,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: AuthGate(authService: authService, tokenStorage: tokenStorage),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(LoginScreen), findsOneWidget);

      await tester.tap(find.text('DEV LOGIN'));
      await tester.pumpAndSettle();

      expect(tokenStorage.currentToken, 'secret.jwt.token.value');
      expect(find.byType(HomeScreen), findsOneWidget);
      expect(find.text('Logged in'), findsOneWidget);
    });

    testWidgets('session restoration does not expose JWT in UI', (
      WidgetTester tester,
    ) async {
      const secretToken = 'super_secret_jwt_payload_string_xyz_999';
      final tokenStorage = FakeTokenStorage(secretToken);
      final apiClient = buildMockApiClient((request) async {
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

      await tester.pumpWidget(
        MaterialApp(
          home: AuthGate(authService: authService, tokenStorage: tokenStorage),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining(secretToken), findsNothing);
    });

    testWidgets('non-401 session restoration error -> shows retry view', (
      WidgetTester tester,
    ) async {
      final tokenStorage = FakeTokenStorage('valid.token');
      final apiClient = buildMockApiClient((request) async {
        return http.Response(
          jsonEncode({'message': 'Internal Server Error'}),
          500,
          headers: {'content-type': 'application/json'},
        );
      });
      final authService = AuthService(
        apiClient: apiClient,
        tokenStorage: tokenStorage,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: AuthGate(authService: authService, tokenStorage: tokenStorage),
        ),
      );
      await tester.pumpAndSettle();

      expect(tokenStorage.currentToken, equals('valid.token'));
      expect(find.text('RETRY'), findsOneWidget);
      expect(find.text('BACK TO LOGIN'), findsOneWidget);
    });
  });
}
