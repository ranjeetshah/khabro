import '../../posts/data/post_model.dart';

class WitnessHistoryModel {
  const WitnessHistoryModel({
    required this.id,
    required this.createdAt,
    required this.post,
  });

  factory WitnessHistoryModel.fromJson(Map<String, dynamic> json) {
    return WitnessHistoryModel(
      id: json['id'] as String? ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
      post: PostModel.fromJson(json['post'] as Map<String, dynamic>),
    );
  }

  final String id;
  final DateTime createdAt;
  final PostModel post;
}
