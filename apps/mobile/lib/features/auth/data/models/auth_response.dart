import 'user_model.dart';

/// Represents the response from /auth/register and /auth/dev-login.
class AuthResponse {
  const AuthResponse({
    required this.accessToken,
    required this.user,
  });

  final String accessToken;
  final UserModel user;

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      accessToken: json['accessToken'] as String,
      user: UserModel.fromJson(json['user'] as Map<String, dynamic>),
    );
  }
}
