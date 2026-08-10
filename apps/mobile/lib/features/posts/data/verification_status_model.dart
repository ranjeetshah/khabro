import 'verification_status.dart';

/// Public verification metadata returned by GET /posts/:id/verification.
///
/// Contains only the safe status plus witness count — never witness
/// identities, coordinates, or other private data.
class VerificationStatusModel {
  const VerificationStatusModel({
    required this.status,
    required this.witnessCount,
  });

  final VerificationStatus status;
  final int witnessCount;

  factory VerificationStatusModel.fromJson(Map<String, dynamic> json) {
    return VerificationStatusModel(
      status: VerificationStatus.fromWire(json['status'] as String?),
      witnessCount: json['witnessCount'] as int? ?? 0,
    );
  }
}
