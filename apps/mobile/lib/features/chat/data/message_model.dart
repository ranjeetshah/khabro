class MessageModel {
  const MessageModel({
    required this.id,
    this.conversationId,
    required this.senderId,
    this.content,
    required this.createdAt,
    required this.deleted,
  });

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    return MessageModel(
      id: json['id'] as String? ?? '',
      conversationId: json['conversationId'] as String?,
      senderId: json['senderId'] as String? ?? '',
      content: json['content'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
      deleted: json['deleted'] as bool? ?? false,
    );
  }

  final String id;
  final String? conversationId;
  final String senderId;
  final String? content;
  final DateTime createdAt;
  final bool deleted;
}

class MessageListResult {
  const MessageListResult({
    required this.items,
    required this.page,
    required this.limit,
    required this.total,
    required this.hasMore,
  });

  factory MessageListResult.fromJson(Map<String, dynamic> json) {
    final list = json['items'] as List<dynamic>? ?? [];
    return MessageListResult(
      items: list
          .map((item) => MessageModel.fromJson(item as Map<String, dynamic>))
          .toList(),
      page: (json['page'] as num?)?.toInt() ?? 1,
      limit: (json['limit'] as num?)?.toInt() ?? 20,
      total: (json['total'] as num?)?.toInt() ?? 0,
      hasMore: json['hasMore'] as bool? ?? false,
    );
  }

  final List<MessageModel> items;
  final int page;
  final int limit;
  final int total;
  final bool hasMore;
}