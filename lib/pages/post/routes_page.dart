import 'package:flutter/material.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../models/maps_model.dart';
import '../../models/post_ride_data.dart';
import '../../providers/maps_provider.dart';
import '../../themes/app_theme.dart';
import 'fare_and_passenger_page.dart';

/// Page that lets the user pick one of the available routes returned by the
/// Maps API. Shows a live Google Map with the route polyline at the top and
/// a scrollable list of route cards below.
class RoutesPage extends ConsumerStatefulWidget {
  /// Data collected from the previous PostPage.
  final PostRideData rideData;

  const RoutesPage({super.key, required this.rideData});

  @override
  ConsumerState<RoutesPage> createState() => _RoutesPageState();
}

class _RoutesPageState extends ConsumerState<RoutesPage> {
  /// Index of the currently selected route (null = none selected).
  int? _selectedRoute;

  GoogleMapController? _mapController;

  /// Decoded polyline points for the selected route.
  List<LatLng> _polylinePoints = [];

  /// True when GoogleMap fails to initialize (e.g. emulator without GMS).
  bool _mapFailed = false;

  @override
  void initState() {
    super.initState();
    _fetchRoutes();
  }

  /// Call the Maps API to compute route alternatives.
  Future<void> _fetchRoutes() async {
    final data = widget.rideData;
    final originLat = data.fromLat ?? 0.0;
    final originLng = data.fromLng ?? 0.0;
    final destLat = data.toLat ?? 0.0;
    final destLng = data.toLng ?? 0.0;

    // Skip API call if coordinates were never captured.
    if (originLat == 0.0 && originLng == 0.0) return;

    await ref.read(routesProvider.notifier).computeRoutes(
          originLat: originLat,
          originLng: originLng,
          destLat: destLat,
          destLng: destLng,
        );

    // Auto-select the first route if only one comes back.
    final routes = ref.read(routesProvider).routes;
    if (routes.length == 1) {
      _selectRoute(0, routes[0]);
    }
  }

  /// Decode the route's encoded polyline and update the map.
  void _selectRoute(int index, ComputedRoute route) {
    setState(() => _selectedRoute = index);

    if (route.encodedPolyline != null && route.encodedPolyline!.isNotEmpty) {
      final decoded = PolylinePoints()
          .decodePolyline(route.encodedPolyline!)
          .map((p) => LatLng(p.latitude, p.longitude))
          .toList();
      setState(() => _polylinePoints = decoded);
      _fitMapToPolyline(decoded);
    }
  }

  /// Animate the camera to show the full polyline.
  void _fitMapToPolyline(List<LatLng> points) {
    if (points.isEmpty || _mapController == null) return;

    double minLat = points.first.latitude;
    double maxLat = points.first.latitude;
    double minLng = points.first.longitude;
    double maxLng = points.first.longitude;

    for (final p in points) {
      if (p.latitude < minLat) minLat = p.latitude;
      if (p.latitude > maxLat) maxLat = p.latitude;
      if (p.longitude < minLng) minLng = p.longitude;
      if (p.longitude > maxLng) maxLng = p.longitude;
    }

    _mapController!.animateCamera(
      CameraUpdate.newLatLngBounds(
        LatLngBounds(
          southwest: LatLng(minLat, minLng),
          northeast: LatLng(maxLat, maxLng),
        ),
        60, // padding in pixels
      ),
    );
  }

  void _onNext() {
    if (_selectedRoute == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a route')),
      );
      return;
    }

    final routes = ref.read(routesProvider).routes;
    final selected = routes[_selectedRoute!];

