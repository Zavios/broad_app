import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/ride_model.dart';
import '../../models/booking_model.dart';
import '../../providers/rides_provider.dart';
import '../../services/rides_service.dart';
import '../../themes/app_theme.dart';

/// My Rides page — driver view (published rides) and passenger view (bookings).
class MyRidesPage extends ConsumerStatefulWidget {
  const MyRidesPage({super.key});

  @override
  ConsumerState<MyRidesPage> createState() => _MyRidesPageState();
}

class _MyRidesPageState extends ConsumerState<MyRidesPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    // Fetch data for both tabs on page load.
    Future.microtask(() {
      ref.read(myPublishedRidesProvider.notifier).fetch();
      ref.read(myBookingsProvider.notifier).fetch();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Text(
                'My Rides',
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: AppColors.black,
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Tab bar
            TabBar(
              controller: _tabController,
              indicatorColor: AppColors.primary,
              labelColor: AppColors.primary,
              unselectedLabelColor: AppColors.secondaryText,
              labelStyle: const TextStyle(
                fontFamily: 'monospace',
                fontWeight: FontWeight.bold,
              ),
              unselectedLabelStyle: const TextStyle(
                fontFamily: 'monospace',
              ),
              tabs: const [
                Tab(text: 'My Rides'),
                Tab(text: 'Bookings'),
              ],
            ),

            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: const [
                  _DriverTab(),
                  _PassengerTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Driver Tab ───────────────────────────────────────────────────────

class _DriverTab extends ConsumerWidget {
  const _DriverTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(myPublishedRidesProvider);

    if (state.isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    if (state.error != null) {
      return _ErrorView(
        message: state.error!,
        onRetry: () => ref.read(myPublishedRidesProvider.notifier).fetch(),
      );
    }

    if (state.rides.isEmpty) {
      return const _EmptyView(
        icon: Icons.directions_car_outlined,
        message: "You haven't posted any rides yet.",
      );
    }

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () => ref.read(myPublishedRidesProvider.notifier).fetch(),
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: state.rides.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          return _DriverRideCard(ride: state.rides[index]);
        },
      ),
    );
  }
}

class _DriverRideCard extends ConsumerWidget {
  final Ride ride;

  const _DriverRideCard({required this.ride});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statusColor = _statusColor(ride.status);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    '${ride.origin?.locationName ?? '?'} → ${ride.destination?.locationName ?? '?'}',
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: AppColors.black,
                    ),
                  ),
                ),
                // Status badge
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    ride.status.toUpperCase(),
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
            child: Text(
              ride.departureAt,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 12,
                color: AppColors.secondaryText,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
            child: Text(
              '${ride.seatAvailable} seats left  •  ₹${ride.pricePerSeat.toStringAsFixed(0)}/seat',
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 12,
                color: AppColors.secondaryText,
              ),
            ),
          ),

          // Action buttons for active rides
          if (ride.status == 'active') ...[
            const Divider(height: 20, color: AppColors.divider),
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 0, 8, 10),
              child: Row(
                children: [
                  TextButton.icon(
                    onPressed: () => _showBookingRequests(context, ref),
                    icon: const Icon(Icons.people_outline,
                        size: 16, color: AppColors.primary),
                    label: const Text(
                      'Requests',
                      style: TextStyle(
                        fontFamily: 'monospace',
                        color: AppColors.primary,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: () => _cancelRide(context, ref),
                    icon: const Icon(Icons.cancel_outlined,
                        size: 16, color: AppColors.burntOrange),
                    label: const Text(
                      'Cancel Ride',
                      style: TextStyle(
                        fontFamily: 'monospace',
                        color: AppColors.burntOrange,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ] else
            const SizedBox(height: 14),
        ],
      ),
    );
  }

  Color _statusColor(String status) {
    return switch (status) {
      'active' => AppColors.primary,
      'completed' => AppColors.amber,
      _ => AppColors.secondaryText,
    };
  }

  Future<void> _cancelRide(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.background,
        title: const Text(
          'Cancel ride?',
          style: TextStyle(
            fontFamily: 'monospace',
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
        content: const Text(
          'This will cancel the ride for all passengers.',
          style: TextStyle(fontFamily: 'monospace'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(
              'No',
              style: TextStyle(fontFamily: 'monospace', color: AppColors.primary),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Yes, Cancel',
              style: TextStyle(fontFamily: 'monospace', color: AppColors.burntOrange),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    try {
      final service = ref.read(ridesServiceProvider);
      await service.cancelRide(ride.id);
      await ref.read(myPublishedRidesProvider.notifier).fetch();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ride cancelled', style: TextStyle(fontFamily: 'monospace')),
            backgroundColor: AppColors.primary,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString(), style: const TextStyle(fontFamily: 'monospace')),
            backgroundColor: AppColors.burntOrange,
          ),
        );
      }
    }
  }

  void _showBookingRequests(BuildContext context, WidgetRef ref) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _BookingRequestsSheet(rideId: ride.id),
    );
  }
}

