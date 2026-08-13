import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart' as http_testing;
import 'package:mobile/core/network/api_client.dart';
import 'package:mobile/core/storage/token_storage.dart';
import 'package:mobile/features/auth/data/auth_exception.dart';
import 'package:mobile/features/users/data/public_user_service.dart';

class FakeTokenStorage extends TokenStorage {
  FakeTokenStorage([this.token]) : super(storage: null);
  String? token;

  @override
  Future<String?> getAccessToken() async => token;
}

PublicUserService serviceFor(
  FakeTokenStorage storage,
  http_testing.MockClientHandler handler,
) => PublicUserService(
  tokenStorage: storage,
  apiClient: ApiClient(httpClient: http_testing.MockClient(handler)),
);

void main() {
  test('success parses only the public user response', () async {
    final service = serviceFor(FakeTokenStorage('jwt'), (request) async {
      expect(request.url.path, '/users/user-1/public');
      return http.Response(jsonEncode({'user': {'id': 'user-1', 'name': 'Test User'}}), 200);
    });
    expect((await service.getPublicUser('user-1')).name, 'Test User');
  });

  test('handles missing token, 401, 404, and server error', () async {
    final missing = serviceFor(FakeTokenStorage(), (request) async => fail('no request'));
    expect(() => missing.getPublicUser('user-1'), throwsA(isA<AuthException>()));

    for (final status in [401, 404, 500]) {
      final service = serviceFor(FakeTokenStorage('jwt'), (request) async {
        return http.Response('{"message":"Failure"}', status);
      });
      expect(
        () => service.getPublicUser('user-1'),
        throwsA(isA<AuthException>().having((e) => e.statusCode, 'status', status)),
      );
    }
  });

  test('reportUser sends the reason and parses errors', () async {
    final service = serviceFor(FakeTokenStorage('jwt'), (request) async {
      expect(request.method, 'POST');
      expect(request.url.path, '/users/user-1/report');
      expect(request.headers['Authorization'], 'Bearer jwt');
      expect(jsonDecode(request.body), {
        'reason': 'HARASSMENT',
        'description': 'Abusive messages',
      });
      return http.Response(jsonEncode({'id': 'report-1', 'status': 'OPEN'}), 201);
    });
    await service.reportUser('user-1', reason: 'HARASSMENT', description: 'Abusive messages');
  });

  test('reportUser requires a token and rejects on server error', () async {
    final missing = serviceFor(FakeTokenStorage(), (request) async => fail('no request'));
    expect(
      () => missing.reportUser('user-1', reason: 'SPAM'),
      throwsA(isA<AuthException>()),
    );

    final failing = serviceFor(FakeTokenStorage('jwt'), (request) async {
      return http.Response('{"message":"Duplicate report"}', 409);
    });
    expect(
      () => failing.reportUser('user-1', reason: 'SPAM'),
      throwsA(isA<AuthException>().having((e) => e.statusCode, 'status', 409)),
    );
  });
}
