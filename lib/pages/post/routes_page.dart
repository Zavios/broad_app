import 'package:flutter/material.dart';

import '../../models/post_ride_data.dart';
import '../../themes/app_theme.dart';
import 'fare_and_passenger_page.dart';

/// Page that lets the user pick one of the available routes.
/// Shows a map placeholder at the top and a 2×2 grid of route buttons.
class RoutesPage extends StatefulWidget {
  /// Data collected from the previous PostPage.
  final PostRideData rideData;

  const RoutesPage({super.key, required this.rideData});

  @override
  State<RoutesPage> createState() => _RoutesPageState();
}

class _RoutesPageState extends State<RoutesPage> {
  /// Index of the currently selected route (null = none selected).
  int? _selectedRoute;

  void _onNext() {
    if (_selectedRoute == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a route')),
      );
      return;
    }

    // Add the selected route to the ride data and navigate forward.
    final updatedData = widget.rideData.copyWith(
      selectedRoute: _selectedRoute,
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
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 32),

              // ---- Heading ----
              const Text(
                'Select Route',
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  color: AppColors.black,
                ),
              ),

              const SizedBox(height: 24),

              // ---- Map placeholder ----
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  width: double.infinity,
                  height: 180,
                  color: AppColors.card,
                  child: const Center(
                    child: Icon(
                      Icons.map_outlined,
                      size: 64,
                      color: AppColors.secondaryText,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // ---- Route buttons (2 × 2 grid) ----
              _buildRouteRow(0, 1),

              const SizedBox(height: 12),

              _buildRouteRow(2, 3),

              const Spacer(),

              // ---- Next button ----
              Padding(
                padding: const EdgeInsets.only(bottom: 24),
                child: SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _onNext,
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
      ),
    );
  }

  /// Builds a row with two route buttons side-by-side.
  Widget _buildRouteRow(int indexA, int indexB) {
    return Row(
      children: [
        Expanded(child: _routeButton(indexA)),
        const SizedBox(width: 12),
        Expanded(child: _routeButton(indexB)),
      ],
    );
  }

  /// A single route-selection button.
  Widget _routeButton(int index) {
    final isSelected = _selectedRoute == index;

    return SizedBox(
      height: 48,
      child: OutlinedButton(
        onPressed: () {
          setState(() => _selectedRoute = index);
        },
        style: OutlinedButton.styleFrom(
          backgroundColor:
              isSelected ? AppColors.primary : AppColors.background,
          foregroundColor:
              isSelected ? AppColors.background : AppColors.primary,
          side: const BorderSide(color: AppColors.primary, width: 1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: Text(
          'Route ${index + 1}',
          style: const TextStyle(
            fontFamily: 'monospace',
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
