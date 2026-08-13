class CivicComplaintHistoryItem {
  const CivicComplaintHistoryItem({
    this.fromStatus,
    required this.toStatus,
    this.note,
    required this.createdAt,
  });

  factory CivicComplaintHistoryItem.fromJson(Map<String, dynamic> json) {
    return CivicComplaintHistoryItem(
      fromStatus: json['fromStatus'] as String?,
      toStatus: json['toStatus'] as String,
      note: json['note'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  final String? fromStatus;
  final String toStatus;
  final String? note;
  final DateTime createdAt;
}
