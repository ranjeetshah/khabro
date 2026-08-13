import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart' as http_testing;
import 'package:mobile/core/network/api_client.dart';
import 'package:mobile/core/storage/token_storage.dart';
import 'package:mobile/features/auth/data/auth_exception.dart';
import 'package:mobile/features/complaints/data/complaint_service.dart';
import 'package:mobile/features/complaints/data/complaint_status.dart';

class FakeTokenStorage extends TokenStorage {
  FakeTokenStorage([this.token]) : super(storage: null);
  String? token;

  @override
  Future<String?> getAccessToken() async => token;
}

ComplaintService serviceFor(
  FakeTokenStorage storage,
  http_testing.MockClientHandler handler,
) => ComplaintService(
  tokenStorage: storage,
  apiClient: ApiClient(httpClient: http_testing.MockClient(handler)),
);

void main() {
  test('createComplaint posts the description and parses the safe result', () async {
    final service = serviceFor(FakeTokenStorage('jwt'), (request) async {
      expect(request.method, 'POST');
      expect(request.url.path, '/posts/post-1/complaint');
      expect(request.headers['Authorization'], 'Bearer jwt');
      expect(jsonDecode(request.body), {'description': 'Broken streetlight'});
      return http.Response(
        jsonEncode({'id': 'complaint-1', 'status': 'SUBMITTED'}),
        201,
      );
    });

    final result = await service.createComplaint('post-1', 'Broken streetlight');
    expect(result.id, 'complaint-1');
    expect(result.status, ComplaintStatus.submitted);
  });

  test('createComplaint surfaces backend errors and 401s', () async {
    final failing = serviceFor(FakeTokenStorage('jwt'), (request) async {
      return http.Response('{"message":"Only locally verified posts qualify"}', 409);
    });
    expect(
      () => failing.createComplaint('post-1', 'Broken streetlight'),
      throwsA(
        isA<AuthException>().having((e) => e.statusCode, 'status', 409),
      ),
    );

    final expired = serviceFor(FakeTokenStorage('jwt'), (request) async {
      return http.Response('{"message":"Unauthorized"}', 401);
    });
    expect(
      () => expired.createComplaint('post-1', 'Broken streetlight'),
      throwsA(isA<AuthException>().having((e) => e.statusCode, 'status', 401)),
    );
  });

  test('getComplaint parses detail without private fields on the model', () async {
    final service = serviceFor(FakeTokenStorage('jwt'), (request) async {
      expect(request.url.path, '/complaints/complaint-1');
      return http.Response(
        jsonEncode({
          'id': 'complaint-1',
          'status': 'IN_PROGRESS',
          'description': 'Broken streetlight',
          'createdAt': '2026-08-09T08:05:00.000Z',
          'updatedAt': '2026-08-10T09:00:00.000Z',
          'post': {
            'content': 'Streetlight flickering',
            'verificationStatus': 'LOCALLY_VERIFIED',
          },
          'statusHistory': [
            {
              'fromStatus': null,
              'toStatus': 'SUBMITTED',
              'createdAt': '2026-08-09T08:05:00.000Z',
            },
            {
              'fromStatus': 'SUBMITTED',
              'toStatus': 'IN_PROGRESS',
              'createdAt': '2026-08-10T09:00:00.000Z',
            },
          ],
        }),
        200,
      );
    });

    final detail = await service.getComplaint('complaint-1');
    expect(detail.id, 'complaint-1');
    expect(detail.status, ComplaintStatus.inProgress);
    expect(detail.description, 'Broken streetlight');
    expect(detail.postContent, 'Streetlight flickering');
    expect(detail.statusHistory, hasLength(2));
    expect(
      detail.statusHistory.first.toStatus,
      ComplaintStatus.submitted,
    );
    expect(
      detail.statusHistory.last.toStatus,
      ComplaintStatus.inProgress,
    );
  });

  test('getComplaint throws AuthException on errors', () async {
    for (final status in [401, 404, 500]) {
      final service = serviceFor(FakeTokenStorage('jwt'), (request) async {
        return http.Response('{"message":"Failure"}', status);
      });
      expect(
        () => service.getComplaint('complaint-1'),
        throwsA(
          isA<AuthException>().having((e) => e.statusCode, 'status', status),
        ),
      );
    }
  });

  test('getMyComplaints parses the citizen list', () async {
    final service = serviceFor(FakeTokenStorage('jwt'), (request) async {
      expect(request.url.path, '/complaints/me');
      return http.Response(
        jsonEncode({
          'complaints': [
            {
              'id': 'complaint-1',
              'status': 'SUBMITTED',
              'description': 'Broken streetlight',
              'createdAt': '2026-08-09T08:05:00.000Z',
            },
            {
              'id': 'complaint-2',
              'status': 'RESOLVED',
              'description': 'Pothole filled',
              'createdAt': '2026-08-10T09:00:00.000Z',
            },
          ],
        }),
        200,
      );
    });

    final complaints = await service.getMyComplaints();
    expect(complaints, hasLength(2));
    expect(complaints.first.status, ComplaintStatus.submitted);
    expect(complaints.last.status, ComplaintStatus.resolved);
    expect(complaints.first.id, 'complaint-1');
  });

  test('unknown future statuses fall back to a safe placeholder', () async {
    final service = serviceFor(FakeTokenStorage('jwt'), (request) async {
      return http.Response(
        jsonEncode({
          'id': 'complaint-1',
          'status': 'FUTURE_STATE',
          'description': 'Broken streetlight',
          'createdAt': '2026-08-09T08:05:00.000Z',
          'updatedAt': '2026-08-09T08:05:00.000Z',
          'statusHistory': [
            {'toStatus': 'FUTURE_STATE', 'createdAt': '2026-08-09T08:05:00.000Z'},
          ],
        }),
        200,
      );
    });

    final detail = await service.getComplaint('complaint-1');
    expect(detail.status, ComplaintStatus.unknown);
    expect(detail.status.label, 'Status update');
  });
}
