import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:broad_app/models/vehicle_model.dart';
import 'package:broad_app/services/profile_service.dart';

class VehicleState {
  final bool isLoading;
  final List<Vehicle> vehicles;
  final String? error;

  const VehicleState({
    this.isLoading = false,
    this.vehicles = const [],
    this.error,
  });

  VehicleState copyWith({
    bool? isLoading,
    List<Vehicle>? vehicles,
    String? error,
  }) {
    return VehicleState(
      isLoading: isLoading ?? this.isLoading,
      vehicles: vehicles ?? this.vehicles,
      error: error,
    );
  }
}

class VehicleNotifier extends StateNotifier<VehicleState> {
  final ProfileService _service = ProfileService();

  VehicleNotifier() : super(const VehicleState());

  /// Fetch user's vehicles.
  Future<void> fetchVehicles() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final vehicles = await _service.getMyVehicles();
      state = state.copyWith(isLoading: false, vehicles: vehicles);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: _extractError(e));
    }
  }

  /// Add a new vehicle.
  Future<bool> addVehicle({
    required String make,
    required String model,
    required String color,
    required String registrationNo,
    required int seatCapacity,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final vehicle = await _service.addVehicle(
        make: make,
        model: model,
        color: color,
        registrationNo: registrationNo,
        seatCapacity: seatCapacity,
      );
      state = state.copyWith(
        isLoading: false,
        vehicles: [...state.vehicles, vehicle],
      );
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: _extractError(e));
      return false;
    }
  }

  /// Update a vehicle.
  Future<bool> updateVehicle(
      String vehicleId, Map<String, dynamic> fields) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final updated = await _service.updateVehicle(vehicleId, fields);
      state = state.copyWith(
        isLoading: false,
        vehicles: state.vehicles
            .map((v) => v.id == vehicleId ? updated : v)
            .toList(),
      );
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: _extractError(e));
      return false;
    }
  }

  /// Delete a vehicle.
  Future<bool> deleteVehicle(String vehicleId) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _service.deleteVehicle(vehicleId);
      state = state.copyWith(
        isLoading: false,
        vehicles: state.vehicles.where((v) => v.id != vehicleId).toList(),
      );
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: _extractError(e));
      return false;
    }
  }

  /// Clear on sign-out.
  void clear() {
    state = const VehicleState();
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

final vehicleProvider = StateNotifierProvider<VehicleNotifier, VehicleState>(
  (ref) => VehicleNotifier(),
);