// ─── Booking Requests Sheet ───────────────────────────────────────────

class _BookingRequestsSheet extends ConsumerStatefulWidget {
  final String rideId;

  const _BookingRequestsSheet({required this.rideId});

  @override
  ConsumerState<_BookingRequestsSheet> createState() =>
      _BookingRequestsSheetState();
}

class _BookingRequestsSheetState
    extends ConsumerState<_BookingRequestsSheet> {
  List<Booking> _bookings = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchBookings();
  }

  Future<void> _fetchBookings() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final service = ref.read(ridesServiceProvider);
      final bookings = await service.getRideBookings(widget.rideId);
      if (mounted) setState(() {
        _bookings = bookings;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _respond(int bookingId, String action) async {
    try {
      final service = ref.read(ridesServiceProvider);
      await service.respondToBooking(
        rideId: widget.rideId,
        bookingId: bookingId,
        action: action,
      );
      await _fetchBookings();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString(),
                style: const TextStyle(fontFamily: 'monospace')),
            backgroundColor: AppColors.burntOrange,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.6,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Booking Requests',
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                          color: AppColors.primary))
                  : _error != null
                      ? Center(
                          child: Text(_error!,
                              style: const TextStyle(
                                  fontFamily: 'monospace',
                                  color: AppColors.burntOrange)))
                      : _bookings.isEmpty
                          ? const Center(
                              child: Text(
                                'No booking requests yet.',
                                style: TextStyle(
                                  fontFamily: 'monospace',
                                  color: AppColors.secondaryText,
                                ),
                              ),
                            )
                          : ListView.separated(
                              itemCount: _bookings.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 10),
                              itemBuilder: (_, i) {
                                final b = _bookings[i];
                                final passenger = b.passengerProfile;
                                return Container(
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: AppColors.card,
                                    borderRadius:
                                        BorderRadius.circular(14),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              passenger != null
                                                  ? '${passenger.firstName} ${passenger.lastName}'
                                                  : 'Passenger',
                                              style: const TextStyle(
                                                fontFamily: 'monospace',
                                                fontWeight: FontWeight.bold,
                                                color: AppColors.black,
                                              ),
                                            ),
                                          ),
                                          _StatusBadge(
                                              status: b.status),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '${b.seatsBooked} seat(s)  •  ₹${b.totalAmount.toStringAsFixed(0)}',
                                        style: const TextStyle(
                                          fontFamily: 'monospace',
                                          fontSize: 12,
                                          color: AppColors.secondaryText,
                                        ),
                                      ),
                                      if (b.status == 'pending') ...[
                                        const SizedBox(height: 10),
                                        Row(
                                          children: [
                                            Expanded(
                                              child: OutlinedButton(
                                                onPressed: () =>
                                                    _respond(b.id, 'reject'),
                                                style: OutlinedButton.styleFrom(
                                                  foregroundColor:
                                                      AppColors.burntOrange,
                                                  side: const BorderSide(
                                                      color:
                                                          AppColors.burntOrange),
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            10),
                                                  ),
                                                ),
                                                child: const Text(
                                                  'Reject',
                                                  style: TextStyle(
                                                      fontFamily: 'monospace'),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 10),
                                            Expanded(
                                              child: ElevatedButton(
                                                onPressed: () =>
                                                    _respond(b.id, 'confirm'),
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor:
                                                      AppColors.primary,
                                                  foregroundColor:
                                                      AppColors.background,
                                                  elevation: 0,
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            10),
                                                  ),
                                                ),
                                                child: const Text(
                                                  'Confirm',
                                                  style: TextStyle(
                                                      fontFamily: 'monospace'),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ],
                                  ),
                                );
                              },
                            ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Passenger Tab ────────────────────────────────────────────────────

