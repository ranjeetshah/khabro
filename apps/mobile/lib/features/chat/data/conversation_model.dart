class ConversationParticipant {
  const ConversationParticipant({required this.id, required this.name});

  factory ConversationParticipant.fromJson(Map<String, dynamic> json) {
    return ConversationParticipant(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? 'Anonymous',
    );
  }

  final String id;
  final String name;
}

class LastMessagePreview {
  const LastMessagePreview({
    required this.id,
    this.content,
    required this.createdAt,
    required this.senderId,
  });

  factory LastMessagePreview.fromJson(Map<String, dynamic> json) {
    return LastMessagePreview(
      id: json['id'] as String? ?? '',
      content: json['content'] as String? ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
      senderId: json['senderId'] as String? ?? '',
    );
  }

  final String id;
  final String? content;
  final DateTime createdAt;
  final String senderId;
}

class ConversationModel {
  const ConversationModel({
    required this.id,
    required this.participant,
    this.lastMessage,
    required this.unreadCount,
    required this.updatedAt,
  });

  factory ConversationModel.fromJson(Map<String, dynamic> json) {
    final participantJson = json['participant'] as Map<String, dynamic>?;
    final lastMessageJson = json['lastMessage'] as Map<String, dynamic>?;
    return ConversationModel(
      id: json['id'] as String? ?? '',
      participant: participantJson != null
          ? ConversationParticipant.fromJson(participantJson)
          : const ConversationParticipant(id: '', name: 'Anonymous'),
      lastMessage: lastMessageJson != null
          ? LastMessagePreview.fromJson(lastMessageJson)
          : null,
      unreadCount: (json['unreadCount'] as num?)?.toInt() ?? 0,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : DateTime.now(),
    );
  }

  final String id;
  final ConversationParticipant participant;
  final LastMessagePreview? lastMessage;
  final int unreadCount;
  final DateTime updatedAt;
}

class ConversationListResult {
  const ConversationListResult({
    required this.items,
    required this.page,
    required this.limit,
    required this.total,
    required this.hasMore,
  });

  factory ConversationListResult.fromJson(Map<String, dynamic> json) {
    final list = json['items'] as List<dynamic>? ?? [];
    return ConversationListResult(
      items: list
          .map((item) => ConversationModel.fromJson(item as Map<String, dynamic>))
          .toList(),
      page: (json['page'] as num?)?.toInt() ?? 1,
      limit: (json['limit'] as num?)?.toInt() ?? 20,
      total: (json['total'] as num?)?.toInt() ?? 0,
      hasMore: json['hasMore'] as bool? ?? false,
    );
  }

  final List<ConversationModel> items;
  final int page;
  final int limit;
  final int total;
  final bool hasMore;
}

class StartedConversation {
  const StartedConversation({required this.id, required this.participant});

  factory StartedConversation.fromJson(Map<String, dynamic> json) {
    final participantJson = json['participant'] as Map<String, dynamic>?;
    return StartedConversation(
      id: json['id'] as String? ?? '',
      participant: participantJson != null
          ? ConversationParticipant.fromJson(participantJson)
          : const ConversationParticipant(id: '', name: 'Anonymous'),
    );
  }

  final String id;
  final ConversationParticipant participant;
}

class ConversationDetail {
  const ConversationDetail({required this.id, required this.participant});

  factory ConversationDetail.fromJson(Map<String, dynamic> json) {
    final participantJson = json['participant'] as Map<String, dynamic>?;
    return ConversationDetail(
      id: json['id'] as String? ?? '',
      participant: participantJson != null
          ? ConversationParticipant.fromJson(participantJson)
          : const ConversationParticipant(id: '', name: 'Anonymous'),
    );
  }

  final String id;
  final ConversationParticipant participant;
}