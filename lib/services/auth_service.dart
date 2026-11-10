import 'package:dio/dio.dart';
import 'package:broad_app/models/auth_model.dart';
import 'package:broad_app/services/api_client.dart';

/// Service for all /api/auth endpoints.
class AuthService {
  final Dio _dio = ApiClient.instance.dio;

  /// POST /api/auth/signup
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    String? name,
  }) async {
    final response = await _dio.post('/api/auth/signup', data: {
      'email': email,
      'password': password,
      if (name != null) 'name': name,
    });
    return AuthResponse.fromJson(response.data);
  }

  /// POST /api/auth/signin
  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    final response = await _dio.post('/api/auth/signin', data: {
      'email': email,
      'password': password,
    });
    return AuthResponse.fromJson(response.data);
  }

  /// GET /api/auth/google
  Future<String> getGoogleOAuthUrl({String? redirectTo}) async {
    final response = await _dio.get('/api/auth/google', queryParameters: {
      if (redirectTo != null) 'redirect_to': redirectTo,
    });
    return response.data['url'] as String;
  }

  /// GET /api/auth/callback?code=...
  Future<AuthResponse> handleOAuthCallback(String code) async {
    final response = await _dio.get('/api/auth/callback', queryParameters: {
      'code': code,
    });
    return AuthResponse.fromJson(response.data);
  }

  /// POST /api/auth/refresh
  Future<AuthResponse> refreshSession(String refreshToken) async {
    final response = await _dio.post('/api/auth/refresh', data: {
      'refresh_token': refreshToken,
    });
    return AuthResponse.fromJson(response.data);
  }

  /// POST /api/auth/signout
  Future<void> signOut() async {
    await _dio.post('/api/auth/signout');
  }

  /// GET /api/auth/me
  Future<AuthUser> getCurrentUser() async {
    final response = await _dio.get('/api/auth/me');
    return AuthUser.fromJson(response.data['user']);
  }
}
