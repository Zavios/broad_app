import 'package:broad_app/models/ride_model.dart';
import 'package:broad_app/models/user_model.dart';

/// A tag-along booking on a ride.
class Booking {
  final int id;
  final String rideId;
  final String passengerId;
  final String? pickupStopId;
  final String? dropoffStopId;
  final int seatsBooked;
  final double totalAmount;
  final String status; // 'pending', 'confirmed', 'rejected', 'cancelled'
  final String? createdAt;
  final Ride? ride;
  final PublicProfile? passengerProfile;

  const Booking({
    required this.id,
    required this.rideId,
    required this.passengerId,
    this.pickupStopId,
    this.dropoffStopId,
    required this.seatsBooked,
    required this.totalAmount,
    required this.status,
    this.createdAt,
    this.ride,
    this.passengerProfile,
  });

  factory Booking.fromJson(Map<String, dynamic> json) {
    final rideJson = json['rides'];
    final profileJson = json['profiles'];

    return Booking(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      rideId: json['ride_id'] ?? '',
      passengerId: json['passenger_id'] ?? '',
      pickupStopId: json['pickup_stop_id'] as String?,
      dropoffStopId: json['dropoff_stop_id'] as String?,
      seatsBooked: json['seats_booked'] ?? 0,
      totalAmount: (json['total_amount'] as num?)?.toDouble() ?? 0.0,
      status: json['status'] ?? 'pending',
      createdAt: json['created_at'] as String?,
      ride: rideJson != null ? Ride.fromJson(rideJson as Map<String, dynamic>) : null,
      passengerProfile: profileJson != null
          ? PublicProfile.fromJson(profileJson as Map<String, dynamic>)
          : null,
    );
  }
}
