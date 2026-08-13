enum FeedbackType {
  bug('Bug'),
  feedback('Feedback'),
  suggestion('Suggestion');

  const FeedbackType(this.wire);
  final String wire;

  static FeedbackType fromJson(String value) {
    return FeedbackType.values.firstWhere(
      (type) => type.wire.toLowerCase() == value.toLowerCase(),
      orElse: () => FeedbackType.feedback,
    );
  }
}

enum FeedbackStatus {
  open('Open'),
  reviewed('Reviewed'),
  resolved('Resolved');

  const FeedbackStatus(this.wire);
  final String wire;

  static FeedbackStatus fromJson(String value) {
    return FeedbackStatus.values.firstWhere(
      (status) => status.wire.toLowerCase() == value.toLowerCase(),
      orElse: () => FeedbackStatus.open,
    );
  }
}

class FeedbackModel {
  const FeedbackModel({
    required this.id,
    required this.type,
    required this.message,
    required this.status,
    required this.createdAt,
    this.appVersion,
    this.platform,
  });

  final String id;
  final FeedbackType type;
  final String message;
  final FeedbackStatus status;
  final DateTime createdAt;
  final String? appVersion;
  final String? platform;

  factory FeedbackModel.fromJson(Map<String, dynamic> json) {
    return FeedbackModel(
      id: json['id'] as String,
      type: FeedbackType.fromJson(json['type'] as String),
      message: json['message'] as String,
      status: FeedbackStatus.fromJson(json['status'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
      appVersion: json['appVersion'] as String?,
      platform: json['platform'] as String?,
    );
  }
}

class FeedbackPageModel {
  const FeedbackPageModel({
    required this.items,
    required this.page,
    required this.limit,
    required this.total,
    required this.hasMore,
  });

  final List<FeedbackModel> items;
  final int page;
  final int limit;
  final int total;
  final bool hasMore;

  factory FeedbackPageModel.fromJson(Map<String, dynamic> json) {
    return FeedbackPageModel(
      items: (json['items'] as List<dynamic>)
          .map((item) => FeedbackModel.fromJson(item as Map<String, dynamic>))
          .toList(),
      page: (json['page'] as num).toInt(),
      limit: (json['limit'] as num).toInt(),
      total: (json['total'] as num).toInt(),
      hasMore: json['hasMore'] as bool? ?? false,
    );
  }
}
