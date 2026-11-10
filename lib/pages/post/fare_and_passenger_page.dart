import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/post_ride_data.dart';
import '../../models/vehicle_model.dart';
import '../../providers/rides_provider.dart';
import '../../providers/vehicle_provider.dart';
import '../../themes/app_theme.dart';

/// Page where the user sets the passenger count, fare per passenger,
/// and selects which vehicle to post the ride for.
/// Receives all data collected from PostPage and RoutesPage.
class FareAndPassengerPage extends ConsumerStatefulWidget {
  /// Data accumulated from previous pages.
  final PostRideData rideData;

  const FareAndPassengerPage({super.key, required this.rideData});

  @override
  ConsumerState<FareAndPassengerPage> createState() =>
      _FareAndPassengerPageState();
}

class _FareAndPassengerPageState extends ConsumerState<FareAndPassengerPage> {
  late int _passengerCount;
  late int _passengerFare;

  Vehicle? _selectedVehicle;

  @override
  void initState() {
    super.initState();
    // Initialise from the data passed in (use the PostPage passenger count).
    _passengerCount = widget.rideData.passengers;
    _passengerFare = 30;
    // Load registered vehicles from the backend.
    Future.microtask(
        () => ref.read(vehicleProvider.notifier).fetchVehicles());
  }

  Future<void> _onSubmit() async {
    if (_selectedVehicle == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a vehicle')),
      );
      return;
    }

    // Format departure date as YYYY-MM-DD.
    final d = widget.rideData.dateTime;
    final month = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    final departureAt = '${d.year}-$month-$day';

    // Build stops array (origin + destination as minimum).
    final stops = <Map<String, dynamic>>[
      {
        'stop_order': 1,
        'stop_type': 'origin',
        'location_name': widget.rideData.from,
        'latitude': widget.rideData.fromLat ?? 0.0,
        'longitude': widget.rideData.fromLng ?? 0.0,
        'allow_pickup': true,
        'allow_dropoff': false,
      },
      {
        'stop_order': 2,
        'stop_type': 'destination',
        'location_name': widget.rideData.to,
        'latitude': widget.rideData.toLat ?? 0.0,
        'longitude': widget.rideData.toLng ?? 0.0,
        'allow_pickup': false,
        'allow_dropoff': true,
      },
    ];

    final success = await ref.read(publishRideProvider.notifier).publish(
          vehicleId: _selectedVehicle!.id,
          departureAt: departureAt,
          seatOffered: _passengerCount,
          pricePerSeat: _passengerFare.toDouble(),
          routePolyline: widget.rideData.routePolyline,
          stops: stops,
        );

    if (!mounted) return;

