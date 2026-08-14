import '../../users/data/public_user_model.dart';
import 'post_background.dart';
import 'post_media_model.dart';
import 'verification_status.dart';

class PostModel {
  const PostModel({
    required this.id,
    required this.authorId,
    required this.localityId,
    required this.content,
    required this.createdAt,
    required this.updatedAt,
    this.author,
    this.likeCount,
    this.likedByMe,
    this.witnessCount,
    this.witnessedByMe,
    this.commentCount,
    this.verificationStatus = VerificationStatus.reported,
    this.category,
    this.background = PostBackground.defaultColor,
    this.linkUrl,
    this.media = const [],
  });

  final String id;
  final String authorId;
  final String? localityId;
  final String content;
  final DateTime createdAt;
  final DateTime updatedAt;
  final PublicUserModel? author;
  final int? likeCount;
  final bool? likedByMe;
  final int? witnessCount;
  final bool? witnessedByMe;
  final int? commentCount;
  final VerificationStatus verificationStatus;
  final String? category;
  final PostBackground background;
  final String? linkUrl;
  final List<PostMediaModel> media;

  factory PostModel.fromJson(Map<String, dynamic> json) {
    final rawMedia = json['media'];
    final parsedMedia = (rawMedia is List)
        ? rawMedia
            .map((e) => PostMediaModel.fromJson(e as Map<String, dynamic>))
            .toList()
        : <PostMediaModel>[];

    return PostModel(
      id: json['id'] as String,
      authorId: json['authorId'] as String,
      localityId: json['localityId'] as String?,
      content: json['content'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      author: json['author'] == null
          ? null
          : PublicUserModel.fromJson(json['author'] as Map<String, dynamic>),
      likeCount: json['likeCount'] as int?,
      likedByMe: json['likedByMe'] as bool?,
      witnessCount: json['witnessCount'] as int?,
      witnessedByMe: json['witnessedByMe'] as bool?,
      commentCount: json['commentCount'] as int?,
      verificationStatus: PostModel._safeVerificationStatus(
        json['verificationStatus'] as String?,
      ),
      category: json['category'] as String?,
      background: PostBackground.fromWire(json['background'] as String?),
      linkUrl: json['linkUrl'] as String?,
      media: parsedMedia,
    );
  }

  static VerificationStatus _safeVerificationStatus(String? value) {
    final parsed = VerificationStatus.fromWire(value);
    return parsed == VerificationStatus.unknown
        ? VerificationStatus.reported
        : parsed;
  }

  PostModel copyWith({
    int? likeCount,
    bool? likedByMe,
    int? witnessCount,
    bool? witnessedByMe,
    int? commentCount,
    VerificationStatus? verificationStatus,
    PostBackground? background,
    String? linkUrl,
    List<PostMediaModel>? media,
  }) {
    return PostModel(
      id: id,
      authorId: authorId,
      localityId: localityId,
      content: content,
      createdAt: createdAt,
      updatedAt: updatedAt,
      author: author,
      likeCount: likeCount ?? this.likeCount,
      likedByMe: likedByMe ?? this.likedByMe,
      witnessCount: witnessCount ?? this.witnessCount,
      witnessedByMe: witnessedByMe ?? this.witnessedByMe,
      commentCount: commentCount ?? this.commentCount,
      verificationStatus: verificationStatus ?? this.verificationStatus,
      category: category,
      background: background ?? this.background,
      linkUrl: linkUrl ?? this.linkUrl,
      media: media ?? this.media,
    );
  }

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{
      'id': id,
      'authorId': authorId,
      'localityId': localityId,
      'content': content,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
    if (author != null) json['author'] = author!.toJson();
    if (likeCount != null) json['likeCount'] = likeCount;
    if (likedByMe != null) json['likedByMe'] = likedByMe;
    if (witnessCount != null) json['witnessCount'] = witnessCount;
    if (witnessedByMe != null) json['witnessedByMe'] = witnessedByMe;
    if (commentCount != null) json['commentCount'] = commentCount;
    if (verificationStatus != VerificationStatus.reported) {
      json['verificationStatus'] = verificationStatus.wire;
    }
    if (category != null) json['category'] = category;
    if (!background.isDefault) json['background'] = background.wire;
    if (linkUrl != null) json['linkUrl'] = linkUrl;
    if (media.isNotEmpty) {
      json['media'] = media.map((m) => m.toJson()).toList();
    }
    return json;
  }
}
