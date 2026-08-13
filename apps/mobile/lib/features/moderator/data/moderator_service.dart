import 'dart:convert';

import '../../../core/network/api_client.dart';
import '../../../core/storage/token_storage.dart';
import '../../auth/data/auth_exception.dart';
import '../../feedback/data/feedback_model.dart';
import 'moderator_dashboard_model.dart';
import 'moderator_report_model.dart';
import 'moderator_civic_complaint_model.dart';

class ModeratorReportsResponse {
  const ModeratorReportsResponse({
    required this.items,
    required this.page,
    required this.limit,
    required this.total,
    required this.hasMore,
  });

  final List<ModeratorReportModel> items;
  final int page;
  final int limit;
  final int total;
  final bool hasMore;
}

class ModeratorCivicComplaintsResponse {
  const ModeratorCivicComplaintsResponse({
    required this.items,
    required this.page,
    required this.limit,
    required this.total,
    required this.hasMore,
  });

  final List<ModeratorCivicComplaintModel> items;
  final int page;
  final int limit;
  final int total;
  final bool hasMore;
}

class ModeratorService {
  ModeratorService({ApiClient? apiClient, TokenStorage? tokenStorage})
    : _apiClient = apiClient ?? ApiClient(),
      _tokenStorage = tokenStorage ?? TokenStorage();

  final ApiClient _apiClient;
  final TokenStorage _tokenStorage;

  Future<ModeratorDashboardModel> getDashboard() async {
    final response = await _request(
      (headers) => _apiClient.get('/moderator/dashboard', headers: headers),
    );
    _checkStatus(response, 'Failed to fetch dashboard counts');
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return ModeratorDashboardModel.fromJson(data);
  }

  Future<ModeratorReportsResponse> getReports(
    int page,
    int limit, {
    String? type,
    String? status,
  }) async {
    final Map<String, String> queryParams = {
      'page': page.toString(),
      'limit': limit.toString(),
    };
    if (type != null && type.isNotEmpty && type != 'ALL') {
      queryParams['type'] = type;
    }
    if (status != null && status.isNotEmpty) {
      queryParams['status'] = status;
    }

    final uri = Uri(path: '/moderator/reports', queryParameters: queryParams);

    final response = await _request(
      (headers) => _apiClient.get(uri.toString(), headers: headers),
    );
    _checkStatus(response, 'Failed to fetch moderation reports');
    final data = jsonDecode(response.body) as Map<String, dynamic>;

    final items = (data['items'] as List<dynamic>)
        .map((x) => ModeratorReportModel.fromJson(x as Map<String, dynamic>))
        .toList();

    return ModeratorReportsResponse(
      items: items,
      page: (data['page'] as num).toInt(),
      limit: (data['limit'] as num).toInt(),
      total: (data['total'] as num).toInt(),
      hasMore: data['hasMore'] as bool? ?? false,
    );
  }

  Future<ModeratorReportDetailModel> getReportDetail(String id) async {
    final response = await _request(
      (headers) => _apiClient.get('/moderator/reports/$id', headers: headers),
    );
    _checkStatus(response, 'Failed to fetch report detail');
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return ModeratorReportDetailModel.fromJson(data);
  }

  Future<void> updateReportStatus(String id, String status) async {
    final response = await _request(
      (headers) => _apiClient.patch(
        '/moderator/reports/$id/status',
        headers: headers,
        body: {'status': status},
      ),
    );
    _checkStatus(response, 'Failed to update report status');
  }

  Future<ModeratorCivicComplaintsResponse> getCivicComplaints(
    int page,
    int limit, {
    String? status,
  }) async {
    final Map<String, String> queryParams = {
      'page': page.toString(),
      'limit': limit.toString(),
    };
    if (status != null && status.isNotEmpty) {
      queryParams['status'] = status;
    }

    final uri = Uri(
      path: '/moderator/civic-complaints',
      queryParameters: queryParams,
    );

    final response = await _request(
      (headers) => _apiClient.get(uri.toString(), headers: headers),
    );
    _checkStatus(response, 'Failed to fetch civic complaints');
    final data = jsonDecode(response.body) as Map<String, dynamic>;

    final items = (data['items'] as List<dynamic>)
        .map((x) => ModeratorCivicComplaintModel.fromJson(x as Map<String, dynamic>))
        .toList();

    return ModeratorCivicComplaintsResponse(
      items: items,
      page: (data['page'] as num).toInt(),
      limit: (data['limit'] as num).toInt(),
      total: (data['total'] as num).toInt(),
      hasMore: data['hasMore'] as bool? ?? false,
    );
  }

  Future<ModeratorCivicComplaintModel> getCivicComplaintDetail(String id) async {
    final response = await _request(
      (headers) => _apiClient.get('/moderator/civic-complaints/$id', headers: headers),
    );
    _checkStatus(response, 'Failed to fetch civic complaint detail');
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return ModeratorCivicComplaintModel.fromJson(data);
  }

  Future<FeedbackPageModel> getFeedbacks({
    int page = 1,
    int limit = 20,
    String? type,
    String? status,
  }) async {
    final queryParams = <String, String>{
      'page': page.toString(),
      'limit': limit.toString(),
    };
    if (type != null && type.isNotEmpty && type != 'ALL') {
      queryParams['type'] = type;
    }
    if (status != null && status.isNotEmpty) {
      queryParams['status'] = status;
    }

    final uri = Uri(
      path: '/moderator/feedback',
      queryParameters: queryParams,
    );

    final response = await _request(
      (headers) => _apiClient.get(uri.toString(), headers: headers),
    );
    _checkStatus(response, 'Failed to load feedback');
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return FeedbackPageModel.fromJson(data);
  }

  Future<FeedbackModel> getFeedbackDetail(String id) async {
    final response = await _request(
      (headers) => _apiClient.get('/moderator/feedback/$id', headers: headers),
    );
    _checkStatus(response, 'Failed to load feedback detail');
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return FeedbackModel.fromJson(data);
  }

  Future<void> updateFeedbackStatus(String id, String status) async {
    final response = await _request(
      (headers) => _apiClient.patch(
        '/moderator/feedback/$id/status',
        headers: headers,
        body: {'status': status},
      ),
    );
    _checkStatus(response, 'Failed to update feedback status');
  }

  Future<void> updateCivicComplaintStatus(
    String id,
    String status, {
    String? note,
  }) async {
    final body = <String, dynamic>{'status': status};
    if (note != null && note.trim().isNotEmpty) {
      body['note'] = note.trim();
    }

    final response = await _request(
      (headers) => _apiClient.patch(
        '/civic-complaints/$id/status',
        headers: headers,
        body: body,
      ),
    );
    _checkStatus(response, 'Failed to update complaint status');
  }

  Future<dynamic> _request(
    Future<dynamic> Function(Map<String, String> headers) request,
  ) async {
    final token = await _tokenStorage.getAccessToken();
    if (token == null || token.isEmpty) {
      throw const AuthException(
        'Not authenticated. Please log in.',
        statusCode: 401,
      );
    }
    return request({'Authorization': 'Bearer $token'});
  }

  void _checkStatus(dynamic response, String fallback) {
    if (response.statusCode == 401) {
      throw const AuthException(
        'Session expired. Please log in again.',
        statusCode: 401,
      );
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw AuthException(
        _extractErrorMessage(response.body, fallback),
        statusCode: response.statusCode,
      );
    }
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
