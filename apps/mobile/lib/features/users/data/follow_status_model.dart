class FollowStatusModel {
  const FollowStatusModel({
    required this.following,
    required this.followerCount,
    required this.followingCount,
  });

  final bool following;
  final int followerCount;
  final int followingCount;

  factory FollowStatusModel.fromJson(Map<String, dynamic> json) {
    return FollowStatusModel(
      following: json['following'] as bool? ?? false,
      followerCount: (json['followerCount'] as num?)?.toInt() ?? 0,
      followingCount: (json['followingCount'] as num?)?.toInt() ?? 0,
    );
  }
}
