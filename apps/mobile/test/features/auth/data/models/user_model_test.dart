import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/auth/data/models/user_model.dart';

void main() {
  group('UserModel', () {
    test('fromJson parses all fields correctly', () {
      final json = {
        'id': 'user-123',
        'phone': '+919876543210',
        'name': 'Test User',
        'trustScore': 5,
        'status': 'ACTIVE',
      };

      final user = UserModel.fromJson(json);

      expect(user.id, 'user-123');
      expect(user.phone, '+919876543210');
      expect(user.name, 'Test User');
      expect(user.trustScore, 5);
      expect(user.status, 'ACTIVE');
    });

    test('fromJson handles null name', () {
      final json = {
        'id': 'user-456',
        'phone': '+919876543210',
        'name': null,
        'trustScore': 0,
        'status': 'ACTIVE',
      };

      final user = UserModel.fromJson(json);

      expect(user.name, isNull);
    });

    test('toJson produces correct map', () {
      const user = UserModel(
        id: 'user-123',
        phone: '+919876543210',
        name: 'Test User',
        trustScore: 5,
        status: 'ACTIVE',
      );

      final json = user.toJson();

      expect(json, {
        'id': 'user-123',
        'phone': '+919876543210',
        'name': 'Test User',
        'trustScore': 5,
        'status': 'ACTIVE',
      });
    });

    test('fromJson throws on missing required field', () {
      final json = {
        'id': 'user-123',
        'phone': '+919876543210',
        // missing trustScore, status
      };

      expect(() => UserModel.fromJson(json), throwsA(isA<TypeError>()));
    });
  });
}
