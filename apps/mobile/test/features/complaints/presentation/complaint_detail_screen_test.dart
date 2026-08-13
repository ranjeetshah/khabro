import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/complaints/data/complaint_model.dart';
import 'package:mobile/features/complaints/data/complaint_service.dart';
import 'package:mobile/features/complaints/data/complaint_status.dart';
import 'package:mobile/features/complaints/presentation/complaint_detail_screen.dart';

class FakeComplaintDetailService extends ComplaintService {
  FakeComplaintDetailService({this.detail, this.error, this.completer})
    : super(apiClient: null, tokenStorage: null);

  ComplaintDetailModel? detail;
  Object? error;
  Completer<ComplaintDetailModel>? completer;
  var calls = 0;

  @override
  Future<ComplaintDetailModel> getComplaint(String id) async {
    calls++;
    if (completer != null) return completer!.future;
    if (error != null) throw error!;
    return detail!;
  }
}

ComplaintDetailModel detailModel() => ComplaintDetailModel(
  id: 'complaint-1',
  status: ComplaintStatus.inProgress,
  description: 'A deep pothole blocking the street for days',
  createdAt: DateTime.parse('2026-08-09T08:05:00.000Z'),
  updatedAt: DateTime.parse('2026-08-10T09:00:00.000Z'),
  postContent: 'A pothole near the market',
  statusHistory: [
    ComplaintStatusHistoryModel(
      toStatus: ComplaintStatus.submitted,
      createdAt: DateTime.parse('2026-08-09T08:05:00.000Z'),
    ),
    ComplaintStatusHistoryModel(
      fromStatus: ComplaintStatus.submitted,
      toStatus: ComplaintStatus.acknowledged,
      createdAt: DateTime.parse('2026-08-10T09:00:00.000Z'),
    ),
  ],
);

void main() {
  testWidgets('renders description, status, date, and timeline', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ComplaintDetailScreen(
          complaintId: 'complaint-1',
          complaintService: FakeComplaintDetailService(detail: detailModel()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('In progress'), findsOneWidget);
    expect(
      find.text('A deep pothole blocking the street for days'),
      findsOneWidget,
    );
    expect(find.text('About the post: A pothole near the market'), findsOneWidget);
    expect(find.text('Submitted'), findsOneWidget);
    expect(find.text('Acknowledged'), findsOneWidget);
    expect(find.textContaining('2026-08-09'), findsWidgets);
  });

  testWidgets('shows a loading indicator first', (tester) async {
    final completer = Completer<ComplaintDetailModel>();
    await tester.pumpWidget(
      MaterialApp(
        home: ComplaintDetailScreen(
          complaintId: 'complaint-1',
          complaintService: FakeComplaintDetailService(completer: completer),
        ),
      ),
    );
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    completer.complete(detailModel());
    await tester.pumpAndSettle();
    expect(find.text('In progress'), findsOneWidget);
  });

  testWidgets('errors show a retry that recovers', (tester) async {
    final service = FakeComplaintDetailService(error: Exception('boom'));
    await tester.pumpWidget(
      MaterialApp(
        home: ComplaintDetailScreen(
          complaintId: 'complaint-1',
          complaintService: service,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Could not load complaint details.'), findsOneWidget);

    service.error = null;
    service.detail = detailModel();
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(find.text('In progress'), findsOneWidget);
  });

  testWidgets('detail screen never exposes private metadata', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ComplaintDetailScreen(
          complaintId: 'complaint-1',
          complaintService: FakeComplaintDetailService(detail: detailModel()),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('post-1'), findsNothing);
    expect(find.text('private-locality-id'), findsNothing);
    expect(find.text('private-author-id'), findsNothing);
    expect(find.text('latitude'), findsNothing);
    expect(find.text('longitude'), findsNothing);
    expect(find.text('JWT'), findsNothing);
    expect(find.text('authority'), findsNothing);
  });
}
