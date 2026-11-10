import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:broad_app/models/auth_model.dart';
import 'package:broad_app/services/api_client.dart';
import 'package:broad_app/services/auth_service.dart';

/// Holds the current authentication state.
class AuthState {
  final bool isLoading;
  final bool isAuthenticated;
  final AuthUser? user;
  final String? error;

  const AuthState({
    this.isLoading = false,
    this.isAuthenticated = false,
    this.user,
    this.error,
  });

  AuthState copyWith({
    bool? isLoading,
    bool? isAuthenticated,
    AuthUser? user,
    String? error,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      user: user ?? this.user,
      error: error,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthService _authService = AuthService();
  final ApiClient _apiClient = ApiClient.instance;

  AuthNotifier() : super(const AuthState());

  /// Check if user has a stored token (auto-login).
  Future<void> checkAuthStatus() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final hasToken = await _apiClient.hasToken();
      if (hasToken) {
        final user = await _authService.getCurrentUser();
        state = state.copyWith(
          isLoading: false,
          isAuthenticated: true,
          user: user,
        );
      } else {
        state = state.copyWith(isLoading: false, isAuthenticated: false);
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        isAuthenticated: false,
        error: _extractError(e),
      );
    }
  }

  /// Sign up with email/password.
  Future<bool> signUp({
    required String email,
    required String password,
    String? name,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _authService.signUp(
        email: email,
        password: password,
        name: name,
      );
      // Sign-up may not return a session (email confirmation required)
      if (response.session != null) {
        await _apiClient.saveTokens(
          accessToken: response.session!.accessToken,
          refreshToken: response.session!.refreshToken,
        );
        state = state.copyWith(
          isLoading: false,
          isAuthenticated: true,
          user: response.user != null
              ? AuthUser(
                  id: response.user!.id,
                  email: response.user!.email,
                )
              : null,
        );
      } else {
        state = state.copyWith(isLoading: false);
      }
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: _extractError(e));
      return false;
    }
  }

  /// Sign in with email/password.
  Future<bool> signIn({
    required String email,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _authService.signIn(
        email: email,
        password: password,
      );
      if (response.session != null) {
        await _apiClient.saveTokens(
          accessToken: response.session!.accessToken,
          refreshToken: response.session!.refreshToken,
        );
      }
      state = state.copyWith(
        isLoading: false,
        isAuthenticated: true,
        user: response.user != null
            ? AuthUser(id: response.user!.id, email: response.user!.email)
            : null,
      );
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: _extractError(e));
      return false;
    }
  }

  /// Get Google OAuth URL.
  Future<String?> getGoogleOAuthUrl() async {
    try {
      return await _authService.getGoogleOAuthUrl();
    } catch (e) {
      state = state.copyWith(error: _extractError(e));
      return null;
    }
  }

  /// Handle OAuth callback code.
  Future<bool> handleOAuthCallback(String code) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _authService.handleOAuthCallback(code);
      if (response.session != null) {
        await _apiClient.saveTokens(
          accessToken: response.session!.accessToken,
          refreshToken: response.session!.refreshToken,
        );
      }
      state = state.copyWith(
        isLoading: false,
        isAuthenticated: true,
        user: response.user != null
            ? AuthUser(id: response.user!.id, email: response.user!.email)
            : null,
      );
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: _extractError(e));
      return false;
    }
  }

  /// Sign out.
  Future<void> signOut() async {
    try {
      await _authService.signOut();
    } catch (_) {
      // Even if API call fails, clear local tokens
    }
    await _apiClient.clearTokens();
    state = const AuthState();
  }

  String _extractError(dynamic e) {
    if (e is DioException && e.response?.data != null) {
      final data = e.response!.data;
      if (data is Map) {
        return data['error']?.toString() ?? e.message ?? 'Unknown error';
      }
    }
    return e.toString();
  }
}

/// Global auth state provider.
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>(
  (ref) => AuthNotifier(),
);
