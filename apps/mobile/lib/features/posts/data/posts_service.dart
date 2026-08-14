import 'dart:convert';
import 'package:http/http.dart' as http;

import '../../../core/network/api_client.dart';
import '../../../core/storage/token_storage.dart';
import '../../auth/data/auth_exception.dart';
import 'civic_complaint_history_model.dart';
import 'civic_complaint_model.dart';
import 'comment_model.dart';
import 'comment_report_reason.dart';
import 'like_status_model.dart';
import 'post_background.dart';
import 'post_media_model.dart';
import 'post_model.dart';
import 'verification_history_model.dart';
import 'verification_status_model.dart';
import 'witness_status_model.dart';

class PostsService {
  PostsService({ApiClient? apiClient, TokenStorage? tokenStorage})
    : _apiClient = apiClient ?? ApiClient(),
      _tokenStorage = tokenStorage ?? TokenStorage();

  final ApiClient _apiClient;
  final TokenStorage _tokenStorage;

  Future<PostModel> createPost(
    String content, {
    String? category,
    PostBackground? background,
    List<String>? mediaIds,
    String? linkUrl,
  }) async {
    final response = await _request(
      (headers) => _apiClient.post(
        '/posts',
        headers: headers,
        body: {
          'content': content,
          if (category != null && category.isNotEmpty) 'category': category,
          if (background != null && !background.isDefault)
            'background': background.wire,
          if (mediaIds != null && mediaIds.isNotEmpty) 'mediaIds': mediaIds,
          if (linkUrl != null && linkUrl.trim().isNotEmpty)
            'linkUrl': linkUrl.trim(),
        },
      ),
    );
    _checkStatus(response, 'Failed to create post');
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final postJson = data.containsKey('post') ? data['post'] : data;
    return PostModel.fromJson(postJson as Map<String, dynamic>);
  }

  Future<PostMediaModel> uploadMedia(
    List<int> bytes,
    String filename,
    String mimeType,
  ) async {
    final token = await _tokenStorage.getAccessToken();
    if (token == null || token.isEmpty) {
      throw const AuthException(
        'Not authenticated. Please log in.',
        statusCode: 401,
      );
    }

    final uri = Uri.parse('${ApiClient.baseUrl}/posts/media/upload');
    final request = http.MultipartRequest('POST', uri);
    request.headers['Authorization'] = 'Bearer $token';
    request.files.add(
      http.MultipartFile.fromBytes(
        'file',
        bytes,
        filename: filename,
      ),
    );

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);
    _checkStatus(response, 'Failed to upload media');
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return PostMediaModel.fromJson(data);
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

  Future<WitnessStatusModel> witnessPost(String id) async {
    return _updateWitness('/posts/$id/witness', 'Failed to witness post');
  }

  Future<WitnessStatusModel> unwitnessPost(String id) async {
    final response = await _request(
      (headers) => _apiClient.delete('/posts/$id/witness', headers: headers),
    );
    _checkStatus(response, 'Failed to unwitness post');
    return _parseWitnessStatus(response.body);
  }

  Future<WitnessStatusModel> getWitnessStatus(String id) async {
    final response = await _request(
      (headers) => _apiClient.get('/posts/$id/witnesses', headers: headers),
    );
    _checkStatus(response, 'Failed to fetch witness status');
    return _parseWitnessStatus(response.body);
  }

