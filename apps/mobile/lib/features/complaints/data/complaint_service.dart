import 'dart:convert';

import '../../../core/network/api_client.dart';
import '../../../core/storage/token_storage.dart';
import '../../auth/data/auth_exception.dart';
import 'complaint_model.dart';

class ComplaintService {
  ComplaintService({ApiClient? apiClient, TokenStorage? tokenStorage})
    : _apiClient = apiClient ?? ApiClient(),
      _tokenStorage = tokenStorage ?? TokenStorage();

  final ApiClient _apiClient;
  final TokenStorage _tokenStorage;

  /// Submits a civic complaint for a locally verified post. The author is
  /// derived from the JWT on the backend; only the safe submission result is
  /// returned.
  Future<ComplaintSubmissionModel> createComplaint(
    String postId,
    String description,
  ) async {
    final response = await _authorized(
      (token) => _apiClient.post(
        '/posts/$postId/complaint',
        headers: {'Authorization': 'Bearer $token'},
        body: {'description': description},
      ),
    );

    if (response.statusCode == 401) {
      throw const AuthException(
        'Session expired. Please log in again.',
        statusCode: 401,
      );
    }
    if (response.statusCode != 201) {
      throw AuthException(
        _extractErrorMessage(response.body, 'Failed to submit complaint'),
        statusCode: response.statusCode,
      );
    }

    return ComplaintSubmissionModel.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  /// Fetches a single complaint owned by the current citizen. Other users'
  /// complaints are 404s on the backend and surface here as the same generic
  /// fetch error.
  Future<ComplaintDetailModel> getComplaint(String id) async {
    final response = await _authorized(
      (token) =>
          _apiClient.get('/complaints/$id', headers: {
            'Authorization': 'Bearer $token',
          }),
    );

    if (response.statusCode == 401) {
      throw const AuthException(
        'Session expired. Please log in again.',
        statusCode: 401,
      );
    }
    if (response.statusCode != 200) {
      throw AuthException(
        _extractErrorMessage(response.body, 'Failed to fetch complaint'),
        statusCode: response.statusCode,
      );
    }

    return ComplaintDetailModel.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  /// Fetches the current citizen's complaints.
  Future<List<ComplaintModel>> getMyComplaints() async {
    final response = await _authorized(
      (token) =>
          _apiClient.get('/complaints/me', headers: {
            'Authorization': 'Bearer $token',
          }),
    );

    if (response.statusCode == 401) {
      throw const AuthException(
        'Session expired. Please log in again.',
        statusCode: 401,
      );
    }
    if (response.statusCode != 200) {
      throw AuthException(
        _extractErrorMessage(response.body, 'Failed to fetch complaints'),
        statusCode: response.statusCode,
      );
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return (data['complaints'] as List<dynamic>? ?? [])
        .map((item) => ComplaintModel.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<dynamic> _authorized(
    Future<dynamic> Function(String token) request,
  ) async {
    final token = await _tokenStorage.getAccessToken();
    if (token == null || token.isEmpty) {
      throw const AuthException(
        'Not authenticated. Please log in.',
        statusCode: 401,
      );
    }
    return request(token);
  }

  String _extractErrorMessage(String body, String fallback) {
    try {
      final data = jsonDecode(body) as Map<String, dynamic>;
      final message = data['message'];
      if (message is String) return message;
      if (message is List) return message.join(', ');
      return fallback;
    } catch (_) {
      return fallback;
    }
  }
}
