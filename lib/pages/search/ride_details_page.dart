import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/ride_model.dart';
import '../../models/booking_model.dart';
import '../../models/ride_stop_model.dart';
import '../../providers/rides_provider.dart';
import '../../services/rides_service.dart';
import '../../themes/app_theme.dart';

/// Shows full ride info and lets a passenger book a seat.
class RideDetailsPage extends ConsumerStatefulWidget {
  final String rideId;

  const RideDetailsPage({super.key, required this.rideId});

  @override
  ConsumerState<RideDetailsPage> createState() => _RideDetailsPageState();
}

class _RideDetailsPageState extends ConsumerState<RideDetailsPage> {
  Ride? _ride;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchRide();
  }

  Future<void> _fetchRide() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final service = ref.read(ridesServiceProvider);
      final ride = await service.getRideById(widget.rideId);
      if (mounted) setState(() {
        _ride = ride;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _openBookingSheet() {
    if (_ride == null) return;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _BookingSheet(ride: _ride!),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: AppColors.black,
            size: 22,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Ride Details',
          style: TextStyle(
            fontFamily: 'monospace',
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
      ),
      body: _buildBody(),
      bottomNavigationBar: _ride != null
          ? SafeArea(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: ElevatedButton(
                  onPressed: _openBookingSheet,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.background,
                    elevation: 0,
                    minimumSize: const Size.fromHeight(52),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(17),
                    ),
                  ),
                  child: const Text(
                    'Request Tag Along',
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline,
                size: 48, color: AppColors.burntOrange),
            const SizedBox(height: 12),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'monospace',
                color: AppColors.burntOrange,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _fetchRide,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.background,
              ),
              child: const Text('Retry',
                  style: TextStyle(fontFamily: 'monospace')),
            ),
          ],
        ),
      );
    }

    final ride = _ride!;
    final driver = ride.driverProfile;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ---- Driver card ----
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                // Avatar initials
                CircleAvatar(
                  radius: 26,
                  backgroundColor: AppColors.primary,
                  child: Text(
                    driver != null
                        ? '${driver.firstName[0]}${driver.lastName[0]}'
                            .toUpperCase()
                        : '?',
                    style: const TextStyle(
                      color: AppColors.background,
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        driver != null
                            ? '${driver.firstName} ${driver.lastName}'
                            : 'Driver',
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: AppColors.black,
                        ),
                      ),
                      if (driver?.verificationStatus == 'verified')
                        const Row(
                          children: [
                            Icon(Icons.verified,
                                size: 14, color: AppColors.primary),
                            SizedBox(width: 4),
                            Text(
                              'Verified',
                              style: TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 12,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // ---- Route timeline ----
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                for (int i = 0; i < ride.stops.length; i++)
                  _StopRow(
                    stop: ride.stops[i],
                    isLast: i == ride.stops.length - 1,
                  ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // ---- Ride info chips ----
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _InfoChip(
                icon: Icons.event_seat_outlined,
                label: '${ride.seatAvailable} seats left',
              ),
              _InfoChip(
                icon: Icons.currency_rupee,
                label:
                    '${ride.pricePerSeat.toStringAsFixed(0)} / seat',
              ),
              _InfoChip(
                icon: Icons.calendar_today_outlined,
                label: ride.departureAt,
              ),
              _InfoChip(
                icon: ride.status == 'active'
                    ? Icons.check_circle_outline
                    : Icons.cancel_outlined,
                label: ride.status,
                color: ride.status == 'active'
                    ? AppColors.primary
                    : AppColors.secondaryText,
              ),
            ],
          ),

          // ---- Description ----
          if (ride.description != null && ride.description!.isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                ride.description!,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 13,
                  color: AppColors.black,
                ),
              ),
            ),
          ],

          const SizedBox(height: 80),
        ],
      ),
    );
  }
}

// ─── Stop Timeline Row ────────────────────────────────────────────────

class _StopRow extends StatelessWidget {
  final RideStop stop;
  final bool isLast;

  const _StopRow({required this.stop, required this.isLast});

