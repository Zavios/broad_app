import 'package:dio/dio.dart';
import 'package:broad_app/models/ride_model.dart';
import 'package:broad_app/models/booking_model.dart';
import 'package:broad_app/services/api_client.dart';

/// Service for /api/rides endpoints.
class RidesService {
  final Dio _dio = ApiClient.instance.dio;

  // ─── Rides ─────────────────────────────────────────────────────────

  /// GET /api/rides/search
  Future<List<Ride>> searchRides({
    String? status,
    int? minSeats,
    String? departureDate,
  }) async {
    final response = await _dio.get('/api/rides/search', queryParameters: {
      if (status != null) 'status': status,
      if (minSeats != null) 'min_seats': minSeats,
      if (departureDate != null) 'departure_date': departureDate,
    });
    final list = response.data['data'] as List;
    return list.map((r) => Ride.fromJson(r)).toList();
  }

  /// GET /api/rides/my/published
  Future<List<Ride>> getMyPublishedRides() async {
    final response = await _dio.get('/api/rides/my/published');
    final list = response.data['data'] as List;
    return list.map((r) => Ride.fromJson(r)).toList();
  }

  /// GET /api/rides/my/bookings
  Future<List<Booking>> getMyBookings() async {
    final response = await _dio.get('/api/rides/my/bookings');
    final list = response.data['data'] as List;
    return list.map((b) => Booking.fromJson(b)).toList();
  }

  /// POST /api/rides  — Publish a ride with stops
  Future<Ride> publishRide({
    required String vehicleId,
    required String departureAt,
    required int seatOffered,
    required double pricePerSeat,
    String currency = 'INR',
    String? routePolyline,
    String? description,
    required List<Map<String, dynamic>> stops,
  }) async {
    final response = await _dio.post('/api/rides', data: {
      'vehicle_id': vehicleId,
      'departure_at': departureAt,
      'seat_offered': seatOffered,
      'price_per_seat': pricePerSeat,
      'currency': currency,
      if (routePolyline != null) 'route_polyline': routePolyline,
      if (description != null) 'description': description,
      'stops': stops,
    });
    return Ride.fromJson(response.data['data']);
  }

  /// GET /api/rides/:rideId
  Future<Ride> getRideById(String rideId) async {
    final response = await _dio.get('/api/rides/$rideId');
    return Ride.fromJson(response.data['data']);
  }

  /// PATCH /api/rides/:rideId
  Future<Ride> updateRide(
      String rideId, Map<String, dynamic> fields) async {
    final response =
        await _dio.patch('/api/rides/$rideId', data: fields);
    return Ride.fromJson(response.data['data']);
  }

  /// POST /api/rides/:rideId/cancel
  Future<void> cancelRide(String rideId) async {
    await _dio.post('/api/rides/$rideId/cancel');
  }

  // ─── Bookings ──────────────────────────────────────────────────────

  /// POST /api/rides/:rideId/book
  Future<Booking> bookRide({
    required String rideId,
    required String pickupStopId,
    required String dropoffStopId,
    required int seatsBooked,
  }) async {
    final response = await _dio.post('/api/rides/$rideId/book', data: {
      'pickup_stop_id': pickupStopId,
      'dropoff_stop_id': dropoffStopId,
      'seats_booked': seatsBooked,
    });
    return Booking.fromJson(response.data['data']);
  }

  /// GET /api/rides/:rideId/bookings (driver view)
  Future<List<Booking>> getRideBookings(String rideId) async {
    final response = await _dio.get('/api/rides/$rideId/bookings');
    final list = response.data['data'] as List;
    return list.map((b) => Booking.fromJson(b)).toList();
  }

  /// PATCH /api/rides/:rideId/booking/:bookingId
  Future<Booking> respondToBooking({
    required String rideId,
    required int bookingId,
    required String action, // 'confirm' or 'reject'
  }) async {
    final response = await _dio.patch(
      '/api/rides/$rideId/booking/$bookingId',
      data: {'action': action},
    );
    return Booking.fromJson(response.data['data']);
  }

  /// POST /api/rides/:rideId/booking/:bookingId/cancel
  Future<void> cancelBooking({
    required String rideId,
    required int bookingId,
  }) async {
    await _dio.post('/api/rides/$rideId/booking/$bookingId/cancel');
  }
}
