import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/users/data/public_user_model.dart';

void main() {
  test('parses and serializes a public user', () {
    const user = PublicUserModel(id: 'user-1', name: 'Test User');
    expect(PublicUserModel.fromJson(user.toJson()).name, 'Test User');
  });

  test('supports a null public name', () {
    final user = PublicUserModel.fromJson({'id': 'user-1', 'name': null});
    expect(user.name, isNull);
  });
}
