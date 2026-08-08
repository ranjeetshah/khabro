import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/auth/data/models/auth_response.dart';
import 'package:mobile/features/auth/data/models/user_model.dart';

void main() {
  group('AuthResponse', () {
    test('fromJson parses accessToken and user correctly', () {
      final json = {
        'accessToken': 'jwt.token.here',
        'user': {
          'id': 'user-123',
          'phone': '+919876543210',
          'name': 'Test User',
          'trustScore': 0,
          'status': 'ACTIVE',
        },
      };

      final response = AuthResponse.fromJson(json);

      expect(response.accessToken, 'jwt.token.here');
      expect(response.user, isA<UserModel>());
      expect(response.user.id, 'user-123');
      expect(response.user.phone, '+919876543210');
      expect(response.user.name, 'Test User');
    });

    test('fromJson throws on missing accessToken', () {
      final json = {
        'user': {
          'id': 'user-123',
          'phone': '+919876543210',
          'name': null,
          'trustScore': 0,
          'status': 'ACTIVE',
        },
      };

      expect(() => AuthResponse.fromJson(json), throwsA(isA<TypeError>()));
    });

    test('fromJson throws on missing user object', () {
      final json = {
        'accessToken': 'jwt.token.here',
      };

      expect(() => AuthResponse.fromJson(json), throwsA(isA<TypeError>()));
    });
  });
}