    if (success) {
      // Pop back to the root PostPage.
      Navigator.popUntil(context, (route) => route.isFirst);

      // Show success SnackBar.
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.primary,
          duration: const Duration(seconds: 5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(
                    Icons.check_circle_rounded,
                    color: AppColors.amber,
                    size: 20,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Ride Posted Successfully!',
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: AppColors.background,
                    ),
                  ),
                ],
              ),
              const Divider(color: Color(0xFF3B674C), height: 16),
              _snackDetail('From', widget.rideData.from),
              _snackDetail('To', widget.rideData.to),
              _snackDetail('Date', departureAt),
              _snackDetail('Passengers', '$_passengerCount'),
              _snackDetail('Fare', '₹$_passengerFare/seat'),
              _snackDetail(
                  'Vehicle', _selectedVehicle!.displayName),
            ],
          ),
        ),
      );
    } else {
      final error =
          ref.read(publishRideProvider).error ?? 'Failed to post ride';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error,
              style: const TextStyle(fontFamily: 'monospace')),
          backgroundColor: AppColors.burntOrange,
        ),
      );
    }
  }

  Widget _snackDetail(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(
            fontFamily: 'monospace',
            fontSize: 12,
            color: AppColors.background,
          ),
          children: [
            TextSpan(
              text: '$label: ',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColors.amber,
              ),
            ),
            TextSpan(text: value),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final vehicleState = ref.watch(vehicleProvider);
    final publishState = ref.watch(publishRideProvider);
    final isSubmitting = publishState.isLoading;

    // Sync selected vehicle when list loads.
    if (_selectedVehicle == null && vehicleState.vehicles.isNotEmpty) {
      _selectedVehicle = vehicleState.vehicles.first;
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 32),

                      // ---- Heading ----
                      const Text(
                        'More details',
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 32,
                          fontWeight: FontWeight.w800,
                          color: AppColors.black,
                        ),
                      ),

                      const SizedBox(height: 28),

                      // ---- Passenger count row ----
                      _buildCounterRow(
                        label: 'Passenger count',
                        value: _passengerCount,
                        onIncrement: () {
                          setState(() => _passengerCount++);
                        },
                        onDecrement: () {
                          if (_passengerCount > 1) {
                            setState(() => _passengerCount--);
                          }
                        },
                      ),

                      const SizedBox(height: 20),

                      // ---- Passenger fare row ----
                      _buildCounterRow(
                        label: 'Passenger fare',
                        value: _passengerFare,
                        onIncrement: () {
                          setState(() => _passengerFare += 10);
                        },
                        onDecrement: () {
                          if (_passengerFare > 10) {
                            setState(() => _passengerFare -= 10);
                          }
                        },
                      ),

                      const SizedBox(height: 28),

                      // ---- Vehicle selection ----
                      const Text(
                        'Vehicle',
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.black,
                        ),
                      ),

                      const SizedBox(height: 10),

                      if (vehicleState.isLoading)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.all(16),
                            child: CircularProgressIndicator(
                                color: AppColors.primary),
                          ),
                        )
                      else if (vehicleState.vehicles.isEmpty)
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.card,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: AppColors.divider),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.info_outline,
                                  color: AppColors.secondaryText, size: 20),
                              SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'No vehicles registered. Add one in your Profile.',
                                  style: TextStyle(
                                    fontFamily: 'monospace',
                                    fontSize: 13,
                                    color: AppColors.secondaryText,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )
                      else
                        DropdownButtonFormField<Vehicle>(
                          value: _selectedVehicle,
                          isExpanded: true,
                          dropdownColor: AppColors.card,
                          icon: const Icon(
                            Icons.keyboard_arrow_down_rounded,
                            color: AppColors.primary,
                          ),
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.black,
                          ),
                          decoration: InputDecoration(
                            prefixIcon: const Icon(
                              Icons.directions_car_filled_outlined,
                              color: AppColors.primary,
                            ),
                            filled: true,
                            fillColor: AppColors.card,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 14,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: const BorderSide(
                                color: AppColors.primary,
                                width: 1,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: const BorderSide(
                                color: AppColors.primary,
                                width: 1.8,
                              ),
                            ),
                          ),
                          items: vehicleState.vehicles.map((vehicle) {
                            return DropdownMenuItem<Vehicle>(
                              value: vehicle,
                              child: Text(
                                vehicle.displayName,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontFamily: 'monospace',
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.black,
                                ),
                              ),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() => _selectedVehicle = value);
                          },
                        ),

                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),

              // ---- Submit button ----
              Padding(
                padding: const EdgeInsets.only(bottom: 24),
                child: SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: isSubmitting ? null : _onSubmit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.background,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(17),
                      ),
                    ),
                    child: isSubmitting
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              color: AppColors.background,
                              strokeWidth: 2.5,
                            ),
                          )
                        : const Text(
                            'Post Ride',
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

  /// A label on the left with +/value/− controls on the right.
  Widget _buildCounterRow({
    required String label,
    required int value,
    required VoidCallback onIncrement,
    required VoidCallback onDecrement,
  }) {
    return Row(
      children: [
        // Label
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              fontFamily: 'monospace',
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.black,
            ),
          ),
        ),

        // + button
        _circleButton(
          icon: Icons.add,
          onTap: onIncrement,
        ),

        // Value
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Text(
            '$value',
            style: const TextStyle(
              fontFamily: 'monospace',
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
        ),

        // − button
        _circleButton(
          icon: Icons.remove,
          onTap: onDecrement,
        ),
      ],
    );
  }

  /// A small circular icon button matching the dark-green circles in the design.
  Widget _circleButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: const BoxDecoration(
          color: AppColors.primary,
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          color: AppColors.background,
          size: 20,
        ),
      ),
    );
  }
}
