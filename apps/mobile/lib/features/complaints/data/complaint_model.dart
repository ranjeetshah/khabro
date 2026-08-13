import 'complaint_status.dart';

/// A single step in a complaint's status timeline. Never contains identities,
/// coordinates, locality, or authority internals.
class ComplaintStatusHistoryModel {
  const ComplaintStatusHistoryModel({
    required this.toStatus,
    this.fromStatus,
    required this.createdAt,
  });

  final ComplaintStatus? fromStatus;
  final ComplaintStatus toStatus;
  final DateTime createdAt;

  factory ComplaintStatusHistoryModel.fromJson(Map<String, dynamic> json) {
    return ComplaintStatusHistoryModel(
      fromStatus: ComplaintStatus.fromWire(json['fromStatus'] as String?),
      toStatus: ComplaintStatus.fromWire(json['toStatus'] as String?),
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}

/// A complaint as shown in a list — safe public/citizen-visible fields only.
class ComplaintModel {
  const ComplaintModel({
    required this.id,
    required this.status,
    required this.description,
    required this.createdAt,
  });

  final String id;
  final ComplaintStatus status;
  final String description;
  final DateTime createdAt;

  factory ComplaintModel.fromJson(Map<String, dynamic> json) {
    return ComplaintModel(
      id: json['id'] as String,
      status: ComplaintStatus.fromWire(json['status'] as String?),
      description: json['description'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}

/// Full citizen-visible complaint detail. No database ids beyond the
/// complaint's own id, no locality, no coordinates, no authority internals.
class ComplaintDetailModel {
  const ComplaintDetailModel({
    required this.id,
    required this.status,
    required this.description,
    required this.createdAt,
    required this.updatedAt,
    required this.statusHistory,
    this.postContent,
  });

  final String id;
  final ComplaintStatus status;
  final String description;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? postContent;
  final List<ComplaintStatusHistoryModel> statusHistory;

  factory ComplaintDetailModel.fromJson(Map<String, dynamic> json) {
    final post = json['post'] as Map<String, dynamic>?;
    return ComplaintDetailModel(
      id: json['id'] as String,
      status: ComplaintStatus.fromWire(json['status'] as String?),
      description: json['description'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      postContent: post?['content'] as String?,
      statusHistory: (json['statusHistory'] as List<dynamic>? ?? [])
          .map(
            (entry) => ComplaintStatusHistoryModel.fromJson(
              entry as Map<String, dynamic>,
            ),
          )
          .toList(),
    );
  }
}

/// Minimal safe submission result — status is enough for confirmation.
class ComplaintSubmissionModel {
  const ComplaintSubmissionModel({
    required this.id,
    required this.status,
  });

  final String id;
  final ComplaintStatus status;

  factory ComplaintSubmissionModel.fromJson(Map<String, dynamic> json) {
    return ComplaintSubmissionModel(
      id: json['id'] as String,
      status: ComplaintStatus.fromWire(json['status'] as String?),
    );
  }
}
