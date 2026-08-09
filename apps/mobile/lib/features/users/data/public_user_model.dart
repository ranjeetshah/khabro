class PublicUserModel {
  const PublicUserModel({required this.id, required this.name});

  final String id;
  final String? name;

  factory PublicUserModel.fromJson(Map<String, dynamic> json) {
    return PublicUserModel(
      id: json['id'] as String,
      name: json['name'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {'id': id, 'name': name};
}
