/// A stop along a ride route.
class RideStop {
  final String id;
  final int stopOrder;
  final String stopType; // 'origin', 'stop', 'destination'
  final String locationName;
  final double latitude;
  final double longitude;
  final String? scheduledAt;
  final bool? allowPickup;
  final bool? allowDropoff;

  const RideStop({
    required this.id,
    required this.stopOrder,
    required this.stopType,
    required this.locationName,
    required this.latitude,
    required this.longitude,
    this.scheduledAt,
    this.allowPickup,
    this.allowDropoff,
  });

  factory RideStop.fromJson(Map<String, dynamic> json) => RideStop(
        id: json['id'] ?? '',
        stopOrder: json['stop_order'] ?? 0,
        stopType: json['stop_type'] ?? 'stop',
        locationName: json['location_name'] ?? '',
        latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
        longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
        scheduledAt: json['scheduled_at'] as String?,
        allowPickup: json['allow_pickup'] as bool?,
        allowDropoff: json['allow_dropoff'] as bool?,
      );

  Map<String, dynamic> toJson() => {
        'stop_order': stopOrder,
        'stop_type': stopType,
        'location_name': locationName,
        'latitude': latitude,
        'longitude': longitude,
        if (scheduledAt != null) 'scheduled_at': scheduledAt,
        if (allowPickup != null) 'allow_pickup': allowPickup,
        if (allowDropoff != null) 'allow_dropoff': allowDropoff,
      };
}
