import 'package:broad_app/models/ride_stop_model.dart';
import 'package:broad_app/models/user_model.dart';

/// A published ride with its stops and driver profile.
class Ride {
  final String id;
  final String driverId;
  final String? vehicleId;
  final String departureAt; // YYYY-MM-DD
  final int seatOffered;
  final int seatAvailable;
  final double pricePerSeat;
  final String currency;
  final String? routePolyline;
  final String? description;
  final String status; // 'active', 'completed', 'cancelled'
  final String? createdAt;
  final List<RideStop> stops;
  final PublicProfile? driverProfile;

  const Ride({
    required this.id,
    required this.driverId,
    this.vehicleId,
    required this.departureAt,
    required this.seatOffered,
    required this.seatAvailable,
    required this.pricePerSeat,
    required this.currency,
    this.routePolyline,
    this.description,
    required this.status,
    this.createdAt,
    this.stops = const [],
    this.driverProfile,
  });

  factory Ride.fromJson(Map<String, dynamic> json) {
    final stopsJson = json['rides_stops'] ?? json['stops'] ?? [];
    final profileJson = json['profiles'];

    return Ride(
      id: json['id'] ?? '',
      driverId: json['driver_id'] ?? '',
      vehicleId: json['vehicle_id'] as String?,
      departureAt: json['departure_at'] ?? '',
      seatOffered: json['seat_offered'] ?? 0,
      seatAvailable: json['seat_available'] ?? 0,
      pricePerSeat: (json['price_per_seat'] as num?)?.toDouble() ?? 0.0,
      currency: json['currency'] ?? 'INR',
      routePolyline: json['route_polyline'] as String?,
      description: json['description'] as String?,
      status: json['status'] ?? 'active',
      createdAt: json['created_at'] as String?,
      stops: (stopsJson as List)
          .map((s) => RideStop.fromJson(s as Map<String, dynamic>))
          .toList(),
      driverProfile: profileJson != null
          ? PublicProfile.fromJson(profileJson as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'driver_id': driverId,
        'vehicle_id': vehicleId,
        'departure_at': departureAt,
        'seat_offered': seatOffered,
        'seat_available': seatAvailable,
        'price_per_seat': pricePerSeat,
        'currency': currency,
        'route_polyline': routePolyline,
        'description': description,
        'status': status,
      };

  /// Origin stop (first stop)
  RideStop? get origin =>
      stops.isNotEmpty ? stops.firstWhere((s) => s.stopType == 'origin', orElse: () => stops.first) : null;

  /// Destination stop (last stop)
  RideStop? get destination =>
      stops.isNotEmpty ? stops.firstWhere((s) => s.stopType == 'destination', orElse: () => stops.last) : null;

  Ride copyWith({
    String? id,
    String? driverId,
    String? vehicleId,
    String? departureAt,
    int? seatOffered,
    int? seatAvailable,
    double? pricePerSeat,
    String? currency,
    String? routePolyline,
    String? description,
    String? status,
    String? createdAt,
    List<RideStop>? stops,
    PublicProfile? driverProfile,
  }) {
    return Ride(
      id: id ?? this.id,
      driverId: driverId ?? this.driverId,
      vehicleId: vehicleId ?? this.vehicleId,
      departureAt: departureAt ?? this.departureAt,
      seatOffered: seatOffered ?? this.seatOffered,
      seatAvailable: seatAvailable ?? this.seatAvailable,
      pricePerSeat: pricePerSeat ?? this.pricePerSeat,
      currency: currency ?? this.currency,
      routePolyline: routePolyline ?? this.routePolyline,
      description: description ?? this.description,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      stops: stops ?? this.stops,
      driverProfile: driverProfile ?? this.driverProfile,
    );
  }
}
