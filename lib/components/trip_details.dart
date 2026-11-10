import 'package:flutter/material.dart';

/// A reusable "plan your trip" card: From / To locations, date & time,
/// passenger count and a primary "Next" button.
///
/// The widget is stateless: pass the current values in and react to taps via
/// callbacks (open a place picker, date picker, bottom sheet, etc.).
class TripSearchCard extends StatelessWidget {
  const TripSearchCard({
    super.key,
    this.fromText,
    this.toText,
    required this.dateTimeText,
    required this.passengersText,
    this.onFromTap,
    this.onToTap,
    this.onDateTimeTap,
    this.onPassengersTap,
    this.onNext,
    this.fromHint = 'Select start location',
    this.toHint = 'Select destination point',
    this.nextLabel = 'Next',
    this.backgroundColor = const Color(0xFFEFEADD),
    this.buttonColor = const Color(0xFF1E4630),
    this.accentColor = const Color(0xFFE8A22B),
    this.textColor = const Color(0xFF1B1B1B),
    this.labelColor = const Color(0xFF6B6B63),
    this.dividerColor = const Color(0xFFCFCABB),
    this.fontFamily,
  });

  final String? fromText;
  final String? toText;
  final String dateTimeText;
  final String passengersText;

  final VoidCallback? onFromTap;
  final VoidCallback? onToTap;
  final VoidCallback? onDateTimeTap;
  final VoidCallback? onPassengersTap;
  final VoidCallback? onNext;

  final String fromHint;
  final String toHint;
  final String nextLabel;

  final Color backgroundColor;
  final Color buttonColor;
  final Color accentColor;
  final Color textColor;
  final Color labelColor;
  final Color dividerColor;
  final String? fontFamily;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildLocations(),
          const SizedBox(height: 14),
          Divider(height: 1, thickness: 1, color: dividerColor),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _SelectorTile(
                  leading: Icons.calendar_today_outlined,
                  label: 'Date and time',
                  value: dateTimeText,
                  onTap: onDateTimeTap,
                  textColor: textColor,
                  labelColor: labelColor,
                  fontFamily: fontFamily,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _SelectorTile(
                  leading: Icons.person_outline,
                  label: 'Passengers',
                  value: passengersText,
                  onTap: onPassengersTap,
                  textColor: textColor,
                  labelColor: labelColor,
                  fontFamily: fontFamily,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildNextButton(),
        ],
      ),
    );
  }

  Widget _buildLocations() {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Timeline: dot ── line ── square
          SizedBox(
            width: 20,
            child: Column(
              children: [
                const SizedBox(height: 6),
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: accentColor,
                    shape: BoxShape.circle,
                  ),
                ),
                Expanded(child: Container(width: 1.5, color: textColor)),
                Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: textColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                  alignment: Alignment.center,
                  child: Container(width: 5, height: 5, color: backgroundColor),
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _LocationField(
                  label: 'From',
                  value: fromText,
                  hint: fromHint,
                  onTap: onFromTap,
                  textColor: textColor,
                  labelColor: labelColor,
                  fontFamily: fontFamily,
                ),
                Divider(height: 1, thickness: 1, color: dividerColor),
                _LocationField(
                  label: 'To',
                  value: toText,
                  hint: toHint,
                  onTap: onToTap,
                  textColor: textColor,
                  labelColor: labelColor,
                  fontFamily: fontFamily,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNextButton() {
    return SizedBox(
      height: 52,
      child: FilledButton(
        onPressed: onNext,
        style: FilledButton.styleFrom(
          backgroundColor: buttonColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(26),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              nextLabel,
              style: TextStyle(
                fontFamily: fontFamily,
                fontSize: 15,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.arrow_forward, size: 20),
          ],
        ),
      ),
    );
  }
}

class _LocationField extends StatelessWidget {
  const _LocationField({
    required this.label,
    required this.hint,
    required this.textColor,
    required this.labelColor,
    this.value,
    this.onTap,
    this.fontFamily,
  });

  final String label;
  final String hint;
  final String? value;
  final VoidCallback? onTap;
  final Color textColor;
  final Color labelColor;
  final String? fontFamily;

  @override
  Widget build(BuildContext context) {
    final hasValue = value != null && value!.isNotEmpty;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontFamily: fontFamily,
                fontSize: 11,
                color: labelColor,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              hasValue ? value! : hint,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: fontFamily,
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: hasValue ? textColor : textColor.withOpacity(0.85),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SelectorTile extends StatelessWidget {
  const _SelectorTile({
    required this.leading,
    required this.label,
    required this.value,
    required this.textColor,
    required this.labelColor,
    this.onTap,
    this.fontFamily,
  });

  final IconData leading;
  final String label;
  final String value;
  final VoidCallback? onTap;
  final Color textColor;
  final Color labelColor;
  final String? fontFamily;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Row(
        children: [
          Icon(leading, size: 20, color: textColor),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: fontFamily,
                    fontSize: 11,
                    color: labelColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: fontFamily,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.keyboard_arrow_down, size: 20, color: textColor),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Example usage
// ---------------------------------------------------------------------------
//
// class Demo extends StatefulWidget {
//   const Demo({super.key});
//   @override
//   State<Demo> createState() => _DemoState();
// }
//
// class _DemoState extends State<Demo> {
//   String? from;
//   String? to;
//   int passengers = 1;
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: Padding(
//         padding: const EdgeInsets.all(16),
//         child: TripSearchCard(
//           fromText: from,
//           toText: to,
//           dateTimeText: 'Today, 1:00 PM',
//           passengersText: '$passengers Passenger${passengers > 1 ? 's' : ''}',
//           onFromTap: () => setState(() => from = 'Home'),
//           onToTap: () => setState(() => to = 'Office'),
//           onPassengersTap: () => setState(() => passengers++),
//           onNext: () {},
//         ),
//       ),
//     );
//   }
// }
