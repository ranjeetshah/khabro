import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../core/network/api_client.dart';
import '../../../core/storage/token_storage.dart';
import '../../auth/data/auth_exception.dart';
import '../../auth/data/models/user_model.dart';
import 'my_report_model.dart';
import 'profile_model.dart';
import 'witness_history_model.dart';

/// Service for user profile operations against the Khabro backend.
class UsersService {
  UsersService({ApiClient? apiClient, TokenStorage? tokenStorage})
    : _apiClient = apiClient ?? ApiClient(),
      _tokenStorage = tokenStorage ?? TokenStorage();

  final ApiClient _apiClient;
  final TokenStorage _tokenStorage;

  /// Fetch the authenticated user's profile from GET /users/me.
  Future<UserModel> getMe() async {
    final response = await _request(
      (headers) => _apiClient.get('/users/me', headers: headers),
    );
    _checkStatus(response, 'Failed to fetch profile');
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return UserModel.fromJson(data['user'] as Map<String, dynamic>);
  }

  /// Fetch full ProfileModel with stats from GET /users/me.
  Future<ProfileModel> getMyProfile() async {
    final response = await _request(
      (headers) => _apiClient.get('/users/me', headers: headers),
    );
    _checkStatus(response, 'Failed to fetch profile');
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return ProfileModel.fromJson(data['user'] as Map<String, dynamic>);
  }

  /// Fetch submitted reports from GET /users/me/reports.
  Future<List<MyReportModel>> getMyReports({
    int page = 1,
    int limit = 20,
  }) async {
    final response = await _request(
      (headers) => _apiClient.get(
        '/users/me/reports?page=$page&limit=$limit',
        headers: headers,
      ),
    );
    _checkStatus(response, "Couldn't load reports.");
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final list = data['items'] as List<dynamic>? ?? [];
    return list
        .map((item) => MyReportModel.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  /// Fetch witness history from GET /users/me/witnesses.
  Future<List<WitnessHistoryModel>> getMyWitnessHistory({
    int page = 1,
    int limit = 20,
  }) async {
    final response = await _request(
      (headers) => _apiClient.get(
        '/users/me/witnesses?page=$page&limit=$limit',
        headers: headers,
      ),
    );
    _checkStatus(response, "Couldn't load witness history.");
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final list = data['items'] as List<dynamic>? ?? [];
    return list
        .map(
          (item) => WitnessHistoryModel.fromJson(item as Map<String, dynamic>),
        )
        .toList();
  }

  /// Update the authenticated user's profile via PATCH /users/me.
  Future<UserModel> updateMe(String name) async {
    return updateProfile(name: name);
  }

  /// Update profile fields via PATCH /users/me.
  Future<UserModel> updateProfile({
    String? name,
    bool? allowCivicComplaintContactSharing,
  }) async {
    final body = <String, dynamic>{};
    if (name != null) body['name'] = name;
    if (allowCivicComplaintContactSharing != null) {
      body['allowCivicComplaintContactSharing'] =
          allowCivicComplaintContactSharing;
    }
    final response = await _request(
      (headers) =>
          _apiClient.patch('/users/me', body: body, headers: headers),
    );
    _checkStatus(response, 'Failed to update profile');
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return UserModel.fromJson(data['user'] as Map<String, dynamic>);
  }

  Future<http.Response> _request(
    Future<http.Response> Function(Map<String, String> headers) action,
  ) async {
    final token = await _tokenStorage.getAccessToken();
    if (token == null || token.isEmpty) {
      throw const AuthException('Not authenticated', statusCode: 401);
    }
    final headers = {'Authorization': 'Bearer $token'};
    final response = await action(headers);

    if (response.statusCode == 401) {
      await _tokenStorage.deleteAccessToken();
      throw const AuthException('Session expired', statusCode: 401);
    }

    return response;
  }

  void _checkStatus(http.Response response, String defaultErrorMsg) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return;
    }
    throw AuthException(
      _extractErrorMessage(response.body, defaultErrorMsg),
      statusCode: response.statusCode,
    );
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
