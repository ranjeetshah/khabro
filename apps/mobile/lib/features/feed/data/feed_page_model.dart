import '../../posts/data/post_model.dart';

class FeedPageModel {
  const FeedPageModel({required this.items, required this.nextCursor});

  final List<PostModel> items;
  final String? nextCursor;

  factory FeedPageModel.fromJson(Map<String, dynamic> json) {
    return FeedPageModel(
      items: (json['items'] as List<dynamic>)
          .map((item) => PostModel.fromJson(item as Map<String, dynamic>))
          .toList(),
      nextCursor: json['nextCursor'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'items': items.map((item) => item.toJson()).toList(),
    'nextCursor': nextCursor,
  };
}
