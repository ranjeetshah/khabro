class MyReportModel {
  const MyReportModel({
    required this.id,
    required this.type,
    required this.reason,
    this.description,
    required this.status,
    required this.createdAt,
    this.targetPostId,
    this.targetContentSnippet,
    this.targetUserId,
    this.targetUserName,
  });

  factory MyReportModel.fromJson(Map<String, dynamic> json) {
    return MyReportModel(
      id: json['id'] as String? ?? '',
      type: json['type'] as String? ?? 'POST',
      reason: json['reason'] as String? ?? '',
      description: json['description'] as String?,
      status: json['status'] as String? ?? 'OPEN',
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
      targetPostId: json['targetPostId'] as String?,
      targetContentSnippet: json['targetContentSnippet'] as String?,
      targetUserId: json['targetUserId'] as String?,
      targetUserName: json['targetUserName'] as String?,
    );
  }

  final String id;
  final String type;
  final String reason;
  final String? description;
  final String status;
  final DateTime createdAt;
  final String? targetPostId;
  final String? targetContentSnippet;
  final String? targetUserId;
  final String? targetUserName;
}
