import 'package:flutter/material.dart';

import 'package:broad_app/models/ride_model.dart';
import 'package:broad_app/models/ride_stop_model.dart';
import 'package:broad_app/models/user_model.dart';
import 'package:broad_app/themes/app_theme.dart';

class RideCard extends StatelessWidget {
  final Ride ride;
  final VoidCallback? onRequestRide;
  final VoidCallback? onMessageDriver;
  final VoidCallback? onTap;

  const RideCard({
    super.key,
    required this.ride,
    this.onRequestRide,
    this.onMessageDriver,
    this.onTap,
  });

  String _formatDate(String dateStr, String? scheduledAt) {
    final targetStr = scheduledAt ?? dateStr;
    final parsed = DateTime.tryParse(targetStr);
    if (parsed == null) return dateStr;

    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final local = targetStr.contains('T') ? parsed.toLocal() : parsed;
    final dateFormatted =
        '${local.day} ${months[local.month - 1]} ${local.year}';

    if (scheduledAt != null && scheduledAt.contains('T')) {
      final hour = local.hour % 12 == 0 ? 12 : local.hour % 12;
      final minute = local.minute.toString().padLeft(2, '0');
      final period = local.hour >= 12 ? 'PM' : 'AM';
      return '$dateFormatted, $hour:$minute $period';
    }
    return dateFormatted;
  }

  String _getInitials(String name) {
    final clean = name.trim();
    if (clean.isEmpty) return '?';
    final parts = clean.split(RegExp(r'\s+'));
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final originName = ride.origin?.locationName ?? 'Origin not specified';
    final destinationName =
        ride.destination?.locationName ?? 'Destination not specified';

    final driverName = ride.driverProfile?.fullName.trim().isNotEmpty == true
        ? ride.driverProfile!.fullName
        : (ride.driverProfile?.username.isNotEmpty == true
              ? '@${ride.driverProfile!.username}'
              : 'Driver');

    final isVerified =
        (ride.driverProfile?.verificationStatus ?? '').toLowerCase() ==
        'verified';

    final bool isAvailable =
        ride.status.toLowerCase() == 'active' && ride.seatAvailable > 0;

    final String priceText =
        ride.pricePerSeat.truncateToDouble() == ride.pricePerSeat
        ? '${ride.currency} ${ride.pricePerSeat.toInt()}'
        : '${ride.currency} ${ride.pricePerSeat.toStringAsFixed(2)}';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20.0),
        border: Border.all(
          color: AppColors.primary.withOpacity(0.12),
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20.0),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header: Departure & Seat Availability
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.calendar_today_outlined,
                        size: 15,
                        color: AppColors.secondaryText,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _formatDate(ride.departureAt, ride.origin?.scheduledAt),
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: isAvailable
                          ? AppColors.primary
                          : AppColors.burntOrange,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      isAvailable
                          ? '${ride.seatAvailable} seat${ride.seatAvailable == 1 ? '' : 's'} left'
                          : 'Full',
                      style: const TextStyle(
                        color: AppColors.background,
                        fontWeight: FontWeight.w700,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Route Timeline: Origin & Destination
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Timeline dots & line
                    SizedBox(
                      width: 18,
                      child: Column(
                        children: [
                          const SizedBox(height: 4),
                          Container(
                            width: 10,
                            height: 10,
                            decoration: const BoxDecoration(
                              color: AppColors.amber,
                              shape: BoxShape.circle,
                            ),
                          ),
                          Expanded(
                            child: Container(
                              width: 1.5,
                              color: AppColors.primary.withOpacity(0.4),
                            ),
                          ),
                          Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(height: 4),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'From',
                                style: TextStyle(
                                  color: AppColors.secondaryText,
                                  fontSize: 11,
                                ),
                              ),
                              Text(
                                originName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15,
                                  color: AppColors.black,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'To',
                                style: TextStyle(
                                  color: AppColors.secondaryText,
                                  fontSize: 11,
                                ),
                              ),
                              Text(
                                destinationName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15,
                                  color: AppColors.black,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              if (ride.description != null &&
                  ride.description!.trim().isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  ride.description!.trim(),
                  style: TextStyle(
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                    color: AppColors.black.withOpacity(0.7),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],

              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12.0),
                child: Divider(
                  color: AppColors.divider,
                  height: 1,
                  thickness: 1,
                ),
              ),

              // Driver & Fare Summary
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: AppColors.primary,
                        child: Text(
                          _getInitials(driverName),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: AppColors.background,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                driverName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                  color: AppColors.black,
                                ),
                              ),
                              if (isVerified) ...[
                                const SizedBox(width: 4),
                                const Icon(
                                  Icons.verified,
                                  size: 15,
                                  color: AppColors.amber,
                                ),
                              ],
                            ],
                          ),
                          Text(
                            isVerified ? 'Verified Driver' : 'Driver',
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.secondaryText,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text(
                        'Fare per seat',
                        style: TextStyle(
                          color: AppColors.secondaryText,
                          fontSize: 11,
                        ),
                      ),
                      Text(
                        priceText,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 17,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 44,
                      child: ElevatedButton(
                        onPressed: isAvailable && onRequestRide != null
                            ? onRequestRide
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: AppColors.background,
                          disabledBackgroundColor: AppColors.primary
                              .withOpacity(0.2),
                          disabledForegroundColor: AppColors.secondaryText,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: Text(
                          isAvailable ? 'Request Ride' : 'Ride Full',
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (onMessageDriver != null) ...[
                    const SizedBox(width: 10),
                    InkWell(
                      onTap: onMessageDriver,
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        height: 44,
                        width: 44,
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: AppColors.primary.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: const Icon(
                          Icons.chat_bubble_outline_rounded,
                          size: 20,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
