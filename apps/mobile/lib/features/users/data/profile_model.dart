class ProfileStatsModel {
  const ProfileStatsModel({
    required this.postCount,
    required this.reportCount,
    required this.witnessCount,
    required this.verifiedContributionCount,
    this.followerCount = 0,
    this.followingCount = 0,
  });

  factory ProfileStatsModel.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return const ProfileStatsModel(
        postCount: 0,
        reportCount: 0,
        witnessCount: 0,
        verifiedContributionCount: 0,
        followerCount: 0,
        followingCount: 0,
      );
    }
    return ProfileStatsModel(
      postCount: (json['postCount'] as num?)?.toInt() ?? 0,
      reportCount: (json['reportCount'] as num?)?.toInt() ?? 0,
      witnessCount: (json['witnessCount'] as num?)?.toInt() ?? 0,
      verifiedContributionCount:
          (json['verifiedContributionCount'] as num?)?.toInt() ?? 0,
      followerCount: (json['followerCount'] as num?)?.toInt() ?? 0,
      followingCount: (json['followingCount'] as num?)?.toInt() ?? 0,
    );
  }

  final int postCount;
  final int reportCount;
  final int witnessCount;
  final int verifiedContributionCount;
  final int followerCount;
  final int followingCount;
}

class ProfileModel {
  const ProfileModel({
    required this.id,
    required this.phone,
    required this.name,
    required this.allowCivicComplaintContactSharing,
    required this.createdAt,
    required this.stats,
  });

  factory ProfileModel.fromJson(Map<String, dynamic> json) {
    return ProfileModel(
      id: json['id'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      name: json['name'] as String?,
      allowCivicComplaintContactSharing:
          json['allowCivicComplaintContactSharing'] as bool? ?? false,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
      stats: ProfileStatsModel.fromJson(
          json['stats'] as Map<String, dynamic>?),
    );
  }

  final String id;
  final String phone;
  final String? name;
  final bool allowCivicComplaintContactSharing;
  final DateTime createdAt;
  final ProfileStatsModel stats;
}
