import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Keys used in secure storage.
const kAccessTokenKey = 'access_token';
const kRefreshTokenKey = 'refresh_token';

/// Central Dio HTTP client with auth token injection.
class ApiClient {
  ApiClient._();

  static final ApiClient instance = ApiClient._();

  static const String _baseUrl = 'http://10.0.2.2:5000';

  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  late final Dio dio = _createDio();

  Dio _createDio() {
    final dio = Dio(
      BaseOptions(
        baseUrl: _baseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        headers: {
          'Content-Type': 'application/json',
        },
      ),
    );

    // Logging in debug mode
    if (kDebugMode) {
      dio.interceptors.add(LogInterceptor(
        requestBody: true,
        responseBody: true,
        logPrint: (obj) => debugPrint(obj.toString()),
      ));
    }

    // Auth interceptor — inject Bearer token
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // Skip token injection for public endpoints
          final publicPaths = [
            '/api/auth/signup',
            '/api/auth/signin',
            '/api/auth/google',
            '/api/auth/callback',
            '/api/auth/refresh',
          ];
          final isPublic = publicPaths.any(
            (p) => options.path.contains(p),
          );

          if (!isPublic) {
            final token = await _storage.read(key: kAccessTokenKey);
            if (token != null && token.isNotEmpty) {
              options.headers['Authorization'] = 'Bearer $token';
            }
          }
          handler.next(options);
        },
        onError: (error, handler) async {
          // If 401 and we have a refresh token, try to refresh
          if (error.response?.statusCode == 401) {
            final refreshToken = await _storage.read(key: kRefreshTokenKey);
            if (refreshToken != null && refreshToken.isNotEmpty) {
              try {
                final refreshDio = Dio(BaseOptions(baseUrl: _baseUrl));
                final response = await refreshDio.post(
                  '/api/auth/refresh',
                  data: {'refresh_token': refreshToken},
                );

                if (response.statusCode == 200) {
                  final newAccess = response.data['session']?['access_token'];
                  final newRefresh = response.data['session']?['refresh_token'];

                  if (newAccess != null) {
                    await _storage.write(key: kAccessTokenKey, value: newAccess);
                  }
                  if (newRefresh != null) {
                    await _storage.write(key: kRefreshTokenKey, value: newRefresh);
                  }

                  // Retry the original request with the new token
                  error.requestOptions.headers['Authorization'] =
                      'Bearer $newAccess';
                  final retryResponse = await dio.fetch(error.requestOptions);
                  return handler.resolve(retryResponse);
                }
              } catch (_) {
                // Refresh failed — let the error propagate
              }
            }
          }
          handler.next(error);
        },
      ),
    );

    return dio;
  }

  /// Save tokens to secure storage after login/signup.
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    await _storage.write(key: kAccessTokenKey, value: accessToken);
    await _storage.write(key: kRefreshTokenKey, value: refreshToken);
  }

  /// Clear stored tokens on sign-out.
  Future<void> clearTokens() async {
    await _storage.delete(key: kAccessTokenKey);
    await _storage.delete(key: kRefreshTokenKey);
  }

  /// Check if a token exists (for auto-login check).
  Future<bool> hasToken() async {
    final token = await _storage.read(key: kAccessTokenKey);
    return token != null && token.isNotEmpty;
  }

  /// Read the current access token.
  Future<String?> getAccessToken() async {
    return _storage.read(key: kAccessTokenKey);
  }

  /// Read the current refresh token.
  Future<String?> getRefreshToken() async {
    return _storage.read(key: kRefreshTokenKey);
  }
}