  @override
  Widget build(BuildContext context) {
    final isOrigin = stop.stopType == 'origin';
    final isDestination = stop.stopType == 'destination';

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline dot + line
          Column(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isOrigin
                      ? AppColors.primary
                      : isDestination
                          ? AppColors.burntOrange
                          : AppColors.amber,
                  border: Border.all(color: AppColors.primary, width: 2),
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    color: AppColors.divider,
                    margin: const EdgeInsets.symmetric(vertical: 2),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    stop.locationName,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: AppColors.black,
                    ),
                  ),
                  Text(
                    stop.stopType,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 11,
                      color: AppColors.secondaryText,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Info Chip ───────────────────────────────────────────────────────

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _InfoChip({
    required this.icon,
    required this.label,
    this.color = AppColors.primary,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Booking Sheet ───────────────────────────────────────────────────

class _BookingSheet extends ConsumerStatefulWidget {
  final Ride ride;

  const _BookingSheet({required this.ride});

  @override
  ConsumerState<_BookingSheet> createState() => _BookingSheetState();
}

class _BookingSheetState extends ConsumerState<_BookingSheet> {
  RideStop? _pickupStop;
  RideStop? _dropoffStop;
  int _seats = 1;
  bool _isLoading = false;
  String? _error;
  Booking? _result;

  List<RideStop> get _pickupStops =>
      widget.ride.stops.where((s) => s.allowPickup == true).toList();
  List<RideStop> get _dropoffStops =>
      widget.ride.stops.where((s) => s.allowDropoff == true).toList();

  @override
  void initState() {
    super.initState();
    if (_pickupStops.isNotEmpty) _pickupStop = _pickupStops.first;
    if (_dropoffStops.isNotEmpty) _dropoffStop = _dropoffStops.first;
  }

  Future<void> _book() async {
    if (_pickupStop == null || _dropoffStop == null) {
      setState(() => _error = 'Please select pickup and dropoff stops');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final service = ref.read(ridesServiceProvider);
      final booking = await service.bookRide(
        rideId: widget.ride.id,
        pickupStopId: _pickupStop!.id,
        dropoffStopId: _dropoffStop!.id,
        seatsBooked: _seats,
      );
      if (mounted) setState(() {
        _result = booking;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: _result != null ? _buildSuccess() : _buildForm(),
    );
  }

  Widget _buildSuccess() {
    final b = _result!;
    final statusColor = switch (b.status) {
      'confirmed' => AppColors.primary,
      'pending' => AppColors.amber,
      _ => AppColors.secondaryText,
    };

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.check_circle_rounded,
            size: 56, color: AppColors.primary),
        const SizedBox(height: 12),
        const Text(
          'Booking Requested!',
          style: TextStyle(
            fontFamily: 'monospace',
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            color: statusColor.withOpacity(0.12),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            b.status.toUpperCase(),
            style: TextStyle(
              fontFamily: 'monospace',
              fontWeight: FontWeight.bold,
              color: statusColor,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Total: \u20B9${b.totalAmount.toStringAsFixed(0)}',
          style: const TextStyle(
            fontFamily: 'monospace',
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.black,
          ),
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.background,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: const Text('Done',
                style: TextStyle(fontFamily: 'monospace', fontSize: 16)),
          ),
        ),
      ],
    );
  }

  Widget _buildForm() {
    final maxSeats = widget.ride.seatAvailable;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Book a Seat',
          style: TextStyle(
            fontFamily: 'monospace',
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 20),

        // Pickup stop dropdown
        if (_pickupStops.isNotEmpty) ...[
          const Text(
            'Pickup stop',
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 12,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 6),
          DropdownButtonFormField<RideStop>(
            value: _pickupStop,
            dropdownColor: AppColors.card,
            decoration: _dropdownDecoration(),
            items: _pickupStops
                .map((s) => DropdownMenuItem(
                      value: s,
                      child: Text(
                        s.locationName,
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 13,
                        ),
                      ),
                    ))
                .toList(),
            onChanged: (v) => setState(() => _pickupStop = v),
          ),
          const SizedBox(height: 14),
        ],

        // Dropoff stop dropdown
        if (_dropoffStops.isNotEmpty) ...[
          const Text(
            'Dropoff stop',
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 12,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 6),
          DropdownButtonFormField<RideStop>(
            value: _dropoffStop,
            dropdownColor: AppColors.card,
            decoration: _dropdownDecoration(),
            items: _dropoffStops
                .map((s) => DropdownMenuItem(
                      value: s,
                      child: Text(
                        s.locationName,
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 13,
                        ),
                      ),
                    ))
                .toList(),
            onChanged: (v) => setState(() => _dropoffStop = v),
          ),
          const SizedBox(height: 14),
        ],

        // Seat count stepper
        Row(
          children: [
            const Expanded(
              child: Text(
                'Seats',
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.black,
                ),
              ),
            ),
            _CounterButton(
              icon: Icons.remove,
              onTap: () {
                if (_seats > 1) setState(() => _seats--);
              },
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                '$_seats',
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ),
            _CounterButton(
              icon: Icons.add,
              onTap: () {
                if (_seats < maxSeats) setState(() => _seats++);
              },
            ),
          ],
        ),

        if (_error != null) ...[
          const SizedBox(height: 10),
          Text(
            _error!,
            style: const TextStyle(
              fontFamily: 'monospace',
              color: AppColors.burntOrange,
              fontSize: 12,
            ),
          ),
        ],

        const SizedBox(height: 20),

        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _book,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.background,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: _isLoading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      color: AppColors.background,
                      strokeWidth: 2.5,
                    ),
                  )
                : Text(
                    'Confirm Booking  •  \u20B9${(widget.ride.pricePerSeat * _seats).toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  InputDecoration _dropdownDecoration() {
    return InputDecoration(
      filled: true,
      fillColor: AppColors.card,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.primary, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.8),
      ),
    );
  }
}

class _CounterButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _CounterButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 34,
        height: 34,
        decoration: const BoxDecoration(
          color: AppColors.primary,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: AppColors.background, size: 18),
      ),
    );
  }
}

