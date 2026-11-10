import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:broad_app/models/user_model.dart';
import 'package:broad_app/services/profile_service.dart';

/// State for the user's profile.
class ProfileState {
  final bool isLoading;
  final UserProfile? profile;
  final String? error;

  const ProfileState({
    this.isLoading = false,
    this.profile,
    this.error,
  });

  ProfileState copyWith({
    bool? isLoading,
    UserProfile? profile,
    String? error,
  }) {
    return ProfileState(
      isLoading: isLoading ?? this.isLoading,
      profile: profile ?? this.profile,
      error: error,
    );
  }
}

class ProfileNotifier extends StateNotifier<ProfileState> {
  final ProfileService _service = ProfileService();

  ProfileNotifier() : super(const ProfileState());

  /// Fetch the current user's profile.
  Future<void> fetchProfile() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final profile = await _service.getMyProfile();
      state = state.copyWith(isLoading: false, profile: profile);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: _extractError(e));
    }
  }

  /// Create a new profile.
  Future<bool> createProfile({
    required String username,
    required String firstName,
    required String lastName,
    required String email,
    String? dob,
    int? phone,
    String? bio,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final profile = await _service.createProfile(
        username: username,
        firstName: firstName,
        lastName: lastName,
        email: email,
        dob: dob,
        phone: phone,
        bio: bio,
      );
      state = state.copyWith(isLoading: false, profile: profile);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: _extractError(e));
      return false;
    }
  }

  /// Update the current user's profile.
  Future<bool> updateProfile(Map<String, dynamic> fields) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final profile = await _service.updateProfile(fields);
      state = state.copyWith(isLoading: false, profile: profile);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: _extractError(e));
      return false;
    }
  }

  /// Clear the profile (on sign-out).
  void clear() {
    state = const ProfileState();
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

final profileProvider = StateNotifierProvider<ProfileNotifier, ProfileState>(
  (ref) => ProfileNotifier(),
);
