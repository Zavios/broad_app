import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../components/location_search_sheet.dart';
import '../../components/trip_details.dart';
import '../../themes/app_theme.dart';
import 'rides_list_page.dart';

class SearchPage extends ConsumerStatefulWidget {
  const SearchPage({super.key});

  @override
  ConsumerState<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends ConsumerState<SearchPage> {
  String? _from;
  double? _fromLat;
  double? _fromLng;

  String? _to;
  double? _toLat;
  double? _toLng;

  DateTime _dateTime = DateTime.now();
  int _passengers = 1;

  // ---- Formatting ---------------------------------------------------------
  String get _dateTimeText {
    final now = DateTime.now();
    final isToday =
        _dateTime.year == now.year &&
        _dateTime.month == now.month &&
        _dateTime.day == now.day;
    final time = TimeOfDay.fromDateTime(_dateTime).format(context);
    final day = isToday
        ? 'Today'
        : '${_dateTime.day}/${_dateTime.month}/${_dateTime.year}';
    return '$day, $time';
  }

  String get _passengersText =>
      '$_passengers Passenger${_passengers > 1 ? 's' : ''}';

  // ---- Pickers ------------------------------------------------------------

  /// Opens the live autocomplete location search sheet.
  Future<void> _pickLocation({required bool isFrom}) async {
    final result = await showLocationSearchSheet(
      context,
      title: isFrom ? 'Start location' : 'Destination',
    );
    if (result == null) return;
    setState(() {
      if (isFrom) {
        _from = result.displayName;
        _fromLat = result.lat;
        _fromLng = result.lng;
      } else {
        _to = result.displayName;
        _toLat = result.lat;
        _toLng = result.lng;
      }
    });
  }

  Future<void> _pickDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _dateTime,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: AppColors.background,
              surface: AppColors.background,
              onSurface: AppColors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    if (date == null || !mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_dateTime),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: AppColors.background,
              surface: AppColors.background,
              onSurface: AppColors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    if (time == null) return;

    setState(() {
      _dateTime = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    });
  }

  Future<void> _pickPassengers() async {
    final count = await showModalBottomSheet<int>(
      context: context,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 1; i <= 6; i++)
              ListTile(
                title: Text(
                  '$i Passenger${i > 1 ? 's' : ''}',
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.w600,
                  ),
                ),
                trailing: i == _passengers
                    ? const Icon(Icons.check, color: AppColors.primary)
                    : null,
                onTap: () => Navigator.pop(ctx, i),
              ),
          ],
        ),
      ),
    );
    if (count != null) setState(() => _passengers = count);
  }

  void _onSearch() {
    if (_from == null || _to == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select both locations')),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RidesListPage(
          from: _from,
          to: _to,
          dateTime: _dateTime,
          passengers: _passengers,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Search a ride',
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: AppColors.black,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Trip details',
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.secondaryText,
            ),
          ),
          const SizedBox(height: 16),
          TripSearchCard(
            fromText: _from,
            toText: _to,
            dateTimeText: _dateTimeText,
            passengersText: _passengersText,
            nextLabel: 'Search',
            fontFamily: 'monospace',
            onFromTap: () => _pickLocation(isFrom: true),
            onToTap: () => _pickLocation(isFrom: false),
            onDateTimeTap: _pickDateTime,
            onPassengersTap: _pickPassengers,
            onNext: _onSearch,
          ),
        ],
      ),
    );
  }
}
