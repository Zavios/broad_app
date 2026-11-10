import 'package:broad_app/components/trip_details.dart';
import 'package:broad_app/pages/post/routes_page.dart';
import 'package:broad_app/models/post_ride_data.dart';
import 'package:flutter/material.dart';

class PostPage extends StatefulWidget {
  const PostPage({super.key});

  @override
  State<PostPage> createState() => _PostPageState();
}

class _PostPageState extends State<PostPage> {
  String? _from;
  String? _to;
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
  Future<void> _pickLocation({required bool isFrom}) async {
    final controller = TextEditingController(text: isFrom ? _from : _to);
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isFrom ? 'Start location' : 'Destination'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Enter a place'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('OK'),
          ),
        ],
      ),
    );
    if (result == null || result.isEmpty) return;
    setState(() => isFrom ? _from = result : _to = result);
  }

  Future<void> _pickDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _dateTime,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date == null || !mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_dateTime),
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
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 1; i <= 6; i++)
              ListTile(
                title: Text('$i Passenger${i > 1 ? 's' : ''}'),
                trailing: i == _passengers ? const Icon(Icons.check) : null,
                onTap: () => Navigator.pop(ctx, i),
              ),
          ],
        ),
      ),
    );
    if (count != null) setState(() => _passengers = count);
  }

  void _onNext() {
    if (_from == null || _to == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select both locations')),
      );
      return;
    }

    // Bundle the trip data and navigate to the routes page.
    final data = PostRideData(
      from: _from!,
      to: _to!,
      dateTime: _dateTime,
      passengers: _passengers,
    );

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => RoutesPage(rideData: data)),
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
            'Post a ride',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          const Text(
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w400),
            "Trip details",
          ),
          const SizedBox(height: 16),
          TripSearchCard(
            fromText: _from,
            toText: _to,
            dateTimeText: _dateTimeText,
            passengersText: _passengersText,
            onFromTap: () => _pickLocation(isFrom: true),
            onToTap: () => _pickLocation(isFrom: false),
            onDateTimeTap: _pickDateTime,
            onPassengersTap: _pickPassengers,
            onNext: _onNext,
          ),
        ],
      ),
    );
  }
}
