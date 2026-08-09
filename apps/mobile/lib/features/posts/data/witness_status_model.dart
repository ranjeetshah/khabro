class WitnessStatusModel {
  const WitnessStatusModel({
    required this.witnessCount,
    required this.witnessedByMe,
  });

  final int witnessCount;
  final bool witnessedByMe;

  factory WitnessStatusModel.fromJson(Map<String, dynamic> json) {
    return WitnessStatusModel(
      witnessCount: json['witnessCount'] as int,
      witnessedByMe: json['witnessedByMe'] as bool,
    );
  }
}
