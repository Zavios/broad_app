import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../components/ride_card.dart';
import '../../models/ride_model.dart';
import '../../providers/rides_provider.dart';
import '../../themes/app_theme.dart';
import 'ride_details_page.dart';

/// Page displaying search results for available rides.
class RidesListPage extends ConsumerStatefulWidget {
  final String? from;
  final String? to;
  final DateTime? dateTime;
  final int? passengers;

  const RidesListPage({
    super.key,
    this.from,
    this.to,
    this.dateTime,
    this.passengers,
  });

  @override
  ConsumerState<RidesListPage> createState() => _RidesListPageState();
}

class _RidesListPageState extends ConsumerState<RidesListPage> {
  @override
  void initState() {
    super.initState();
    // Kick off the search after the first frame.
    Future.microtask(_search);
  }

  Future<void> _search() async {
    String? departureDate;
    if (widget.dateTime != null) {
      final d = widget.dateTime!;
      final m = d.month.toString().padLeft(2, '0');
      final day = d.day.toString().padLeft(2, '0');
      departureDate = '${d.year}-$m-$day';
    }

    await ref.read(searchRidesProvider.notifier).search(
          minSeats: widget.passengers,
          departureDate: departureDate,
        );
  }

  void _openRideDetails(Ride ride) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RideDetailsPage(rideId: ride.id),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ridesState = ref.watch(searchRidesProvider);

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
          'Available Rides',
          style: TextStyle(
            fontFamily: 'monospace',
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Route summary card
              if (widget.from != null && widget.to != null) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.route_outlined,
                        color: AppColors.primary,
                        size: 28,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          '${widget.from} \u2192 ${widget.to}',
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Results area
              Expanded(
                child: _buildBody(ridesState),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody(SearchRidesState state) {
    if (state.isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    if (state.error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline,
              size: 48,
              color: AppColors.burntOrange,
            ),
            const SizedBox(height: 12),
            Text(
              state.error!,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'monospace',
                color: AppColors.burntOrange,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _search,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.background,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text(
                'Retry',
                style: TextStyle(fontFamily: 'monospace'),
              ),
            ),
          ],
        ),
      );
    }

    if (state.rides.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.directions_car_outlined,
              size: 64,
              color: AppColors.secondaryText,
            ),
            SizedBox(height: 12),
            Text(
              'No rides found',
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.secondaryText,
              ),
            ),
            SizedBox(height: 4),
            Text(
              'Try a different date or fewer passengers.',
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 13,
                color: AppColors.secondaryText,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: _search,
      child: ListView.separated(
        itemCount: state.rides.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final ride = state.rides[index];
          return RideCard(
            ride: ride,
            onTap: () => _openRideDetails(ride),
            onRequestRide: () => _openRideDetails(ride),
          );
        },
      ),
    );
  }
}
