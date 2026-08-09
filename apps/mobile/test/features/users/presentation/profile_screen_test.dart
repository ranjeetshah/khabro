import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/auth/data/models/user_model.dart';
import 'package:mobile/features/users/data/users_service.dart';
import 'package:mobile/features/users/presentation/profile_screen.dart';

class FakeUsersService extends UsersService {
  FakeUsersService(this.updatedUser)
    : super(apiClient: null, tokenStorage: null);

  final UserModel updatedUser;
  String? savedName;

  @override
  Future<UserModel> updateMe(String name) async {
    savedName = name;
    return updatedUser;
  }
}

const initialUser = UserModel(
  id: 'user-123',
  phone: '+919876543210',
  name: 'Test User',
  trustScore: 10,
  status: 'ACTIVE',
);

void main() {
  testWidgets('displays profile data and only makes name editable', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: ProfileScreen(user: initialUser)),
    );

    expect(find.text('Khabro'), findsOneWidget);
    expect(find.text('+919876543210'), findsOneWidget);
    expect(find.text('Test User'), findsOneWidget);
    expect(find.text('10'), findsOneWidget);
    expect(find.text('ACTIVE'), findsOneWidget);
    expect(find.byType(TextField), findsNothing);

    await tester.tap(find.text('EDIT NAME'));
    await tester.pump();

    expect(find.byType(TextField), findsOneWidget);
    expect(find.text('Phone'), findsOneWidget);
    expect(find.text('Trust Score'), findsOneWidget);
    expect(find.text('Status'), findsOneWidget);
  });

  testWidgets('successful save updates displayed name', (tester) async {
    final updatedUser = initialUser.copyWith(name: () => 'Updated Name');
    final service = FakeUsersService(updatedUser);

    await tester.pumpWidget(
      MaterialApp(
        home: ProfileScreen(user: initialUser, usersService: service),
      ),
    );

    await tester.tap(find.text('EDIT NAME'));
    await tester.pump();
    await tester.enterText(find.byType(TextField), 'Updated Name');
    await tester.tap(find.text('SAVE'));
    await tester.pumpAndSettle();

    expect(service.savedName, 'Updated Name');
    expect(find.text('Updated Name'), findsOneWidget);
    expect(find.text('Name updated successfully!'), findsOneWidget);
  });
}
