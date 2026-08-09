import 'dart:convert';

import '../../../core/network/api_client.dart';
import '../../../core/storage/token_storage.dart';
import '../../auth/data/auth_exception.dart';
import 'location_model.dart';

/// Service for the authenticated user's current location.
class LocationService {
  LocationService({ApiClient? apiClient, TokenStorage? tokenStorage})
    : _apiClient = apiClient ?? ApiClient(),
      _tokenStorage = tokenStorage ?? TokenStorage();

  final ApiClient _apiClient;
  final TokenStorage _tokenStorage;

  Future<LocationModel?> getMyLocation() async {
    final response = await _request(
      (headers) => _apiClient.get('/location/me', headers: headers),
    );

    if (response.statusCode == 401) {
      throw const AuthException(
        'Session expired. Please log in again.',
        statusCode: 401,
      );
    }

    if (response.statusCode != 200) {
      throw AuthException(
        _extractErrorMessage(response.body, 'Failed to fetch location'),
        statusCode: response.statusCode,
      );
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final location = data['location'];
    return location == null
        ? null
        : LocationModel.fromJson(location as Map<String, dynamic>);
  }

  Future<LocationModel> updateMyLocation({
    required double latitude,
    required double longitude,
    double? accuracyMeters,
    required DateTime capturedAt,
  }) async {
    final response = await _request(
      (headers) => _apiClient.put(
        '/location/me',
        headers: headers,
        body: {
          'latitude': latitude,
          'longitude': longitude,
          'accuracyMeters': accuracyMeters,
          'capturedAt': capturedAt.toIso8601String(),
        },
      ),
    );

    if (response.statusCode == 401) {
      throw const AuthException(
        'Session expired. Please log in again.',
        statusCode: 401,
      );
    }

    if (response.statusCode == 400) {
      throw AuthException(
        _extractErrorMessage(response.body, 'Invalid location data'),
        statusCode: 400,
      );
    }

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw AuthException(
        _extractErrorMessage(response.body, 'Failed to update location'),
        statusCode: response.statusCode,
      );
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return LocationModel.fromJson(data['location'] as Map<String, dynamic>);
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
