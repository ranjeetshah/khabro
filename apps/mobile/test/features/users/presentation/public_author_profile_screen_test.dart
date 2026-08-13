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
  var reportCalls = 0;
  String? reportUserId;
  String? reportReason;

  @override
  Future<PublicUserModel> getPublicUser(String id) async {
    calls++;
    if (error != null) throw error!;
    return user!;
  }

  @override
  Future<void> reportUser(
    String id, {
    required String reason,
    String? description,
  }) async {
    reportCalls++;
    reportUserId = id;
    reportReason = reason;
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

  testWidgets('report user submits the selected reason safely', (tester) async {
    final service = FakePublicUserService(
      user: const PublicUserModel(id: 'author-1', name: 'Test User'),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: PublicAuthorProfileScreen(
          userId: 'author-1',
          publicUserService: service,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('More options'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Report user'));
    await tester.pumpAndSettle();
    expect(find.text('Why are you reporting this?'), findsOneWidget);

    await tester.tap(find.text('Harassment'));
    await tester.pump();
    await tester.tap(find.widgetWithText(FilledButton, 'Submit report'));
    await tester.pumpAndSettle();

    expect(service.reportCalls, 1);
    expect(service.reportUserId, 'author-1');
    expect(service.reportReason, 'HARASSMENT');
    expect(find.text('Report submitted'), findsOneWidget);
    expect(find.text('author-1'), findsNothing);
    expect(find.text('report-1'), findsNothing);
    expect(find.text('JWT'), findsNothing);
  });
}
