import 'dart:convert';

import '../../../core/network/api_client.dart';
import '../../../core/storage/token_storage.dart';
import '../../auth/data/auth_exception.dart';
import 'like_status_model.dart';
import 'post_model.dart';

class PostsService {
  PostsService({ApiClient? apiClient, TokenStorage? tokenStorage})
    : _apiClient = apiClient ?? ApiClient(),
      _tokenStorage = tokenStorage ?? TokenStorage();

  final ApiClient _apiClient;
  final TokenStorage _tokenStorage;

  Future<PostModel> createPost(String content) async {
    final response = await _request(
      (headers) => _apiClient.post(
        '/posts',
        headers: headers,
        body: {'content': content},
      ),
    );
    _checkStatus(response, 'Failed to create post');
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return PostModel.fromJson(data['post'] as Map<String, dynamic>);
  }

  Future<List<PostModel>> getMyPosts() async {
    final response = await _request(
      (headers) => _apiClient.get('/posts/me', headers: headers),
    );
    _checkStatus(response, 'Failed to fetch posts');
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return (data['posts'] as List<dynamic>)
        .map((post) => PostModel.fromJson(post as Map<String, dynamic>))
        .toList();
  }

  Future<PostModel> getPost(String id) async {
    final response = await _request(
      (headers) => _apiClient.get('/posts/$id', headers: headers),
    );
    _checkStatus(response, 'Failed to fetch post');
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return PostModel.fromJson(data['post'] as Map<String, dynamic>);
  }

  Future<void> deletePost(String id) async {
    final response = await _request(
      (headers) => _apiClient.delete('/posts/$id', headers: headers),
    );
    _checkStatus(response, 'Failed to delete post');
  }

  Future<LikeStatusModel> likePost(String id) async {
    return _updateLike('/posts/$id/like', 'Failed to like post');
  }

  Future<LikeStatusModel> unlikePost(String id) async {
    final response = await _request(
      (headers) => _apiClient.delete('/posts/$id/like', headers: headers),
    );
    _checkStatus(response, 'Failed to unlike post');
    return _parseLikeStatus(response.body);
  }

  Future<LikeStatusModel> _updateLike(String path, String fallback) async {
    final response = await _request(
      (headers) => _apiClient.post(path, headers: headers),
    );
    _checkStatus(response, fallback);
    return _parseLikeStatus(response.body);
  }

  LikeStatusModel _parseLikeStatus(String body) {
    final data = jsonDecode(body) as Map<String, dynamic>;
    return LikeStatusModel.fromJson(data['like'] as Map<String, dynamic>);
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
