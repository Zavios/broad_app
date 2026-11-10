import 'package:dio/dio.dart';
import 'package:broad_app/models/maps_model.dart';
import 'package:broad_app/services/api_client.dart';

/// Service for /api/maps endpoints.
class MapsService {
  final Dio _dio = ApiClient.instance.dio;

  /// POST /api/maps/routes
  Future<List<ComputedRoute>> computeRoutes({
    required double originLat,
    required double originLng,
    required double destLat,
    required double destLng,
    bool computeAlternatives = true,
  }) async {
    final response = await _dio.post('/api/maps/routes', data: {
      'origin': {'latitude': originLat, 'longitude': originLng},
      'destination': {'latitude': destLat, 'longitude': destLng},
      'computeAlternatives': computeAlternatives,
    });
    final list = response.data['data'] as List;
    return list.map((r) => ComputedRoute.fromJson(r)).toList();
  }

  /// POST /api/maps/distance
  Future<DistanceResult> getDistance({
    required double originLat,
    required double originLng,
    required double destLat,
    required double destLng,
  }) async {
    final response = await _dio.post('/api/maps/distance', data: {
      'origin': {'latitude': originLat, 'longitude': originLng},
      'destination': {'latitude': destLat, 'longitude': destLng},
    });
    return DistanceResult.fromJson(response.data['data']);
  }

  /// GET /api/maps/geocode?address=...
  Future<GeocodedLocation> geocode(String address) async {
    final response = await _dio.get('/api/maps/geocode', queryParameters: {
      'address': address,
    });
    return GeocodedLocation.fromJson(response.data['data']);
  }

  /// GET /api/maps/reverse-geocode?lat=...&lng=...
  Future<ReverseGeocodeResult> reverseGeocode({
    required double lat,
    required double lng,
  }) async {
    final response =
        await _dio.get('/api/maps/reverse-geocode', queryParameters: {
      'lat': lat,
      'lng': lng,
    });
    return ReverseGeocodeResult.fromJson(response.data['data']);
  }

  /// GET /api/maps/autocomplete?input=...
  Future<List<PlaceSuggestion>> autocomplete({
    required String input,
    double? lat,
    double? lng,
  }) async {
    final response =
        await _dio.get('/api/maps/autocomplete', queryParameters: {
      'input': input,
      if (lat != null) 'lat': lat,
      if (lng != null) 'lng': lng,
    });
    final list = response.data['data'] as List;
    return list.map((s) => PlaceSuggestion.fromJson(s)).toList();
  }
}
