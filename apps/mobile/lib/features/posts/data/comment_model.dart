class CommentModel {
  const CommentModel({
    required this.id,
    required this.content,
    required this.createdAt,
    required this.authorId,
    required this.authorName,
  });

  factory CommentModel.fromJson(Map<String, dynamic> json) {
    final author = json['author'] as Map<String, dynamic>? ?? {};
    return CommentModel(
      id: json['id'] as String? ?? '',
      content: json['content'] as String? ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
      authorId: author['id'] as String? ?? '',
      authorName: author['name'] as String? ?? 'Anonymous',
    );
  }

  final String id;
  final String content;
  final DateTime createdAt;
  final String authorId;
  final String authorName;
}
