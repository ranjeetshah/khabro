class ModeratorReportModel {
  const ModeratorReportModel({
    required this.id,
    required this.type,
    required this.reason,
    this.description,
    required this.status,
    required this.createdAt,
    required this.targetId,
    required this.targetTitle,
  });

  factory ModeratorReportModel.fromJson(Map<String, dynamic> json) {
    final target = json['target'] as Map<String, dynamic>?;
    return ModeratorReportModel(
      id: json['id'] as String,
      type: json['type'] as String,
      reason: json['reason'] as String,
      description: json['description'] as String?,
      status: json['status'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      targetId: target?['id'] as String? ?? '',
      targetTitle: target?['title'] as String? ?? '',
    );
  }

  final String id;
  final String type;
  final String reason;
  final String? description;
  final String status;
  final DateTime createdAt;
  final String targetId;
  final String targetTitle;
}

class ModeratorReportDetailModel {
  const ModeratorReportDetailModel({
    required this.id,
    required this.type,
    required this.reason,
    this.description,
    required this.status,
    required this.createdAt,
    this.postContent,
    this.postVerificationStatus,
    this.postWitnessCount,
    this.postAuthorName,
    this.reportedUserName,
    this.reportedUserStatus,
    this.reportedUserRole,
    this.commentContent,
    this.commentAuthorName,
    this.commentPostContent,
  });

  factory ModeratorReportDetailModel.fromJson(Map<String, dynamic> json) {
    final type = json['type'] as String;

    String? postContent;
    String? postVerificationStatus;
    int? postWitnessCount;
    String? postAuthorName;
    String? reportedUserName;
    String? reportedUserStatus;
    String? reportedUserRole;
    String? commentContent;
    String? commentAuthorName;
    String? commentPostContent;

    if (type == 'POST') {
      final post = json['post'] as Map<String, dynamic>?;
      postContent = post?['content'] as String?;
      postVerificationStatus = post?['verificationStatus'] as String?;
      postWitnessCount = (post?['witnessCount'] as num?)?.toInt();
      final author = post?['author'] as Map<String, dynamic>?;
      postAuthorName = author?['name'] as String?;
    } else if (type == 'USER') {
      final ru = json['reportedUser'] as Map<String, dynamic>?;
      reportedUserName = ru?['name'] as String?;
      reportedUserStatus = ru?['status'] as String?;
      reportedUserRole = ru?['role'] as String?;
    } else if (type == 'COMMENT') {
      final comment = json['comment'] as Map<String, dynamic>?;
      commentContent = comment?['content'] as String?;
      commentAuthorName = comment?['authorName'] as String?;
      final cp = comment?['post'] as Map<String, dynamic>?;
      commentPostContent = cp?['content'] as String?;
    }

    return ModeratorReportDetailModel(
      id: json['id'] as String,
      type: type,
      reason: json['reason'] as String,
      description: json['description'] as String?,
      status: json['status'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      postContent: postContent,
      postVerificationStatus: postVerificationStatus,
      postWitnessCount: postWitnessCount,
      postAuthorName: postAuthorName,
      reportedUserName: reportedUserName,
      reportedUserStatus: reportedUserStatus,
      reportedUserRole: reportedUserRole,
      commentContent: commentContent,
      commentAuthorName: commentAuthorName,
      commentPostContent: commentPostContent,
    );
  }

  final String id;
  final String type;
  final String reason;
  final String? description;
  final String status;
  final DateTime createdAt;

  // Post Report specific
  final String? postContent;
  final String? postVerificationStatus;
  final int? postWitnessCount;
  final String? postAuthorName;

  // User Report specific
  final String? reportedUserName;
  final String? reportedUserStatus;
  final String? reportedUserRole;

  // Comment Report specific
  final String? commentContent;
  final String? commentAuthorName;
  final String? commentPostContent;
}
