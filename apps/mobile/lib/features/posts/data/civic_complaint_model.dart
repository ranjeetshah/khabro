class CivicComplaintModel {
  const CivicComplaintModel({
    required this.referenceCode,
    required this.status,
    required this.witnessCount,
    this.sentAt,
  });

  factory CivicComplaintModel.fromJson(Map<String, dynamic> json) {
    return CivicComplaintModel(
      referenceCode: json['referenceCode'] as String,
      status: json['status'] as String,
      witnessCount: (json['witnessCount'] as num).toInt(),
      sentAt: json['sentAt'] == null
          ? null
          : DateTime.tryParse(json['sentAt'] as String),
    );
  }

  final String referenceCode;
  final String status;
  final int witnessCount;
  final DateTime? sentAt;
}