    // Add the selected route index and polyline to the ride data and navigate.
    final updatedData = widget.rideData.copyWith(
      selectedRoute: _selectedRoute,
      routePolyline: selected.encodedPolyline,
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FareAndPassengerPage(rideData: updatedData),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final routesState = ref.watch(routesProvider);
    final origin = LatLng(
      widget.rideData.fromLat ?? 0.0,
      widget.rideData.fromLng ?? 0.0,
    );
    final destination = LatLng(
      widget.rideData.toLat ?? 0.0,
      widget.rideData.toLng ?? 0.0,
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ---- Heading ----
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 32, 16, 16),
              child: Text(
                'Select Route',
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  color: AppColors.black,
                ),
              ),
            ),

            // ---- Google Map (with GMS failure fallback) ----
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: SizedBox(
                  height: 200,
                  child: _mapFailed
                      ? _buildMapFallback()
                      : _buildGoogleMap(origin, destination),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // ---- Route cards ----
            Expanded(
              child: _buildRouteList(routesState),
            ),

            // ---- Next button ----
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: routesState.isLoading ? null : _onNext,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.background,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(17),
                    ),
                  ),
                  child: const Text(
                    'Next',
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGoogleMap(LatLng origin, LatLng destination) {
    // Wrapped in a custom error widget so a GMS crash (e.g. emulator without
    // Google Play Services) degrades gracefully instead of killing the app.
    return Builder(
      builder: (context) {
        try {
          return GoogleMap(
            initialCameraPosition: CameraPosition(
              target: origin.latitude != 0.0
                  ? origin
                  : const LatLng(20.5937, 78.9629),
              zoom: origin.latitude != 0.0 ? 10 : 4,
            ),
            onMapCreated: (ctrl) {
              _mapController = ctrl;
              if (_polylinePoints.isNotEmpty) {
                _fitMapToPolyline(_polylinePoints);
              } else if (origin.latitude != 0.0) {
                _fitMapToPolyline([origin, destination]);
              }
            },
            markers: {
              if (origin.latitude != 0.0)
                Marker(
                  markerId: const MarkerId('origin'),
                  position: origin,
                  infoWindow: InfoWindow(title: widget.rideData.from),
                  icon: BitmapDescriptor.defaultMarkerWithHue(
                      BitmapDescriptor.hueGreen),
                ),
              if (destination.latitude != 0.0)
                Marker(
                  markerId: const MarkerId('destination'),
                  position: destination,
                  infoWindow: InfoWindow(title: widget.rideData.to),
                  icon: BitmapDescriptor.defaultMarkerWithHue(
                      BitmapDescriptor.hueRed),
                ),
            },
            polylines: _polylinePoints.isNotEmpty
                ? {
                    Polyline(
                      polylineId: const PolylineId('route'),
                      points: _polylinePoints,
                      color: AppColors.primary,
                      width: 4,
                    ),
                  }
                : {},
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            onCameraMove: (_) {},
          );
        } catch (_) {
          // Schedule the fallback for the next frame so setState is safe.
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && !_mapFailed) {
              setState(() => _mapFailed = true);
            }
          });
          return _buildMapFallback();
        }
      },
    );
  }

  /// Shown when GoogleMap fails to initialize (emulator / no GMS).
  Widget _buildMapFallback() {
    return Container(
      color: AppColors.card,
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.map_outlined, size: 40, color: AppColors.primary),
          const SizedBox(height: 10),
          Text(
            '${widget.rideData.from}  →  ${widget.rideData.to}',
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontFamily: 'monospace',
              fontWeight: FontWeight.bold,
              fontSize: 13,
              color: AppColors.black,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Map unavailable on this device.\nSelect a route below.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 11,
              color: AppColors.secondaryText,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRouteList(RoutesState state) {
    if (state.isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    if (state.error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline,
                  color: AppColors.burntOrange, size: 40),
              const SizedBox(height: 8),
              Text(
                state.error!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  color: AppColors.burntOrange,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _fetchRoutes,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.background,
                ),
                child: const Text('Retry',
                    style: TextStyle(fontFamily: 'monospace')),
              ),
            ],
          ),
        ),
      );
    }

    // No coordinates captured — location search not used.
    if (state.routes.isEmpty &&
        (widget.rideData.fromLat == null ||
            widget.rideData.fromLat == 0.0)) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.location_off_outlined,
                  color: AppColors.secondaryText, size: 48),
              const SizedBox(height: 8),
              const Text(
                'Route calculation requires coordinates.\nGo back and use the location search.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'monospace',
                  color: AppColors.secondaryText,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.primary),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Go back',
                    style: TextStyle(fontFamily: 'monospace')),
              ),
            ],
          ),
        ),
      );
    }

    if (state.routes.isEmpty) {
      return const Center(
        child: Text(
          'No routes found.',
          style: TextStyle(
            fontFamily: 'monospace',
            color: AppColors.secondaryText,
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: state.routes.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        return _RouteCard(
          route: state.routes[index],
          index: index,
          isSelected: _selectedRoute == index,
          onTap: () => _selectRoute(index, state.routes[index]),
        );
      },
    );
  }
}

// ─── Route Card ───────────────────────────────────────────────────────

class _RouteCard extends StatelessWidget {
  final ComputedRoute route;
  final int index;
  final bool isSelected;
  final VoidCallback onTap;

  const _RouteCard({
    required this.route,
    required this.index,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.divider,
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            // Route number circle
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.background.withOpacity(0.2)
                    : AppColors.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  '${index + 1}',
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: isSelected
                        ? AppColors.background
                        : AppColors.primary,
                  ),
                ),
              ),
            ),

            const SizedBox(width: 14),

            // Route stats
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Route ${index + 1}',
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: isSelected
                          ? AppColors.background
                          : AppColors.black,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      _StatChip(
                        icon: Icons.straighten_outlined,
                        label: route.distanceKm,
                        isSelected: isSelected,
                      ),
                      const SizedBox(width: 10),
                      _StatChip(
                        icon: Icons.schedule_outlined,
                        label: _formatDuration(route.duration),
                        isSelected: isSelected,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Selected check
            if (isSelected)
              const Icon(Icons.check_circle_rounded,
                  color: AppColors.amber, size: 22),
          ],
        ),
      ),
    );
  }

  /// Converts a Google Maps duration string (e.g. "2340s") to "39 mins".
  String _formatDuration(String raw) {
    final seconds = int.tryParse(raw.replaceAll(RegExp(r'[^0-9]'), ''));
    if (seconds == null) return raw;
    final minutes = (seconds / 60).ceil();
    if (minutes < 60) return '$minutes mins';
    final hrs = minutes ~/ 60;
    final rem = minutes % 60;
    return rem == 0 ? '${hrs}h' : '${hrs}h ${rem}m';
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;

  const _StatChip({
    required this.icon,
    required this.label,
    required this.isSelected,
  });

  @override
  Widget build(BuildContext context) {
    final color = isSelected
        ? AppColors.background.withOpacity(0.85)
        : AppColors.secondaryText;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: color),
        const SizedBox(width: 3),
        Text(
          label,
          style: TextStyle(
            fontFamily: 'monospace',
            fontSize: 12,
            color: color,
          ),
        ),
      ],
    );
  }
}