class _PassengerTab extends ConsumerWidget {
  const _PassengerTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(myBookingsProvider);

    if (state.isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    if (state.error != null) {
      return _ErrorView(
        message: state.error!,
        onRetry: () => ref.read(myBookingsProvider.notifier).fetch(),
      );
    }

    if (state.bookings.isEmpty) {
      return const _EmptyView(
        icon: Icons.bookmark_border_outlined,
        message: "You haven't booked any rides yet.",
      );
    }

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () => ref.read(myBookingsProvider.notifier).fetch(),
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: state.bookings.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          return _PassengerBookingCard(booking: state.bookings[index]);
        },
      ),
    );
  }
}

class _PassengerBookingCard extends ConsumerWidget {
  final Booking booking;

  const _PassengerBookingCard({required this.booking});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ride = booking.ride;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    ride != null
                        ? '${ride.origin?.locationName ?? '?'} → ${ride.destination?.locationName ?? '?'}'
                        : 'Ride #${booking.rideId.substring(0, 8)}',
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: AppColors.black,
                    ),
                  ),
                ),
                _StatusBadge(status: booking.status),
              ],
            ),
          ),
          if (ride != null) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
              child: Text(
                ride.departureAt,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 12,
                  color: AppColors.secondaryText,
                ),
              ),
            ),
          ],
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
            child: Text(
              '${booking.seatsBooked} seat(s)  •  ₹${booking.totalAmount.toStringAsFixed(0)}',
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 12,
                color: AppColors.secondaryText,
              ),
            ),
          ),

          // Cancel button for pending/confirmed bookings
          if (booking.status == 'pending' ||
              booking.status == 'confirmed') ...[
            const Divider(height: 20, color: AppColors.divider),
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 0, 8, 10),
              child: Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: () => _cancelBooking(context, ref),
                  icon: const Icon(Icons.cancel_outlined,
                      size: 16, color: AppColors.burntOrange),
                  label: const Text(
                    'Cancel Booking',
                    style: TextStyle(
                      fontFamily: 'monospace',
                      color: AppColors.burntOrange,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            ),
          ] else
            const SizedBox(height: 14),
        ],
      ),
    );
  }

  Future<void> _cancelBooking(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.background,
        title: const Text(
          'Cancel booking?',
          style: TextStyle(
            fontFamily: 'monospace',
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
        content: const Text(
          'Are you sure you want to cancel this booking?',
          style: TextStyle(fontFamily: 'monospace'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('No',
                style: TextStyle(
                    fontFamily: 'monospace', color: AppColors.primary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Yes, Cancel',
                style: TextStyle(
                    fontFamily: 'monospace',
                    color: AppColors.burntOrange)),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    try {
      final service = ref.read(ridesServiceProvider);
      await service.cancelBooking(
        rideId: booking.rideId,
        bookingId: booking.id,
      );
      await ref.read(myBookingsProvider.notifier).fetch();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Booking cancelled',
                style: TextStyle(fontFamily: 'monospace')),
            backgroundColor: AppColors.primary,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString(),
                style: const TextStyle(fontFamily: 'monospace')),
            backgroundColor: AppColors.burntOrange,
          ),
        );
      }
    }
  }
}

// ─── Status Badge ─────────────────────────────────────────────────────

class _StatusBadge extends StatelessWidget {
  final String status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      'confirmed' || 'active' => AppColors.primary,
      'pending' => AppColors.amber,
      'rejected' || 'cancelled' => AppColors.secondaryText,
      _ => AppColors.secondaryText,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          fontFamily: 'monospace',
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }
}

// ─── Shared Widgets ───────────────────────────────────────────────────

class _EmptyView extends StatelessWidget {
  final IconData icon;
  final String message;

  const _EmptyView({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 64, color: AppColors.secondaryText),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'monospace',
              fontSize: 14,
              color: AppColors.secondaryText,
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline,
              size: 48, color: AppColors.burntOrange),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'monospace',
              color: AppColors.burntOrange,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: onRetry,
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
}
