class LikeStatusModel {
  const LikeStatusModel({required this.likeCount, required this.likedByMe});

  final int likeCount;
  final bool likedByMe;

  factory LikeStatusModel.fromJson(Map<String, dynamic> json) {
    return LikeStatusModel(
      likeCount: json['likeCount'] as int,
      likedByMe: json['likedByMe'] as bool,
    );
  }
}
