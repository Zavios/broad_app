/// Route computed by the Maps API.
class ComputedRoute {
  final int distanceMeters;
  final String distanceKm;
  final String duration;
  final String? encodedPolyline;

  const ComputedRoute({
    required this.distanceMeters,
    required this.distanceKm,
    required this.duration,
    this.encodedPolyline,
  });

  factory ComputedRoute.fromJson(Map<String, dynamic> json) => ComputedRoute(
        distanceMeters: json['distanceMeters'] ?? 0,
        distanceKm: json['distanceKm'] ?? '0',
        duration: json['duration'] ?? '0s',
        encodedPolyline: json['encodedPolyline'] as String?,
      );
}

/// Geocoded location result.
class GeocodedLocation {
  final String formattedAddress;
  final double latitude;
  final double longitude;
  final String? placeId;

  const GeocodedLocation({
    required this.formattedAddress,
    required this.latitude,
    required this.longitude,
    this.placeId,
  });

  factory GeocodedLocation.fromJson(Map<String, dynamic> json) =>
      GeocodedLocation(
        formattedAddress: json['formatted_address'] ?? '',
        latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
        longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
        placeId: json['place_id'] as String?,
      );
}

/// Place autocomplete suggestion.
class PlaceSuggestion {
  final String placeId;
  final String mainText;
  final String secondaryText;
  final String fullText;

  const PlaceSuggestion({
    required this.placeId,
    required this.mainText,
    required this.secondaryText,
    required this.fullText,
  });

  factory PlaceSuggestion.fromJson(Map<String, dynamic> json) =>
      PlaceSuggestion(
        placeId: json['placeId'] ?? '',
        mainText: json['mainText'] ?? '',
        secondaryText: json['secondaryText'] ?? '',
        fullText: json['fullText'] ?? '',
      );
}

/// Distance result (no polyline).
class DistanceResult {
  final int distanceMeters;
  final String distanceKm;
  final String duration;

  const DistanceResult({
    required this.distanceMeters,
    required this.distanceKm,
    required this.duration,
  });

  factory DistanceResult.fromJson(Map<String, dynamic> json) => DistanceResult(
        distanceMeters: json['distanceMeters'] ?? 0,
        distanceKm: json['distanceKm'] ?? '0',
        duration: json['duration'] ?? '0s',
      );
}

/// Reverse geocode result.
class ReverseGeocodeResult {
  final String formattedAddress;
  final String? placeId;

  const ReverseGeocodeResult({
    required this.formattedAddress,
    this.placeId,
  });

  factory ReverseGeocodeResult.fromJson(Map<String, dynamic> json) =>
      ReverseGeocodeResult(
        formattedAddress: json['formatted_address'] ?? '',
        placeId: json['place_id'] as String?,
      );
}
