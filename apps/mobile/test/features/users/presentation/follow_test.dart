import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/auth/data/auth_exception.dart';
import 'package:mobile/features/users/data/follow_status_model.dart';
import 'package:mobile/features/users/data/public_user_model.dart';
import 'package:mobile/features/users/data/public_user_service.dart';
import 'package:mobile/features/users/data/users_service.dart';
import 'package:mobile/features/users/presentation/followers_screen.dart';
import 'package:mobile/features/users/presentation/following_screen.dart';
import 'package:mobile/features/users/presentation/public_author_profile_screen.dart';

class FakePublicUserService extends PublicUserService {
  FakePublicUserService() : super(apiClient: null, tokenStorage: null);

  bool throwError = false;
  bool throw404 = false;
  PublicUserModel mockUser = const PublicUserModel(
    id: 'user-456',
    name: 'Jane Doe',
    followerCount: 15,
    followingCount: 10,
  );

  @override
  Future<PublicUserModel> getPublicUser(String id) async {
    if (throwError) throw const AuthException('Server error', statusCode: 500);
    if (throw404) throw const AuthException('User not found.', statusCode: 404);
    return mockUser;
  }

  @override
  Future<void> reportUser(String id, {required String reason, String? description}) async {}
}

class FakeUsersService extends UsersService {
  FakeUsersService() : super(apiClient: null, tokenStorage: null);

  bool throwStatusError = false;
  bool throwFollowError = false;
  bool throwUnfollowError = false;
  bool throwListError = false;
  bool throw401 = false;
  int followCalls = 0;
  int unfollowCalls = 0;

  FollowStatusModel status = const FollowStatusModel(
    following: false,
    followerCount: 15,
    followingCount: 10,
  );

  List<PublicUserModel> followers = [
    const PublicUserModel(id: 'f-1', name: 'Follower One'),
    const PublicUserModel(id: 'f-2', name: 'Follower Two'),
  ];

  List<PublicUserModel> following = [
    const PublicUserModel(id: 'fol-1', name: 'Following One'),
  ];

  @override
  Future<FollowStatusModel> getFollowStatus(String userId) async {
    if (throwStatusError) throw const AuthException('Connection error', statusCode: 500);
    return status;
  }

  @override
  Future<FollowStatusModel> followUser(String userId) async {
    followCalls++;
    if (throwFollowError) throw const AuthException('Failed to follow', statusCode: 500);
    if (throw401) throw const AuthException('Session expired', statusCode: 401);
    return const FollowStatusModel(following: true, followerCount: 16, followingCount: 10);
  }

  @override
  Future<FollowStatusModel> unfollowUser(String userId) async {
    unfollowCalls++;
    if (throwUnfollowError) throw const AuthException('Failed to unfollow', statusCode: 500);
    return const FollowStatusModel(following: false, followerCount: 14, followingCount: 10);
  }

  @override
  Future<List<PublicUserModel>> getFollowers({
    required String userId,
    int page = 1,
    int limit = 20,
  }) async {
    if (throwListError) throw const AuthException('Failed to fetch followers', statusCode: 500);
    if (throw401) throw const AuthException('Session expired', statusCode: 401);
    return followers;
  }

  @override
  Future<List<PublicUserModel>> getFollowing({
    required String userId,
    int page = 1,
    int limit = 20,
  }) async {
    if (throwListError) throw const AuthException('Failed to fetch following', statusCode: 500);
    return following;
  }
}

