import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../core/network/api_client.dart';
import '../../../core/storage/token_storage.dart';
import 'auth_exception.dart';
import 'models/auth_response.dart';
import 'models/user_model.dart';

/// Service for authentication operations against the Khabro backend.
class AuthService {
  AuthService({ApiClient? apiClient, TokenStorage? tokenStorage})
    : _apiClient = apiClient ?? ApiClient(),
      _tokenStorage = tokenStorage ?? TokenStorage();

  final ApiClient _apiClient;
  final TokenStorage _tokenStorage;

  /// Register a new user and store the access token.
  Future<AuthResponse> register(String phone, String name) async {
    final response = await _apiClient.post(
      '/auth/register',
      body: {'phone': phone, 'name': name},
    );

    if (response.statusCode == 409) {
      throw const AuthException(
        'A user with this phone already exists',
        statusCode: 409,
      );
    }

    if (response.statusCode != 201 && response.statusCode != 200) {
      throw AuthException(
        _extractErrorMessage(response.body, 'Registration failed'),
        statusCode: response.statusCode,
      );
    }

    final authResponse = _parseSuccessfulAuthResponse(response);

    await _tokenStorage.saveAccessToken(authResponse.accessToken);

    return authResponse;
  }

  /// Dev login for an existing user and store the access token.
  Future<AuthResponse> devLogin(String phone) async {
    final response = await _apiClient.post(
      '/auth/dev-login',
      body: {'phone': phone},
    );

    if (response.statusCode == 404) {
      throw const AuthException(
        'User not found. Register first.',
        statusCode: 404,
      );
    }

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw AuthException(
        _extractErrorMessage(response.body, 'Login failed'),
        statusCode: response.statusCode,
      );
    }

    final authResponse = _parseSuccessfulAuthResponse(response);

    await _tokenStorage.saveAccessToken(authResponse.accessToken);

    return authResponse;
  }

  /// Fetch the current authenticated user's data.
  Future<UserModel> getMe() async {
    final token = await _tokenStorage.getAccessToken();

    if (token == null) {
      throw const AuthException(
        'Not authenticated. Please log in.',
        statusCode: 401,
      );
    }

    final response = await _apiClient.get(
      '/auth/me',
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 401) {
      throw const AuthException(
        'Session expired. Please log in again.',
        statusCode: 401,
      );
    }

    if (response.statusCode != 200) {
      throw AuthException(
        _extractErrorMessage(response.body, 'Failed to fetch user'),
        statusCode: response.statusCode,
      );
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return UserModel.fromJson(data['user'] as Map<String, dynamic>);
  }

  /// Log out by deleting the stored access token.
  Future<void> logout() async {
    await _tokenStorage.deleteAccessToken();
  }

  /// Extract a human-readable error message from a JSON error response.
  String _extractErrorMessage(String body, String fallback) {
    try {
      final data = jsonDecode(body) as Map<String, dynamic>;
      return (data['message'] as String?) ?? fallback;
    } catch (_) {
      return fallback;
    }
  }

  AuthResponse _parseSuccessfulAuthResponse(http.Response response) {
    try {
      final authResponse = AuthResponse.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>,
      );

      if (authResponse.accessToken.trim().isEmpty) {
        throw const FormatException('Missing access token');
      }

      return authResponse;
    } catch (_) {
      throw AuthException(
        'Authentication response was invalid',
        statusCode: response.statusCode,
      );
    }
  }
}