  Future<VerificationStatusModel> getVerificationStatus(String id) async {
    final response = await _request(
      (headers) => _apiClient.get('/posts/$id/verification', headers: headers),
    );
    _checkStatus(response, 'Failed to fetch verification status');
    return VerificationStatusModel.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  Future<VerificationHistoryModel> getVerificationHistory(String id) async {
    final response = await _request(
      (headers) =>
          _apiClient.get('/posts/$id/verification/history', headers: headers),
    );
    _checkStatus(response, 'Failed to fetch verification history');
    return VerificationHistoryModel.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  Future<CivicComplaintModel?> getCivicComplaint(String id) async {
    final response = await _request(
      (headers) =>
          _apiClient.get('/posts/$id/civic-complaint', headers: headers),
    );
    if (response.statusCode == 404) return null;
    _checkStatus(response, 'Failed to fetch civic complaint');
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return CivicComplaintModel.fromJson(data);
  }

  Future<List<CivicComplaintHistoryItem>> getCivicComplaintHistory(
    String id,
  ) async {
    final response = await _request(
      (headers) =>
          _apiClient.get('/civic-complaints/$id/history', headers: headers),
    );
    _checkStatus(response, 'Failed to fetch complaint history');
    final list = jsonDecode(response.body) as List<dynamic>;
    return list
        .map(
          (item) =>
              CivicComplaintHistoryItem.fromJson(item as Map<String, dynamic>),
        )
        .toList();
  }

  Future<CivicComplaintModel> confirmCivicComplaintResolution(
    String id,
  ) async {
    final response = await _request(
      (headers) => _apiClient.post(
        '/civic-complaints/$id/confirm',
        headers: headers,
      ),
    );
    _checkStatus(response, 'Failed to confirm resolution');
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return CivicComplaintModel.fromJson(data);
  }

  Future<CivicComplaintModel> reopenCivicComplaint(
    String id,
    String reason,
  ) async {
    final response = await _request(
      (headers) => _apiClient.post(
        '/civic-complaints/$id/reopen',
        headers: headers,
        body: {'reason': reason},
      ),
    );
    _checkStatus(response, 'Failed to reopen complaint');
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return CivicComplaintModel.fromJson(data);
  }

  Future<void> reportPost(
    String id, {
    required String reason,
    String? description,
  }) async {
    final response = await _request(
      (headers) => _apiClient.post(
        '/posts/$id/report',
        headers: headers,
        body: {
          'reason': reason,
          if (description != null && description.trim().isNotEmpty)
            'description': description,
        },
      ),
    );
    _checkStatus(response, 'Failed to report post');
  }

  Future<SearchPostsResponse> searchPosts({
    String? query,
    String? category,
    bool? verified,
    bool? recent,
    double? radiusKm,
    int page = 1,
    int limit = 20,
  }) async {
    final queryParams = <String, String>{
      if (query != null && query.trim().isNotEmpty) 'q': query.trim(),
      if (category != null && category.isNotEmpty) 'category': category,
      if (verified != null) 'verified': '$verified',
      if (recent != null) 'recent': '$recent',
      if (radiusKm != null && radiusKm > 0) 'radiusKm': '$radiusKm',
      'page': '$page',
      'limit': '$limit',
    };

    final uri = Uri(path: '/posts/search', queryParameters: queryParams);
    final response = await _request(
      (headers) => _apiClient.get(uri.toString(), headers: headers),
    );
    _checkStatus(response, 'Failed to search posts');
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final items = (data['items'] as List<dynamic>)
        .map((post) => PostModel.fromJson(post as Map<String, dynamic>))
        .toList();

    return SearchPostsResponse(
      items: items,
      page: (data['page'] as num?)?.toInt() ?? page,
      limit: (data['limit'] as num?)?.toInt() ?? limit,
      hasNextPage: data['hasNextPage'] as bool? ?? false,
    );
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

  Future<WitnessStatusModel> _updateWitness(
    String path,
    String fallback,
  ) async {
    final response = await _request(
      (headers) => _apiClient.post(path, headers: headers),
    );
    _checkStatus(response, fallback);
    return _parseWitnessStatus(response.body);
  }

  Future<List<CommentModel>> getComments(
    String postId, {
    int page = 1,
    int limit = 20,
  }) async {
    final response = await _request(
      (headers) => _apiClient.get(
        '/posts/$postId/comments?page=$page&limit=$limit',
        headers: headers,
      ),
    );
    _checkStatus(response, 'Failed to fetch comments');
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final list = data['items'] as List<dynamic>? ?? [];
    return list
        .map((item) => CommentModel.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<CommentModel> addComment(String postId, String content) async {
    final response = await _request(
      (headers) => _apiClient.post(
        '/posts/$postId/comments',
        headers: headers,
        body: {'content': content},
      ),
    );
    _checkStatus(response, 'Failed to add comment');
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return CommentModel.fromJson(data);
  }

  Future<void> deleteComment(String postId, String commentId) async {
    final response = await _request(
      (headers) => _apiClient.delete(
        '/posts/$postId/comments/$commentId',
        headers: headers,
      ),
    );
    _checkStatus(response, 'Failed to delete comment');
  }

  Future<void> reportComment(
    String postId,
    String commentId,
    CommentReportReason reason, {
    String? description,
  }) async {
    final body = <String, dynamic>{
      'reason': reason.wire,
      if (description != null && description.isNotEmpty)
        'description': description,
    };
    final response = await _request(
      (headers) => _apiClient.post(
        '/posts/$postId/comments/$commentId/report',
        headers: headers,
        body: body,
      ),
    );
    _checkStatus(response, 'Failed to report comment');
  }

  Future<CommentModel> createReply({
    required String postId,
    required String commentId,
    required String content,
  }) async {
    final response = await _request(
      (headers) => _apiClient.post(
        '/posts/$postId/comments/$commentId/replies',
        headers: headers,
        body: {'content': content},
      ),
    );
    _checkStatus(response, 'Failed to post reply');
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return CommentModel.fromJson(data);
  }

  Future<List<CommentModel>> getCommentReplies({
    required String postId,
    required String commentId,
    int page = 1,
    int limit = 20,
  }) async {
    final response = await _request(
      (headers) => _apiClient.get(
        '/posts/$postId/comments/$commentId/replies?page=$page&limit=$limit',
        headers: headers,
      ),
    );
    _checkStatus(response, 'Failed to fetch replies');
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final list = data['items'] as List<dynamic>? ?? [];
    return list
        .map((item) => CommentModel.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  WitnessStatusModel _parseWitnessStatus(String body) {
    final data = jsonDecode(body) as Map<String, dynamic>;
    return WitnessStatusModel.fromJson(
      data['witness'] as Map<String, dynamic>,
    );
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

class SearchPostsResponse {
  const SearchPostsResponse({
    required this.items,
    required this.page,
    required this.limit,
    required this.hasNextPage,
  });

  final List<PostModel> items;
  final int page;
  final int limit;
  final bool hasNextPage;
}
