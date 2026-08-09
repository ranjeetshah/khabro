import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/auth/data/auth_exception.dart';
import 'package:mobile/features/users/data/public_user_model.dart';
import 'package:mobile/features/users/data/public_user_service.dart';
import 'package:mobile/features/users/presentation/public_author_profile_screen.dart';

class FakePublicUserService extends PublicUserService {
  FakePublicUserService({this.user, this.error})
    : super(apiClient: null, tokenStorage: null);

  final PublicUserModel? user;
  final AuthException? error;
  var calls = 0;

  @override
  Future<PublicUserModel> getPublicUser(String id) async {
    calls++;
    if (error != null) throw error!;
    return user!;
  }
}

void main() {
  testWidgets('renders only the public name', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: PublicAuthorProfileScreen(
          userId: 'author-1',
          publicUserService: FakePublicUserService(
            user: const PublicUserModel(id: 'author-1', name: 'Test User'),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Test User'), findsOneWidget);
    expect(find.text('author-1'), findsNothing);
    expect(find.textContaining('phone'), findsNothing);
    expect(find.textContaining('email'), findsNothing);
    expect(find.textContaining('trustScore'), findsNothing);
    expect(find.textContaining('latitude'), findsNothing);
  });

  testWidgets('uses the fallback for null names', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: PublicAuthorProfileScreen(
          userId: 'author-1',
          publicUserService: FakePublicUserService(
            user: const PublicUserModel(id: 'author-1', name: null),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Khabro User'), findsOneWidget);
  });

  testWidgets('handles not found and network errors safely', (tester) async {
    final notFound = FakePublicUserService(
      error: const AuthException('Public user not found', statusCode: 404),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: PublicAuthorProfileScreen(
          userId: 'missing',
          publicUserService: notFound,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('User not found.'), findsOneWidget);
    expect(find.text('RETRY'), findsNothing);

    final failed = FakePublicUserService(
      error: const AuthException('Server unavailable', statusCode: 500),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: PublicAuthorProfileScreen(
          userId: 'author-1',
          publicUserService: failed,
          key: const ValueKey('network-error-profile'),
        ),
      ),
    );
    await tester.pump();
    await tester.pumpAndSettle();
    expect(find.text("Couldn't load profile."), findsOneWidget);
    expect(find.text('RETRY'), findsOneWidget);
    await tester.tap(find.text('RETRY'));
    await tester.pumpAndSettle();
    expect(failed.calls, 2);
  });
}
