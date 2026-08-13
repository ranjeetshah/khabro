import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/auth/data/models/user_model.dart';
import 'package:mobile/features/users/data/my_report_model.dart';
import 'package:mobile/features/users/data/profile_model.dart';
import 'package:mobile/features/users/data/users_service.dart';
import 'package:mobile/features/users/data/witness_history_model.dart';
import 'package:mobile/features/users/presentation/my_reports_screen.dart';
import 'package:mobile/features/users/presentation/profile_screen.dart';
import 'package:mobile/features/users/presentation/witness_history_screen.dart';

class FakeUsersService extends UsersService {
  FakeUsersService(this.updatedUser)
    : super(apiClient: null, tokenStorage: null);

  final UserModel updatedUser;
  String? savedName;
  List<MyReportModel> reports = [];
  List<WitnessHistoryModel> witnesses = [];

  @override
  Future<UserModel> updateMe(String name) async {
    savedName = name;
    return updatedUser;
  }

  @override
  Future<ProfileModel> getMyProfile() async {
    return ProfileModel(
      id: updatedUser.id,
      phone: updatedUser.phone,
      name: updatedUser.name,
      allowCivicComplaintContactSharing: false,
      createdAt: DateTime.now(),
      stats: const ProfileStatsModel(
        postCount: 5,
        reportCount: 2,
        witnessCount: 3,
        verifiedContributionCount: 1,
      ),
    );
  }

  @override
  Future<List<MyReportModel>> getMyReports({
    int page = 1,
    int limit = 20,
  }) async {
    return reports;
  }

  @override
  Future<List<WitnessHistoryModel>> getMyWitnessHistory({
    int page = 1,
    int limit = 20,
  }) async {
    return witnesses;
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
  testWidgets('displays profile data, stats, and makes name editable', (
    tester,
  ) async {
    final service = FakeUsersService(initialUser);

    await tester.pumpWidget(
      MaterialApp(home: ProfileScreen(user: initialUser, usersService: service)),
    );
    await tester.pumpAndSettle();

    expect(find.text('Test User'), findsWidgets);
    expect(find.text('+919876543210'), findsOneWidget);
    expect(find.text('Community Contributions'), findsOneWidget);
    expect(find.text('Posts'), findsOneWidget);
    expect(find.text('5'), findsOneWidget);
    expect(find.text('My Reports'), findsOneWidget);
    expect(find.text('Witness History'), findsOneWidget);
  });

  testWidgets('renders MyReportsScreen empty state', (tester) async {
    final service = FakeUsersService(initialUser);

    await tester.pumpWidget(
      MaterialApp(home: MyReportsScreen(usersService: service)),
    );
    await tester.pumpAndSettle();

    expect(find.text("You haven't submitted any reports."), findsOneWidget);
  });

  testWidgets('renders WitnessHistoryScreen empty state', (tester) async {
    final service = FakeUsersService(initialUser);

    await tester.pumpWidget(
      MaterialApp(home: WitnessHistoryScreen(usersService: service)),
    );
    await tester.pumpAndSettle();

    expect(find.text("You haven't witnessed any posts yet."), findsOneWidget);
  });
}
