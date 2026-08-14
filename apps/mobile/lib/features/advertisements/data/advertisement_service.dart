import 'dart:convert';

import '../../../core/network/api_client.dart';
import '../../../core/storage/token_storage.dart';
import '../../auth/data/auth_exception.dart';
import 'advertisement_model.dart';

class AdvertisementPageModel {
  const AdvertisementPageModel({
    required this.items,
    required this.page,
    required this.limit,
    required this.total,
    required this.hasMore,
  });

  final List<AdvertisementModel> items;
  final int page;
  final int limit;
  final int total;
  final bool hasMore;

  factory AdvertisementPageModel.fromJson(Map<String, dynamic> json) {
    return AdvertisementPageModel(
      items: (json['items'] as List<dynamic>? ?? [])
          .whereType<Map<String, dynamic>>()
          .map(AdvertisementModel.fromJson)
          .toList(),
      page: (json['page'] as num?)?.toInt() ?? 1,
      limit: (json['limit'] as num?)?.toInt() ?? 20,
      total: (json['total'] as num?)?.toInt() ?? 0,
      hasMore: json['hasMore'] as bool? ?? false,
    );
  }
}

class AdvertisementService {
  AdvertisementService({ApiClient? apiClient, TokenStorage? tokenStorage})
    : _apiClient = apiClient ?? ApiClient(),
      _tokenStorage = tokenStorage ?? TokenStorage();

  final ApiClient _apiClient;
  final TokenStorage _tokenStorage;

  Future<AdvertisementPageModel> getAdvertisements({
    required AdvertisementPlacement placement,
    int page = 1,
    int limit = 5,
  }) async {
    final query = {
      'placement': placement.wire,
      'page': page.toString(),
      'limit': limit.toString(),
    };
    final uri = Uri(path: '/advertisements', queryParameters: query);
    final response = await _request(
      (headers) => _apiClient.get(uri.toString(), headers: headers),
    );
    _checkStatus(response, 'Failed to load advertisements');
    return AdvertisementPageModel.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  Future<void> recordImpression(String id) async {
    final response = await _request(
      (headers) =>
          _apiClient.post('/advertisements/$id/impression', headers: headers),
    );
    _checkStatus(response, 'Failed to record impression');
  }

  Future<void> recordClick(String id) async {
    final response = await _request(
      (headers) =>
          _apiClient.post('/advertisements/$id/click', headers: headers),
    );
    _checkStatus(response, 'Failed to record click');
  }

  // ----- Moderator operations -----

  Future<AdvertisementPageModel> getModeratorAdvertisements({
    int page = 1,
    int limit = 20,
    String? status,
    String? placement,
  }) async {
    final query = <String, String>{
      'page': page.toString(),
      'limit': limit.toString(),
    };
    if (status != null && status.isNotEmpty) {
      query['status'] = status;
    }
    if (placement != null && placement.isNotEmpty && placement != 'ALL') {
      query['placement'] = placement;
    }
    final uri = Uri(
      path: '/moderator/advertisements',
      queryParameters: query,
    );
    final response = await _request(
      (headers) => _apiClient.get(uri.toString(), headers: headers),
    );
    _checkStatus(response, 'Failed to load advertisements');
    return AdvertisementPageModel.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  Future<AdvertisementModel> getModeratorAdvertisementDetail(String id) async {
    final response = await _request(
      (headers) =>
          _apiClient.get('/moderator/advertisements/$id', headers: headers),
    );
    _checkStatus(response, 'Failed to load advertisement detail');
    return AdvertisementModel.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  Future<AdvertisementModel> createAdvertisement(
    Map<String, dynamic> fields,
  ) async {
    final response = await _request(
      (headers) => _apiClient.post(
        '/moderator/advertisements',
        headers: headers,
        body: fields,
      ),
    );
    _checkStatus(response, 'Failed to create advertisement');
    return AdvertisementModel.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  Future<AdvertisementModel> updateAdvertisement(
    String id,
    Map<String, dynamic> fields,
  ) async {
    final response = await _request(
      (headers) => _apiClient.patch(
        '/moderator/advertisements/$id',
        headers: headers,
        body: fields,
      ),
    );
    _checkStatus(response, 'Failed to update advertisement');
    return AdvertisementModel.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  Future<AdvertisementModel> activateAdvertisement(String id) async {
    final response = await _request(
      (headers) => _apiClient.post(
        '/moderator/advertisements/$id/activate',
        headers: headers,
      ),
    );
    _checkStatus(response, 'Failed to activate advertisement');
    return AdvertisementModel.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  Future<AdvertisementModel> pauseAdvertisement(String id) async {
    final response = await _request(
      (headers) => _apiClient.post(
        '/moderator/advertisements/$id/pause',
        headers: headers,
      ),
    );
    _checkStatus(response, 'Failed to pause advertisement');
    return AdvertisementModel.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  Future<void> cancelAdvertisement(String id) async {
    final response = await _request(
      (headers) =>
          _apiClient.delete('/moderator/advertisements/$id', headers: headers),
    );
    _checkStatus(response, 'Failed to cancel advertisement');
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