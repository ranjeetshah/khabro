import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/auth/data/auth_exception.dart';
import 'package:mobile/features/auth/data/models/user_model.dart';
import 'package:mobile/features/users/data/profile_model.dart';
import 'package:mobile/features/users/data/users_service.dart';
import 'package:mobile/features/users/presentation/profile_screen.dart';
import 'package:mobile/features/moderator/data/moderator_dashboard_model.dart';
import 'package:mobile/features/moderator/data/moderator_report_model.dart';
import 'package:mobile/features/moderator/data/moderator_civic_complaint_model.dart';
import 'package:mobile/features/moderator/data/moderator_service.dart';
import 'package:mobile/features/moderator/presentation/moderator_dashboard_screen.dart';
import 'package:mobile/features/moderator/presentation/moderator_report_list_screen.dart';
import 'package:mobile/features/moderator/presentation/moderator_report_detail_screen.dart';
import 'package:mobile/features/moderator/presentation/moderator_complaint_list_screen.dart';
import 'package:mobile/features/moderator/presentation/moderator_complaint_detail_screen.dart';

class FakeModeratorService extends ModeratorService {
  FakeModeratorService() : super(apiClient: null, tokenStorage: null);

  bool throw403 = false;

  ModeratorDashboardModel dashboardData = const ModeratorDashboardModel(
    openPostReports: 5,
    openUserReports: 2,
    openCommentReports: 3,
    activeCivicComplaints: 4,
    openFeedback: 1,
  );

  List<ModeratorReportModel> reports = [
    ModeratorReportModel(
      id: 'r-post-1',
      type: 'POST',
      reason: 'SPAM',
      description: 'spammy post description',
      status: 'OPEN',
      createdAt: DateTime.utc(2026, 8, 13),
      targetId: 'post-1',
      targetTitle: 'spam content',
    )
  ];

  ModeratorReportDetailModel reportDetail = ModeratorReportDetailModel(
    id: 'r-post-1',
    type: 'POST',
    reason: 'SPAM',
    description: 'spammy post description',
    status: 'OPEN',
    createdAt: DateTime.utc(2026, 8, 13),
    postContent: 'spam content',
    postVerificationStatus: 'REPORTED',
    postWitnessCount: 3,
    postAuthorName: 'Jane Doe',
  );

  List<ModeratorCivicComplaintModel> complaints = [
    ModeratorCivicComplaintModel(
      id: 'c-1',
      referenceCode: 'KH-2026-111111',
      status: 'SENT',
      witnessCount: 12,
      createdAt: DateTime.utc(2026, 8, 13),
    )
  ];

  ModeratorCivicComplaintModel complaintDetail = ModeratorCivicComplaintModel(
    id: 'c-1',
    referenceCode: 'KH-2026-111111',
    status: 'SENT',
    witnessCount: 12,
    createdAt: DateTime.utc(2026, 8, 13),
    statusHistory: [
      ModeratorCivicComplaintHistoryModel(
        id: 'h-1',
        fromStatus: null,
        toStatus: 'SENT',
        note: 'Sent successfully',
        createdAt: DateTime.utc(2026, 8, 13),
      )
    ],
  );

  String? updatedReportId;
  String? updatedReportStatus;

  String? updatedComplaintId;
  String? updatedComplaintStatus;
  String? updatedComplaintNote;

  @override
  Future<ModeratorDashboardModel> getDashboard() async {
    if (throw403) throw const AuthException('Forbidden', statusCode: 403);
    return dashboardData;
  }

  @override
  Future<ModeratorReportsResponse> getReports(
    int page,
    int limit, {
    String? type,
    String? status,
  }) async {
    if (throw403) throw const AuthException('Forbidden', statusCode: 403);
    return ModeratorReportsResponse(
      items: reports,
      page: page,
      limit: limit,
      total: reports.length,
      hasMore: false,
    );
  }

  @override
  Future<ModeratorReportDetailModel> getReportDetail(String id) async {
    if (throw403) throw const AuthException('Forbidden', statusCode: 403);
    return reportDetail;
  }

  @override
  Future<void> updateReportStatus(String id, String status) async {
    updatedReportId = id;
    updatedReportStatus = status;
  }

  @override
  Future<ModeratorCivicComplaintsResponse> getCivicComplaints(
    int page,
    int limit, {
    String? status,
  }) async {
    if (throw403) throw const AuthException('Forbidden', statusCode: 403);
    return ModeratorCivicComplaintsResponse(
      items: complaints,
      page: page,
      limit: limit,
      total: complaints.length,
      hasMore: false,
    );
  }

  @override
  Future<ModeratorCivicComplaintModel> getCivicComplaintDetail(String id) async {
    if (throw403) throw const AuthException('Forbidden', statusCode: 403);
    return complaintDetail;
  }

  @override
  Future<void> updateCivicComplaintStatus(
    String id,
    String status, {
    String? note,
  }) async {
    updatedComplaintId = id;
    updatedComplaintStatus = status;
    updatedComplaintNote = note;
  }
}

class FakeUsersService extends UsersService {
  FakeUsersService(this.user) : super(apiClient: null, tokenStorage: null);
  final UserModel user;

  @override
  Future<UserModel> getMe() async => user;

