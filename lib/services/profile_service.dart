import 'package:dio/dio.dart';
import 'package:broad_app/models/user_model.dart';
import 'package:broad_app/models/vehicle_model.dart';
import 'package:broad_app/services/api_client.dart';

/// Service for /api/profile and /api/profile/vehicle endpoints.
class ProfileService {
  final Dio _dio = ApiClient.instance.dio;

  // ─── Profile ───────────────────────────────────────────────────────

  /// POST /api/profile
  Future<UserProfile> createProfile({
    required String username,
    required String firstName,
    required String lastName,
    required String email,
    String? dob,
    int? phone,
    String? bio,
  }) async {
    final response = await _dio.post(
      '/api/profile',
      data: {
        'username': username,
        'firstName': firstName,
        'lastName': lastName,
        'email': email,
        if (dob != null) 'dob': dob,
        if (phone != null) 'phone': phone,
        if (bio != null) 'bio': bio,
      },
    );
    return UserProfile.fromJson(response.data['data']);
  }

  /// GET /api/profile/me
  Future<UserProfile> getMyProfile() async {
    final response = await _dio.get('/api/profile/me');
    return UserProfile.fromJson(response.data['data']);
  }

  /// Alias for getMyProfile
  Future<UserProfile> getProfile() => getMyProfile();

  /// GET /api/profile/:id
  Future<PublicProfile> getPublicProfile(String id) async {
    final response = await _dio.get('/api/profile/$id');
    return PublicProfile.fromJson(response.data['data']);
  }

  /// PATCH /api/profile
  Future<UserProfile> updateProfile(Map<String, dynamic> fields) async {
    final response = await _dio.patch('/api/profile', data: fields);
    return UserProfile.fromJson(response.data['data']);
  }

  /// Convenience method to update only phone number
  Future<UserProfile> updatePhone(int phone) => updateProfile({'phone': phone});

  // ─── Vehicles ──────────────────────────────────────────────────────

  /// POST /api/profile/vehicle
  Future<Vehicle> addVehicle({
    required String make,
    required String model,
    required String color,
    required String registrationNo,
    required int seatCapacity,
  }) async {
    final response = await _dio.post(
      '/api/profile/vehicle',
      data: {
        'make': make,
        'model': model,
        'color': color,
        'registration_no': registrationNo,
        'seat_capacity': seatCapacity,
      },
    );
    return Vehicle.fromJson(response.data['data']);
  }

  /// GET /api/profile/vehicle
  Future<List<Vehicle>> getMyVehicles() async {
    final response = await _dio.get('/api/profile/v/all');
    final list = response.data['data'] as List;
    return list.map((v) => Vehicle.fromJson(v)).toList();
  }

  /// Alias for getMyVehicles
  Future<List<Vehicle>> getVehicles() => getMyVehicles();

  /// PATCH /api/profile/vehicle/:vehicleId
  Future<Vehicle> updateVehicle(
    String vehicleId,
    Map<String, dynamic> fields,
  ) async {
    final response = await _dio.patch(
      '/api/profile/vehicle/$vehicleId',
      data: fields,
    );
    return Vehicle.fromJson(response.data['data']);
  }

  /// DELETE /api/profile/vehicle/:vehicleId
  Future<void> deleteVehicle(String vehicleId) async {
    await _dio.delete('/api/profile/vehicle/$vehicleId');
  }
}
