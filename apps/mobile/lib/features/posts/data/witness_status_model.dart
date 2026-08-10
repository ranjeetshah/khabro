import 'verification_status_model.dart';

class WitnessStatusModel {
  const WitnessStatusModel({
    required this.witnessCount,
    required this.witnessedByMe,
    this.verification,
  });

  final int witnessCount;
  final bool witnessedByMe;

  /// Optional verification metadata returned alongside witness responses.
  final VerificationStatusModel? verification;

  factory WitnessStatusModel.fromJson(Map<String, dynamic> json) {
    final verification = json['verification'];
    return WitnessStatusModel(
      witnessCount: json['witnessCount'] as int,
      witnessedByMe: json['witnessedByMe'] as bool,
      verification: verification == null
          ? null
          : VerificationStatusModel.fromJson(
              verification as Map<String, dynamic>,
            ),
    );
  }
}
