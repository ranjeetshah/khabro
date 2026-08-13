class NotificationModel {
  const NotificationModel({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.referenceType,
    required this.referenceId,
    required this.isRead,
    required this.createdAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] as String? ?? '',
      type: json['type'] as String? ?? 'UNKNOWN',
      title: json['title'] as String? ?? '',
      body: json['body'] as String? ?? '',
      referenceType: json['referenceType'] as String? ?? 'CIVIC_COMPLAINT',
      referenceId: json['referenceId'] as String? ?? '',
      isRead: json['isRead'] as bool? ?? false,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
    );
  }

  final String id;
  final String type;
  final String title;
  final String body;
  final String referenceType;
  final String referenceId;
  final bool isRead;
  final DateTime createdAt;

  NotificationModel copyWith({bool? isRead}) {
    return NotificationModel(
      id: id,
      type: type,
      title: title,
      body: body,
      referenceType: referenceType,
      referenceId: referenceId,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt,
    );
  }
}
