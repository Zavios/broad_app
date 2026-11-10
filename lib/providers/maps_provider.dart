import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:broad_app/models/maps_model.dart';
import 'package:broad_app/services/maps_service.dart';

// ─── Routes ──────────────────────────────────────────────────────────

class RoutesState {
  final bool isLoading;
  final List<ComputedRoute> routes;
  final String? error;

  const RoutesState({
    this.isLoading = false,
    this.routes = const [],
    this.error,
  });

  RoutesState copyWith({
    bool? isLoading,
    List<ComputedRoute>? routes,
    String? error,
  }) {
    return RoutesState(
      isLoading: isLoading ?? this.isLoading,
      routes: routes ?? this.routes,
      error: error,
    );
  }
}

class RoutesNotifier extends StateNotifier<RoutesState> {
  final MapsService _service = MapsService();

  RoutesNotifier() : super(const RoutesState());

  Future<void> computeRoutes({
    required double originLat,
    required double originLng,
    required double destLat,
    required double destLng,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final routes = await _service.computeRoutes(
        originLat: originLat,
        originLng: originLng,
        destLat: destLat,
        destLng: destLng,
      );
      state = state.copyWith(isLoading: false, routes: routes);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: _extractError(e));
    }
  }

  void clear() => state = const RoutesState();

  String _extractError(dynamic e) {
    if (e is DioException && e.response?.data != null) {
      final data = e.response!.data;
      if (data is Map) return data['error']?.toString() ?? 'Unknown error';
    }
    return e.toString();
  }
}

final routesProvider = StateNotifierProvider<RoutesNotifier, RoutesState>(
  (ref) => RoutesNotifier(),
);

// ─── Autocomplete ────────────────────────────────────────────────────

class AutocompleteState {
  final bool isLoading;
  final List<PlaceSuggestion> suggestions;
  final String? error;

  const AutocompleteState({
    this.isLoading = false,
    this.suggestions = const [],
    this.error,
  });

  AutocompleteState copyWith({
    bool? isLoading,
    List<PlaceSuggestion>? suggestions,
    String? error,
  }) {
    return AutocompleteState(
      isLoading: isLoading ?? this.isLoading,
      suggestions: suggestions ?? this.suggestions,
      error: error,
    );
  }
}

class AutocompleteNotifier extends StateNotifier<AutocompleteState> {
  final MapsService _service = MapsService();

  AutocompleteNotifier() : super(const AutocompleteState());

  Future<void> search(String input, {double? lat, double? lng}) async {
    if (input.length < 2) {
      state = state.copyWith(suggestions: []);
      return;
    }
    state = state.copyWith(isLoading: true, error: null);
    try {
      final suggestions =
          await _service.autocomplete(input: input, lat: lat, lng: lng);
      state = state.copyWith(isLoading: false, suggestions: suggestions);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: _extractError(e));
    }
  }

  void clear() => state = const AutocompleteState();

  String _extractError(dynamic e) {
    if (e is DioException && e.response?.data != null) {
      final data = e.response!.data;
      if (data is Map) return data['error']?.toString() ?? 'Unknown error';
    }
    return e.toString();
  }
}

final autocompleteProvider =
    StateNotifierProvider<AutocompleteNotifier, AutocompleteState>(
  (ref) => AutocompleteNotifier(),
);

// ─── Geocoding (one-off) ─────────────────────────────────────────────

final mapsServiceProvider = Provider<MapsService>((ref) => MapsService());
