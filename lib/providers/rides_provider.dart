import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:broad_app/models/ride_model.dart';
import 'package:broad_app/models/booking_model.dart';
import 'package:broad_app/services/rides_service.dart';

// ─── Search Rides ────────────────────────────────────────────────────

class SearchRidesState {
  final bool isLoading;
  final List<Ride> rides;
  final String? error;

  const SearchRidesState({
    this.isLoading = false,
    this.rides = const [],
    this.error,
  });

  SearchRidesState copyWith({
    bool? isLoading,
    List<Ride>? rides,
    String? error,
  }) {
    return SearchRidesState(
      isLoading: isLoading ?? this.isLoading,
      rides: rides ?? this.rides,
      error: error,
    );
  }
}

class SearchRidesNotifier extends StateNotifier<SearchRidesState> {
  final RidesService _service = RidesService();

  SearchRidesNotifier() : super(const SearchRidesState());

  Future<void> search({
    String? status,
    int? minSeats,
    String? departureDate,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final rides = await _service.searchRides(
        status: status,
        minSeats: minSeats,
        departureDate: departureDate,
      );
      state = state.copyWith(isLoading: false, rides: rides);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: _extractError(e));
    }
  }

  void clear() => state = const SearchRidesState();

  String _extractError(dynamic e) {
    if (e is DioException && e.response?.data != null) {
      final data = e.response!.data;
      if (data is Map) return data['error']?.toString() ?? 'Unknown error';
    }
    return e.toString();
  }
}

final searchRidesProvider =
    StateNotifierProvider<SearchRidesNotifier, SearchRidesState>(
  (ref) => SearchRidesNotifier(),
);

// ─── My Published Rides ──────────────────────────────────────────────

class MyPublishedRidesState {
  final bool isLoading;
  final List<Ride> rides;
  final String? error;

  const MyPublishedRidesState({
    this.isLoading = false,
    this.rides = const [],
    this.error,
  });

  MyPublishedRidesState copyWith({
    bool? isLoading,
    List<Ride>? rides,
    String? error,
  }) {
    return MyPublishedRidesState(
      isLoading: isLoading ?? this.isLoading,
      rides: rides ?? this.rides,
      error: error,
    );
  }
}

class MyPublishedRidesNotifier extends StateNotifier<MyPublishedRidesState> {
  final RidesService _service = RidesService();

  MyPublishedRidesNotifier() : super(const MyPublishedRidesState());

  Future<void> fetch() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final rides = await _service.getMyPublishedRides();
      state = state.copyWith(isLoading: false, rides: rides);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: _extractError(e));
    }
  }

  void clear() => state = const MyPublishedRidesState();

  String _extractError(dynamic e) {
    if (e is DioException && e.response?.data != null) {
      final data = e.response!.data;
      if (data is Map) return data['error']?.toString() ?? 'Unknown error';
    }
    return e.toString();
  }
}

final myPublishedRidesProvider =
    StateNotifierProvider<MyPublishedRidesNotifier, MyPublishedRidesState>(
  (ref) => MyPublishedRidesNotifier(),
);

// ─── My Bookings (Passenger) ─────────────────────────────────────────

class MyBookingsState {
  final bool isLoading;
  final List<Booking> bookings;
  final String? error;

  const MyBookingsState({
    this.isLoading = false,
    this.bookings = const [],
    this.error,
  });

  MyBookingsState copyWith({
    bool? isLoading,
    List<Booking>? bookings,
    String? error,
  }) {
    return MyBookingsState(
      isLoading: isLoading ?? this.isLoading,
      bookings: bookings ?? this.bookings,
      error: error,
    );
  }
}

class MyBookingsNotifier extends StateNotifier<MyBookingsState> {
  final RidesService _service = RidesService();

  MyBookingsNotifier() : super(const MyBookingsState());

  Future<void> fetch() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final bookings = await _service.getMyBookings();
      state = state.copyWith(isLoading: false, bookings: bookings);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: _extractError(e));
    }
  }

  void clear() => state = const MyBookingsState();

  String _extractError(dynamic e) {
    if (e is DioException && e.response?.data != null) {
      final data = e.response!.data;
      if (data is Map) return data['error']?.toString() ?? 'Unknown error';
    }
    return e.toString();
  }
}

final myBookingsProvider =
    StateNotifierProvider<MyBookingsNotifier, MyBookingsState>(
  (ref) => MyBookingsNotifier(),
);

// ─── Publish Ride ────────────────────────────────────────────────────

class PublishRideState {
  final bool isLoading;
  final Ride? publishedRide;
  final String? error;

  const PublishRideState({
    this.isLoading = false,
    this.publishedRide,
    this.error,
  });

  PublishRideState copyWith({
    bool? isLoading,
    Ride? publishedRide,
    String? error,
  }) {
    return PublishRideState(
      isLoading: isLoading ?? this.isLoading,
      publishedRide: publishedRide ?? this.publishedRide,
      error: error,
    );
  }
}

class PublishRideNotifier extends StateNotifier<PublishRideState> {
  final RidesService _service = RidesService();

  PublishRideNotifier() : super(const PublishRideState());

  Future<bool> publish({
    required String vehicleId,
    required String departureAt,
    required int seatOffered,
    required double pricePerSeat,
    String currency = 'INR',
    String? routePolyline,
    String? description,
    required List<Map<String, dynamic>> stops,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final ride = await _service.publishRide(
        vehicleId: vehicleId,
        departureAt: departureAt,
        seatOffered: seatOffered,
        pricePerSeat: pricePerSeat,
        currency: currency,
        routePolyline: routePolyline,
        description: description,
        stops: stops,
      );
      state = state.copyWith(isLoading: false, publishedRide: ride);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: _extractError(e));
      return false;
    }
  }

  void clear() => state = const PublishRideState();

  String _extractError(dynamic e) {
    if (e is DioException && e.response?.data != null) {
      final data = e.response!.data;
      if (data is Map) return data['error']?.toString() ?? 'Unknown error';
    }
    return e.toString();
  }
}

final publishRideProvider =
    StateNotifierProvider<PublishRideNotifier, PublishRideState>(
  (ref) => PublishRideNotifier(),
);

// ─── Booking Actions ─────────────────────────────────────────────────

/// Simple provider for one-off booking actions.
final ridesServiceProvider = Provider<RidesService>((ref) => RidesService());
