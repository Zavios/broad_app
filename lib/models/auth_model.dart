/// Models for the Authentication module responses.

class AuthUser {
  final String id;
  final String email;
  final Map<String, dynamic>? userMetadata;
  final String? createdAt;

  const AuthUser({
    required this.id,
    required this.email,
    this.userMetadata,
    this.createdAt,
  });

  factory AuthUser.fromJson(Map<String, dynamic> json) => AuthUser(
        id: json['id'] ?? '',
        email: json['email'] ?? '',
        userMetadata: json['user_metadata'] as Map<String, dynamic>?,
        createdAt: json['created_at'] as String?,
      );

  String? get fullName => userMetadata?['full_name'] as String?;
}

class AuthSession {
  final String accessToken;
  final String tokenType;
  final int? expiresIn;
  final String refreshToken;

  const AuthSession({
    required this.accessToken,
    this.tokenType = 'bearer',
    this.expiresIn,
    required this.refreshToken,
  });

  factory AuthSession.fromJson(Map<String, dynamic> json) => AuthSession(
        accessToken: json['access_token'] ?? '',
        tokenType: json['token_type'] ?? 'bearer',
        expiresIn: json['expires_in'] as int?,
        refreshToken: json['refresh_token'] ?? '',
      );
}

class AuthResponse {
  final String message;
  final AuthUser? user;
  final AuthSession? session;

  const AuthResponse({
    required this.message,
    this.user,
    this.session,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) => AuthResponse(
        message: json['message'] ?? '',
        user: json['user'] != null ? AuthUser.fromJson(json['user']) : null,
        session: json['session'] != null
            ? AuthSession.fromJson(json['session'])
            : null,
      );
}