  @override
  Future<ProfileModel> getMyProfile() async => ProfileModel(
        id: user.id,
        phone: user.phone,
        name: user.name,
        allowCivicComplaintContactSharing: false,
        createdAt: DateTime.now(),
        stats: const ProfileStatsModel(
          postCount: 0,
          reportCount: 0,
          witnessCount: 0,
          verifiedContributionCount: 0,
        ),
      );
}

void main() {
  late FakeModeratorService fakeService;

  setUp(() {
    fakeService = FakeModeratorService();
  });

  testWidgets('ModeratorDashboardScreen displays stats and filters', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ModeratorDashboardScreen(moderatorService: fakeService),
      ),
    );
    await tester.pumpAndSettle();

    // Verify stats are rendered
    expect(find.text('5'), findsOneWidget);
    expect(find.text('Open Reports'), findsOneWidget);
    expect(find.text('3'), findsOneWidget);
    expect(find.text('Comment Reports'), findsNWidgets(2));
    expect(find.text('2'), findsOneWidget);
    expect(find.text('User Reports'), findsNWidgets(2));
    expect(find.text('4'), findsOneWidget);
    expect(find.text('Civic Complaints'), findsNWidgets(2));

    // Verify buttons are rendered
    expect(find.text('All Reports'), findsOneWidget);
    expect(find.text('Post Reports'), findsOneWidget);
  });

  testWidgets('ModeratorDashboardScreen handles 403 Access Denied', (tester) async {
    fakeService.throw403 = true;

    await tester.pumpWidget(
      MaterialApp(
        home: ModeratorDashboardScreen(moderatorService: fakeService),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Access Denied'), findsOneWidget);
    expect(find.text('Forbidden'), findsOneWidget);
  });

  testWidgets('ModeratorReportListScreen renders reports and navigates to detail', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ModeratorReportListScreen(moderatorService: fakeService),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('POST'), findsOneWidget);
    expect(find.text('Reason: SPAM'), findsOneWidget);
    expect(find.text('Target: spam content'), findsOneWidget);
  });

  testWidgets('ModeratorReportDetailScreen details and transition triggers', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ModeratorReportDetailScreen(
          moderatorService: fakeService,
          reportId: 'r-post-1',
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Reason'), findsOneWidget);
    expect(find.text('SPAM'), findsWidgets);
    expect(find.text('Description'), findsOneWidget);
    expect(find.text('spammy post description'), findsOneWidget);
    expect(find.text('Jane Doe'), findsOneWidget);
    expect(find.text('3'), findsOneWidget);

    // Tap mark reviewed
    await tester.tap(find.text('MARK REVIEWED'));
    await tester.pump();
    expect(fakeService.updatedReportId, 'r-post-1');
    expect(fakeService.updatedReportStatus, 'REVIEWED');
  });

  testWidgets('ModeratorComplaintListScreen lists active complaints', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ModeratorComplaintListScreen(moderatorService: fakeService),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('KH-2026-111111'), findsOneWidget);
    expect(find.text('SENT'), findsOneWidget);
    expect(find.text('Witnesses: 12'), findsOneWidget);
  });

  testWidgets('ModeratorComplaintDetailScreen displays transitions and handles history', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ModeratorComplaintDetailScreen(
          moderatorService: fakeService,
          complaintId: 'c-1',
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('KH-2026-111111'), findsOneWidget);
    expect(find.text('Witnesses'), findsOneWidget);
    expect(find.text('12'), findsOneWidget);
    expect(find.text('DRAFT → SENT'), findsOneWidget);
    expect(find.text('Note: Sent successfully'), findsOneWidget);

    // Click transition
    expect(find.text('TRANSITION TO ACKNOWLEDGED'), findsOneWidget);
    await tester.tap(find.text('TRANSITION TO ACKNOWLEDGED'));
    await tester.pumpAndSettle();

    // Dialog note input
    expect(find.text('Transition to ACKNOWLEDGED'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'Transition note text');
    await tester.tap(find.text('SUBMIT'));
    await tester.pump();

    expect(fakeService.updatedComplaintId, 'c-1');
    expect(fakeService.updatedComplaintStatus, 'ACKNOWLEDGED');
    expect(fakeService.updatedComplaintNote, 'Transition note text');
  });

  testWidgets('ProfileScreen hides Moderator Console button for CITIZEN', (tester) async {
    final citizen = const UserModel(
      id: 'citizen-1',
      phone: '+919999999999',
      name: 'John Citizen',
      trustScore: 5,
      status: 'ACTIVE',
      role: 'CITIZEN',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: ProfileScreen(
          user: citizen,
          usersService: FakeUsersService(citizen),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Switch to settings/contributions tab
    await tester.ensureVisible(find.text('Contributions'));
    await tester.tap(find.text('Contributions'));
    await tester.pumpAndSettle();

    expect(find.text('MODERATOR CONSOLE'), findsNothing);
  });

  testWidgets('ProfileScreen shows Moderator Console button for MODERATOR', (tester) async {
    final moderator = const UserModel(
      id: 'moderator-1',
      phone: '+918888888888',
      name: 'Admin Mod',
      trustScore: 25,
      status: 'ACTIVE',
      role: 'MODERATOR',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: ProfileScreen(
          user: moderator,
          usersService: FakeUsersService(moderator),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Switch to settings/contributions tab
    await tester.ensureVisible(find.text('Contributions'));
    await tester.tap(find.text('Contributions'));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('MODERATOR CONSOLE'));
    expect(find.text('MODERATOR CONSOLE'), findsOneWidget);
  });
}
