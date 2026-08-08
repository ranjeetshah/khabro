/// Represents a Khabro user as returned by the backend API.
class UserModel {
  const UserModel({
    required this.id,
    required this.phone,
    this.name,
    required this.trustScore,
    required this.status,
  });

  final String id;
  final String phone;
  final String? name;
  final int trustScore;
  final String status;

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      phone: json['phone'] as String,
      name: json['name'] as String?,
      trustScore: json['trustScore'] as int,
      status: json['status'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'phone': phone,
      'name': name,
      'trustScore': trustScore,
      'status': status,
    };
  }
}
