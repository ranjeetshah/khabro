class ModeratorCivicComplaintHistoryModel {
  const ModeratorCivicComplaintHistoryModel({
    required this.id,
    this.fromStatus,
    required this.toStatus,
    this.note,
    required this.createdAt,
  });

  factory ModeratorCivicComplaintHistoryModel.fromJson(Map<String, dynamic> json) {
    return ModeratorCivicComplaintHistoryModel(
      id: json['id'] as String? ?? '',
      fromStatus: json['fromStatus'] as String?,
      toStatus: json['toStatus'] as String,
      note: json['note'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  final String id;
  final String? fromStatus;
  final String toStatus;
  final String? note;
  final DateTime createdAt;
}

class ModeratorCivicComplaintModel {
  const ModeratorCivicComplaintModel({
    required this.id,
    required this.referenceCode,
    required this.status,
    required this.witnessCount,
    required this.createdAt,
    this.sentAt,
    this.updatedAt,
    this.statusHistory,
  });

  factory ModeratorCivicComplaintModel.fromJson(Map<String, dynamic> json) {
    final historyJson = json['statusHistory'] as List<dynamic>?;
    final history = historyJson
        ?.map((h) => ModeratorCivicComplaintHistoryModel.fromJson(h as Map<String, dynamic>))
        .toList();

    return ModeratorCivicComplaintModel(
      id: json['id'] as String,
      referenceCode: json['referenceCode'] as String,
      status: json['status'] as String,
      witnessCount: (json['witnessCount'] as num).toInt(),
      createdAt: DateTime.parse(json['createdAt'] as String),
      sentAt: json['sentAt'] == null ? null : DateTime.parse(json['sentAt'] as String),
      updatedAt: json['updatedAt'] == null ? null : DateTime.parse(json['updatedAt'] as String),
      statusHistory: history,
    );
  }

  final String id;
  final String referenceCode;
  final String status;
  final int witnessCount;
  final DateTime createdAt;
  final DateTime? sentAt;
  final DateTime? updatedAt;
  final List<ModeratorCivicComplaintHistoryModel>? statusHistory;
}