void main() {
  group('FollowStatusModel tests', () {
    test('fromJson parses correctly', () {
      final json = {
        'following': true,
        'followerCount': 100,
        'followingCount': 50,
      };
      final model = FollowStatusModel.fromJson(json);
      expect(model.following, isTrue);
      expect(model.followerCount, 100);
      expect(model.followingCount, 50);
    });

    test('fromJson handles missing fields gracefully', () {
      final model = FollowStatusModel.fromJson({});
      expect(model.following, isFalse);
      expect(model.followerCount, 0);
      expect(model.followingCount, 0);
    });
  });

  group('PublicAuthorProfileScreen widget tests', () {
    late FakePublicUserService fakePublicService;
    late FakeUsersService fakeUsersService;

    testWidgets('renders public profile fields and stats', (tester) async {
      fakePublicService = FakePublicUserService();
      fakeUsersService = FakeUsersService();

      await tester.pumpWidget(
        MaterialApp(
          home: PublicAuthorProfileScreen(
            userId: 'user-456',
            currentUserId: 'me-123',
            publicUserService: fakePublicService,
            usersService: fakeUsersService,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Jane Doe'), findsOneWidget);
      expect(find.text('15'), findsOneWidget); // Followers count
      expect(find.text('10'), findsOneWidget); // Following count
      expect(find.text('Followers'), findsOneWidget);
      expect(find.text('Following'), findsOneWidget);
      expect(find.text('Follow'), findsOneWidget); // Action button
    });

    testWidgets('does not show Follow button when viewing oneself', (tester) async {
      fakePublicService = FakePublicUserService();
      fakeUsersService = FakeUsersService();

      await tester.pumpWidget(
        MaterialApp(
          home: PublicAuthorProfileScreen(
            userId: 'user-456',
            currentUserId: 'user-456', // Same as profile user
            publicUserService: fakePublicService,
            usersService: fakeUsersService,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(ElevatedButton), findsNothing);
    });

    testWidgets('toggles follow and unfollow states', (tester) async {
      fakePublicService = FakePublicUserService();
      fakeUsersService = FakeUsersService();

      await tester.pumpWidget(
        MaterialApp(
          home: PublicAuthorProfileScreen(
            userId: 'user-456',
            currentUserId: 'me-123',
            publicUserService: fakePublicService,
            usersService: fakeUsersService,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.descendant(of: find.byType(ElevatedButton), matching: find.text('Follow')), findsOneWidget);
      await tester.tap(find.byType(ElevatedButton));
      await tester.pump(); // Start request

      expect(fakeUsersService.followCalls, 1);
      await tester.pumpAndSettle(); // Complete request

      expect(find.descendant(of: find.byType(ElevatedButton), matching: find.text('Following')), findsOneWidget);
      expect(find.text('16'), findsOneWidget); // Incremented follower count

      // Unfollow
      await tester.tap(find.byType(ElevatedButton));
      await tester.pump();
      expect(fakeUsersService.unfollowCalls, 1);
      await tester.pumpAndSettle();

      expect(find.descendant(of: find.byType(ElevatedButton), matching: find.text('Follow')), findsOneWidget);
      expect(find.text('14'), findsOneWidget);
    });

    testWidgets('prevents rapid double-taps on follow button', (tester) async {
      fakePublicService = FakePublicUserService();
      fakeUsersService = FakeUsersService();

      await tester.pumpWidget(
        MaterialApp(
          home: PublicAuthorProfileScreen(
            userId: 'user-456',
            currentUserId: 'me-123',
            publicUserService: fakePublicService,
            usersService: fakeUsersService,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byType(ElevatedButton));
      await tester.tap(find.byType(ElevatedButton)); // Immediate second tap
      await tester.pumpAndSettle();

      expect(fakeUsersService.followCalls, 1); // Should only execute once
    });

    testWidgets('shows snackbar error on follow failure and recovers state', (tester) async {
      fakePublicService = FakePublicUserService();
      fakeUsersService = FakeUsersService();
      fakeUsersService.throwFollowError = true;

      await tester.pumpWidget(
        MaterialApp(
          home: PublicAuthorProfileScreen(
            userId: 'user-456',
            currentUserId: 'me-123',
            publicUserService: fakePublicService,
            usersService: fakeUsersService,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();

      expect(find.text('Failed to follow'), findsOneWidget);
      expect(find.descendant(of: find.byType(ElevatedButton), matching: find.text('Follow')), findsOneWidget);
    });

    testWidgets('handles 401 session expiry callback', (tester) async {
      fakePublicService = FakePublicUserService();
      fakeUsersService = FakeUsersService();
      fakeUsersService.throw401 = true;
      bool sessionExpiredCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: PublicAuthorProfileScreen(
            userId: 'user-456',
            currentUserId: 'me-123',
            publicUserService: fakePublicService,
            usersService: fakeUsersService,
            onSessionExpired: () {
              sessionExpiredCalled = true;
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();

      expect(sessionExpiredCalled, isTrue);
    });
  });

  group('FollowersScreen and FollowingScreen widget tests', () {
    late FakeUsersService fakeUsersService;

    testWidgets('FollowersScreen renders followers list', (tester) async {
      fakeUsersService = FakeUsersService();

      await tester.pumpWidget(
        MaterialApp(
          home: FollowersScreen(
            userId: 'user-123',
            usersService: fakeUsersService,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Follower One'), findsOneWidget);
      expect(find.text('Follower Two'), findsOneWidget);
    });

    testWidgets('FollowersScreen shows empty message', (tester) async {
      fakeUsersService = FakeUsersService();
      fakeUsersService.followers = [];

      await tester.pumpWidget(
        MaterialApp(
          home: FollowersScreen(
            userId: 'user-123',
            usersService: fakeUsersService,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('No followers yet.'), findsOneWidget);
    });

    testWidgets('FollowingScreen renders following list', (tester) async {
      fakeUsersService = FakeUsersService();

      await tester.pumpWidget(
        MaterialApp(
          home: FollowingScreen(
            userId: 'user-123',
            usersService: fakeUsersService,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Following One'), findsOneWidget);
    });

    testWidgets('FollowingScreen shows empty message', (tester) async {
      fakeUsersService = FakeUsersService();
      fakeUsersService.following = [];

      await tester.pumpWidget(
        MaterialApp(
          home: FollowingScreen(
            userId: 'user-123',
            usersService: fakeUsersService,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Not following anyone yet.'), findsOneWidget);
    });

    testWidgets('handles error retry path correctly', (tester) async {
      fakeUsersService = FakeUsersService();
      fakeUsersService.throwListError = true;

      await tester.pumpWidget(
        MaterialApp(
          home: FollowersScreen(
            userId: 'user-123',
            usersService: fakeUsersService,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Failed to fetch followers'), findsOneWidget);
      expect(find.text('RETRY'), findsOneWidget);

      fakeUsersService.throwListError = false;
      await tester.tap(find.text('RETRY'));
      await tester.pumpAndSettle();

      expect(find.text('Follower One'), findsOneWidget);
    });
  });
}
