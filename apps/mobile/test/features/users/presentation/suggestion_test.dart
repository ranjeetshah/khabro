import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/auth/data/auth_exception.dart';
import 'package:mobile/features/users/data/account_suggestion_model.dart';
import 'package:mobile/features/users/data/follow_status_model.dart';
import 'package:mobile/features/users/data/users_service.dart';
import 'package:mobile/features/users/presentation/account_suggestions_screen.dart';
import 'package:mobile/features/users/presentation/public_author_profile_screen.dart';
import 'package:mobile/features/users/data/public_user_model.dart';
import 'package:mobile/features/users/data/public_user_service.dart';

class FakePublicUserService extends PublicUserService {
  FakePublicUserService() : super(apiClient: null, tokenStorage: null);

  @override
  Future<PublicUserModel> getPublicUser(String id) async {
    return PublicUserModel(
      id: id,
      name: 'Jane Doe',
      followerCount: 15,
      followingCount: 10,
    );
  }
}

class FakeUsersService extends UsersService {
  FakeUsersService() : super(apiClient: null, tokenStorage: null);

  bool throwSuggestionsError = false;
  bool throwFollowError = false;
  bool throw401 = false;
  int followCalls = 0;

  List<AccountSuggestionModel> suggestions = [
    const AccountSuggestionModel(
      id: 'suggest-1',
      name: 'Suggested User 1',
      followerCount: 15,
      followingCount: 5,
      reason: 'Followed by 2 people you follow',
    ),
    const AccountSuggestionModel(
      id: 'suggest-2',
      name: 'Suggested User 2',
      followerCount: 8,
      followingCount: 12,
      reason: 'From your local community',
    ),
  ];

  @override
  Future<List<AccountSuggestionModel>> getAccountSuggestions({
    int page = 1,
    int limit = 20,
  }) async {
    if (throwSuggestionsError) {
      throw const AuthException('Failed to load suggestions.', statusCode: 500);
    }
    return suggestions;
  }

  @override
  Future<FollowStatusModel> followUser(String userId) async {
    followCalls++;
    if (throwFollowError) throw const AuthException('Failed to follow', statusCode: 500);
    if (throw401) throw const AuthException('Session expired', statusCode: 401);
    return const FollowStatusModel(following: true, followerCount: 16, followingCount: 5);
  }

  @override
  Future<FollowStatusModel> getFollowStatus(String userId) async {
    return const FollowStatusModel(
      following: false,
      followerCount: 15,
      followingCount: 10,
    );
  }
}

void main() {
  group('AccountSuggestionModel tests', () {
    test('fromJson parses all fields correctly', () {
      final json = {
        'id': 'user-1',
        'name': 'Rahul',
        'followerCount': 18,
        'followingCount': 11,
        'reason': 'Followed by 3 people you follow',
      };
      final model = AccountSuggestionModel.fromJson(json);
      expect(model.id, 'user-1');
      expect(model.name, 'Rahul');
      expect(model.followerCount, 18);
      expect(model.followingCount, 11);
      expect(model.reason, 'Followed by 3 people you follow');
    });

    test('fromJson handles missing fields safely', () {
      final model = AccountSuggestionModel.fromJson({});
      expect(model.id, '');
      expect(model.name, isNull);
      expect(model.followerCount, 0);
      expect(model.followingCount, 0);
      expect(model.reason, isNull);
    });
  });

  group('AccountSuggestionsScreen widget tests', () {
    late FakeUsersService fakeService;

    testWidgets('renders suggestions list and navigation on tap', (tester) async {
      fakeService = FakeUsersService();
      final fakePublicService = FakePublicUserService();

      await tester.pumpWidget(
        MaterialApp(
          home: AccountSuggestionsScreen(
            usersService: fakeService,
            publicUserService: fakePublicService,
            currentUserId: 'me-123',
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Suggested User 1'), findsOneWidget);
      expect(find.text('Followed by 2 people you follow'), findsOneWidget);
      expect(find.text('15 followers'), findsOneWidget);

      expect(find.text('Suggested User 2'), findsOneWidget);
      expect(find.text('From your local community'), findsOneWidget);
      expect(find.text('8 followers'), findsOneWidget);

      // Tap suggestion to navigate to profile
      await tester.tap(find.text('Suggested User 1'));
      await tester.pumpAndSettle();
      expect(find.byType(PublicAuthorProfileScreen), findsOneWidget);
    });

    testWidgets('empty suggestions shows custom caught up state', (tester) async {
      fakeService = FakeUsersService();
      fakeService.suggestions = [];

      await tester.pumpWidget(
        MaterialApp(
          home: AccountSuggestionsScreen(
            usersService: fakeService,
            currentUserId: 'me-123',
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text("You're all caught up."), findsOneWidget);
      expect(
        find.text("We'll show new people here when we find relevant connections."),
        findsOneWidget,
      );
    });

    testWidgets('shows error state and retries successfully', (tester) async {
      fakeService = FakeUsersService();
      fakeService.throwSuggestionsError = true;

      await tester.pumpWidget(
        MaterialApp(
          home: AccountSuggestionsScreen(
            usersService: fakeService,
            currentUserId: 'me-123',
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Failed to load suggestions.'), findsOneWidget);
      expect(find.text('RETRY'), findsOneWidget);

      fakeService.throwSuggestionsError = false;
      await tester.tap(find.text('RETRY'));
      await tester.pumpAndSettle();

      expect(find.text('Suggested User 1'), findsOneWidget);
    });

    testWidgets('toggles follow, prevents duplicate requests, and removes followed user card after a delay', (tester) async {
      fakeService = FakeUsersService();

      await tester.pumpWidget(
        MaterialApp(
          home: AccountSuggestionsScreen(
            usersService: fakeService,
            currentUserId: 'me-123',
          ),
        ),
      );
      await tester.pumpAndSettle();

      final followBtn = find.descendant(
        of: find.byType(Card).first,
        matching: find.byType(ElevatedButton),
      );

      // Tap once to follow
      await tester.tap(followBtn);
      // Double tap immediately to test rapid clicks protection
      await tester.tap(followBtn);
      await tester.pump();

      expect(fakeService.followCalls, 1); // Should only execute once

      await tester.pumpAndSettle(); // Complete request and transition delay
      expect(find.text('Suggested User 1'), findsNothing); // Removed from suggestions
      expect(find.text('Suggested User 2'), findsOneWidget); // Others remain
    });
  });
}
