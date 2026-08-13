/// Represents a Khabro user as returned by the backend API.
class UserModel {
  const UserModel({
    required this.id,
    required this.phone,
    this.name,
    required this.trustScore,
    required this.status,
    this.role,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String phone;
  final String? name;
  final int trustScore;
  final String status;
  final String? role;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      phone: json['phone'] as String,
      name: json['name'] as String?,
      trustScore: json['trustScore'] as int,
      status: json['status'] as String,
      role: json['role'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'phone': phone,
      'name': name,
      'trustScore': trustScore,
      'status': status,
      if (role != null) 'role': role,
      if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
    };
  }

  /// Create a copy with updated fields.
  UserModel copyWith({
    String? id,
    String? phone,
    String? Function()? name,
    int? trustScore,
    String? status,
    String? role,
    DateTime? Function()? createdAt,
    DateTime? Function()? updatedAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      phone: phone ?? this.phone,
      name: name != null ? name() : this.name,
      trustScore: trustScore ?? this.trustScore,
      status: status ?? this.status,
      role: role ?? this.role,
      createdAt: createdAt != null ? createdAt() : this.createdAt,
      updatedAt: updatedAt != null ? updatedAt() : this.updatedAt,
    );
  }
}
