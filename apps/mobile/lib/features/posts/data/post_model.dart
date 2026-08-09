class PostModel {
  const PostModel({
    required this.id,
    required this.authorId,
    required this.localityId,
    required this.content,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String authorId;
  final String? localityId;
  final String content;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory PostModel.fromJson(Map<String, dynamic> json) {
    return PostModel(
      id: json['id'] as String,
      authorId: json['authorId'] as String,
      localityId: json['localityId'] as String?,
      content: json['content'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'authorId': authorId,
    'localityId': localityId,
    'content': content,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };
}
