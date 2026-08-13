class AccountSuggestionModel {
  const AccountSuggestionModel({
    required this.id,
    required this.name,
    this.followerCount = 0,
    this.followingCount = 0,
    this.reason,
  });

  final String id;
  final String? name;
  final int followerCount;
  final int followingCount;
  final String? reason;

  factory AccountSuggestionModel.fromJson(Map<String, dynamic> json) {
    return AccountSuggestionModel(
      id: json['id'] as String? ?? '',
      name: json['name'] as String?,
      followerCount: (json['followerCount'] as num?)?.toInt() ?? 0,
      followingCount: (json['followingCount'] as num?)?.toInt() ?? 0,
      reason: json['reason'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'followerCount': followerCount,
        'followingCount': followingCount,
        'reason': reason,
      };
}
