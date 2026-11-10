/// Data collected across the multi-step "post a ride" flow.
///
/// Each page in the flow reads what it needs and adds its own fields
/// before passing the object to the next page.
class PostRideData {
  /// Starting location entered on PostPage.
  final String from;

  /// Destination entered on PostPage.
  final String to;

  /// Latitude of the origin stop (populated via geocoding).
  final double? fromLat;

  /// Longitude of the origin stop.
  final double? fromLng;

  /// Latitude of the destination stop.
  final double? toLat;

  /// Longitude of the destination stop.
  final double? toLng;

  /// Departure date & time chosen on PostPage.
  final DateTime dateTime;

  /// Initial passenger count from PostPage.
  final int passengers;

  /// Route index (0-3) selected on RoutesPage.
  final int? selectedRoute;

  /// Encoded polyline of the selected route (from RoutesPage).
  final String? routePolyline;

  /// Passenger count refined on FareAndPassengerPage.
  final int? passengerCount;

  /// Per-passenger fare set on FareAndPassengerPage.
  final int? passengerFare;

  /// Vehicle chosen for the ride on FareAndPassengerPage.
  final String? vehicle;

  const PostRideData({
    required this.from,
    required this.to,
    this.fromLat,
    this.fromLng,
    this.toLat,
    this.toLng,
    required this.dateTime,
    required this.passengers,
    this.selectedRoute,
    this.routePolyline,
    this.passengerCount,
    this.passengerFare,
    this.vehicle,
  });

  /// Returns a copy with the given fields replaced.
  PostRideData copyWith({
    String? from,
    String? to,
    double? fromLat,
    double? fromLng,
    double? toLat,
    double? toLng,
    DateTime? dateTime,
    int? passengers,
    int? selectedRoute,
    String? routePolyline,
    int? passengerCount,
    int? passengerFare,
    String? vehicle,
  }) {
    return PostRideData(
      from: from ?? this.from,
      to: to ?? this.to,
      fromLat: fromLat ?? this.fromLat,
      fromLng: fromLng ?? this.fromLng,
      toLat: toLat ?? this.toLat,
      toLng: toLng ?? this.toLng,
      dateTime: dateTime ?? this.dateTime,
      passengers: passengers ?? this.passengers,
      selectedRoute: selectedRoute ?? this.selectedRoute,
      routePolyline: routePolyline ?? this.routePolyline,
      passengerCount: passengerCount ?? this.passengerCount,
      passengerFare: passengerFare ?? this.passengerFare,
      vehicle: vehicle ?? this.vehicle,
    );
  }

  @override
  String toString() =>
      'PostRideData(from: $from, to: $to, dateTime: $dateTime, '
      'passengers: $passengers, selectedRoute: $selectedRoute, '
      'passengerCount: $passengerCount, passengerFare: $passengerFare, '
      'vehicle: $vehicle)';
}
