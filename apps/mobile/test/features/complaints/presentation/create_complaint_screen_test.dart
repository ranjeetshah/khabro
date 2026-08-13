import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/complaints/data/complaint_model.dart';
import 'package:mobile/features/complaints/data/complaint_service.dart';
import 'package:mobile/features/complaints/data/complaint_status.dart';
import 'package:mobile/features/complaints/presentation/complaint_detail_screen.dart';
import 'package:mobile/features/complaints/presentation/create_complaint_screen.dart';
import 'package:mobile/features/posts/data/post_model.dart';
import 'package:mobile/features/posts/data/verification_status.dart';
import 'package:mobile/features/users/data/public_user_model.dart';

PostModel complaintPost() => PostModel(
  id: 'post-1',
  authorId: 'private-author-id',
  localityId: 'private-locality-id',
  content: 'A pothole near the market',
  createdAt: DateTime.parse('2026-08-09T08:00:00.000Z'),
  updatedAt: DateTime.parse('2026-08-09T08:00:01.000Z'),
  author: const PublicUserModel(id: 'author-1', name: 'Test User'),
  verificationStatus: VerificationStatus.locallyVerified,
);

class FakeComplaintService extends ComplaintService {
  FakeComplaintService({this.createError})
    : super(apiClient: null, tokenStorage: null);

  Object? createError;
  Completer<ComplaintSubmissionModel>? createCompleter;
  var createCalls = 0;
  String? createPostId;
  String? createDescription;

  @override
  Future<ComplaintSubmissionModel> createComplaint(
    String postId,
    String description,
  ) async {
    createCalls++;
    createPostId = postId;
    createDescription = description;
    if (createCompleter != null) return createCompleter!.future;
    if (createError != null) throw createError!;
    return const ComplaintSubmissionModel(
      id: 'complaint-1',
      status: ComplaintStatus.submitted,
    );
  }

  @override
  Future<ComplaintDetailModel> getComplaint(String id) async {
    return ComplaintDetailModel(
      id: id,
      status: ComplaintStatus.submitted,
      description: 'A pothole near the market',
      createdAt: DateTime.parse('2026-08-09T08:05:00.000Z'),
      updatedAt: DateTime.parse('2026-08-09T08:05:00.000Z'),
      statusHistory: const [],
    );
  }
}

void main() {
  testWidgets('submit stays disabled until the description is long enough', (
    tester,
  ) async {
    final service = FakeComplaintService();
    await tester.pumpWidget(
      MaterialApp(
        home: CreateComplaintScreen(post: complaintPost(), complaintService: service),
      ),
    );

    final submit = find.widgetWithText(FilledButton, 'Submit complaint');
    expect(submit, findsOneWidget);
    await tester.enterText(find.byType(TextField), 'Short');
    await tester.pump();
    expect(
      tester.widget<FilledButton>(submit).onPressed,
      isNull,
    );

    await tester.enterText(
      find.byType(TextField),
      'A deep pothole blocking the street for days',
    );
    await tester.pump();
    expect(
      tester.widget<FilledButton>(submit).onPressed,
      isNotNull,
    );
  });

  testWidgets('submits the description and navigates to the detail screen', (
    tester,
  ) async {
    final service = FakeComplaintService();
    await tester.pumpWidget(
      MaterialApp(
        home: CreateComplaintScreen(post: complaintPost(), complaintService: service),
      ),
    );
    await tester.enterText(
      find.byType(TextField),
      'A deep pothole blocking the street for days',
    );
    await tester.pump();
    await tester.tap(find.widgetWithText(FilledButton, 'Submit complaint'));
    await tester.pumpAndSettle();

    expect(service.createCalls, 1);
    expect(service.createPostId, 'post-1');
    expect(service.createDescription, 'A deep pothole blocking the street for days');
    expect(find.byType(ComplaintDetailScreen), findsOneWidget);
    expect(find.text('Submitted'), findsOneWidget);
  });

  testWidgets('errors show a safe message and retry recovers', (tester) async {
    final service = FakeComplaintService(createError: Exception('boom'));
    await tester.pumpWidget(
      MaterialApp(
        home: CreateComplaintScreen(post: complaintPost(), complaintService: service),
      ),
    );
    await tester.enterText(
      find.byType(TextField),
      'A deep pothole blocking the street for days',
    );
    await tester.pump();
    await tester.tap(find.widgetWithText(FilledButton, 'Submit complaint'));
    await tester.pumpAndSettle();
    expect(
      find.text('Something went wrong. Please try again.'),
      findsOneWidget,
    );

    service.createError = null;
    await tester.tap(find.widgetWithText(FilledButton, 'Submit complaint'));
    await tester.pumpAndSettle();
    expect(service.createCalls, 2);
    expect(find.byType(ComplaintDetailScreen), findsOneWidget);
  });

  testWidgets('the create screen never exposes private metadata', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: CreateComplaintScreen(
          post: complaintPost(),
          complaintService: FakeComplaintService(),
        ),
      ),
    );
    expect(find.text('private-locality-id'), findsNothing);
    expect(find.text('private-author-id'), findsNothing);
    expect(find.text('latitude'), findsNothing);
    expect(find.text('longitude'), findsNothing);
    expect(find.text('JWT'), findsNothing);
  });
}
