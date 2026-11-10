import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:broad_app/models/user_model.dart';
import 'package:broad_app/models/vehicle_model.dart';
import 'package:broad_app/services/api_client.dart';
import 'package:broad_app/services/auth_service.dart';
import 'package:broad_app/services/profile_service.dart';
import 'package:broad_app/themes/app_theme.dart';

// ---- Shared constants and helpers -------------------------------------------

const _tint = Color(0x1A1D402D); // primary at 10% opacity
const _plateFill = Color(0xFFFFF3D1);
const _countryCode = '91';

const Map<String, Color> _vehicleColors = {
  'White': Color(0xFFF5F5F2),
  'Black': Color(0xFF1B1B1B),
  'Silver': Color(0xFFC3C6C9),
  'Grey': Color(0xFF7C8084),
  'Red': Color(0xFFC0392B),
  'Blue': Color(0xFF2A5DA8),
  'Green': Color(0xFF3B7A57),
  'Yellow': Color(0xFFE9B72F),
  'Orange': Color(0xFFD9732B),
  'Brown': Color(0xFF7A5333),
};

Color? _colorFor(String name) {
  for (final e in _vehicleColors.entries) {
    if (e.key.toLowerCase() == name.trim().toLowerCase()) return e.value;
  }
  return null;
}

const _months = [
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

/// Formats an ISO date string like "2000-04-12" as "12 Apr 2000".
String? _fmtDate(String? iso) {
  if (iso == null || iso.isEmpty) return null;
  final d = DateTime.tryParse(iso);
  if (d == null) return null;
  final local = iso.contains('T') ? d.toLocal() : d;
  return '${local.day} ${_months[local.month - 1]} ${local.year}';
}

/// Formats phone numbers cleanly for display.
/// Handles 10-digit Indian numbers (9876543210) and 12-digit numbers (919876543210).
String _fmtPhone(int phone) {
  final s = '$phone';
  if (s.length == 12 && s.startsWith('91')) {
    return '+91 ${s.substring(2, 7)} ${s.substring(7)}';
  }
  if (s.length == 10) {
    return '+91 ${s.substring(0, 5)} ${s.substring(5)}';
  }
  return '+$s';
}

String _initials(UserProfile p) {
  final a = p.firstName.isNotEmpty ? p.firstName[0] : '';
  final b = p.lastName.isNotEmpty ? p.lastName[0] : '';
  final s = '$a$b'.toUpperCase();
  return s.isEmpty ? '?' : s;
}

bool _isVerified(UserProfile p) =>
    (p.verificationStatus ?? '').toLowerCase() == 'verified';

Future<T?> _showSheet<T>(BuildContext context, Widget child) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: AppColors.background,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (_) => child,
  );
}

/// Helper to extract clean error message from DioException or generic exceptions.
String _extractErrorMessage(Object e, String fallback) {
  if (e is DioException) {
    final data = e.response?.data;
    if (data is Map && data['error'] != null) {
      return data['error'].toString();
    }
    if (e.message != null && e.message!.isNotEmpty) {
      return e.message!;
    }
  }
  return fallback;
}

// -----------------------------------------------------------------------------
// ProfilePage
// -----------------------------------------------------------------------------

/// Profile tab: user details, editable profile information, vehicle management, and sign out.
class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _service = ProfileService();

  UserProfile? _profile;
  List<Vehicle> _vehicles = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  // ---- Data -----------------------------------------------------------------

  Future<void> _load() async {
    setState(() {
      _loading = _profile == null;
      _error = null;
    });
    try {
      final profile = await _service.getMyProfile();
      final vehicles = await _service.getMyVehicles();
      if (!mounted) return;
      setState(() {
        _profile = profile;
        _vehicles = vehicles;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = _extractErrorMessage(
          e,
          'Could not load your profile. Check your connection and try again.',
        );
        _loading = false;
      });
    }
  }

  Future<void> _reloadVehicles() async {
    try {
      final vehicles = await _service.getMyVehicles();
      if (!mounted) return;
      setState(() => _vehicles = vehicles);
    } catch (e) {
      _toast(
        _extractErrorMessage(e, 'Could not refresh vehicles'),
        error: true,
      );
    }
  }

  void _toast(String message, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: error ? AppColors.burntOrange : AppColors.primary,
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  Future<void> _editPhone() async {
    final result = await _showSheet<int>(
      context,
      _PhoneSheet(initial: _profile?.phone),
    );
    if (result == null) return;
    try {
      final updated = await _service.updateProfile({'phone': result});
      if (!mounted) return;
      setState(() => _profile = updated);
      _toast('Phone number saved');
    } catch (e) {
      _toast(
        _extractErrorMessage(e, 'Could not save phone number'),
        error: true,
      );
    }
  }

  Future<void> _editDob() async {
    final now = DateTime.now();
    DateTime initial = DateTime(now.year - 18, now.month, now.day);
    if (_profile?.dob != null && _profile!.dob!.isNotEmpty) {
      final parsed = DateTime.tryParse(_profile!.dob!);
      if (parsed != null) initial = parsed;
    }

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(1920),
      lastDate: now,
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

    if (picked == null) return;
    final formatted =
        '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';

    try {
      final updated = await _service.updateProfile({'dob': formatted});
      if (!mounted) return;
      setState(() => _profile = updated);
      _toast('Date of birth updated');
    } catch (e) {
      _toast(
        _extractErrorMessage(e, 'Could not update date of birth'),
        error: true,
      );
    }
  }

  Future<void> _editBio() async {
    final controller = TextEditingController(text: _profile?.bio ?? '');
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.background,
        title: const Text(
          'Edit Bio',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
        content: TextField(
          controller: controller,
          maxLines: 4,
          maxLength: 200,
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'Tell us a little about yourself...',
            filled: true,
            fillColor: AppColors.card,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (result == null) return;
    try {
      final updated = await _service.updateProfile({'bio': result});
      if (!mounted) return;
      setState(() => _profile = updated);
      _toast('Bio updated');
    } catch (e) {
      _toast(_extractErrorMessage(e, 'Could not update bio'), error: true);
    }
  }

  Future<void> _openVehicleSheet([Vehicle? existing]) async {
    final result = await _showSheet<Vehicle>(
      context,
      _VehicleSheet(vehicle: existing),
    );
    if (result == null) return;
    try {
      if (existing == null) {
        await _service.addVehicle(
          make: result.make,
          model: result.model,
          color: result.color,
          registrationNo: result.registrationNo,
          seatCapacity: result.seatCapacity,
        );
      } else {
        await _service.updateVehicle(existing.id, {
          'make': result.make,
          'model': result.model,
          'color': result.color,
          'registration_no': result.registrationNo,
          'seat_capacity': result.seatCapacity,
        });
      }
      await _reloadVehicles();
      _toast(existing == null ? 'Vehicle added' : 'Vehicle saved');
    } catch (e) {
      _toast(
        _extractErrorMessage(e, 'Could not save the vehicle'),
        error: true,
      );
    }
  }

  Future<void> _deleteVehicle(Vehicle v) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.background,
        title: const Text('Delete vehicle?'),
        content: Text(
          '${v.displayName} (${v.registrationNo}) will be removed.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.burntOrange),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await _service.deleteVehicle(v.id);
      if (!mounted) return;
      setState(() => _vehicles.removeWhere((x) => x.id == v.id));
      _toast('Vehicle deleted');
    } catch (e) {
      _toast(
        _extractErrorMessage(e, 'Could not delete the vehicle'),
        error: true,
      );
    }
  }

  Future<void> _signOut() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.background,
        title: const Text('Sign out?'),
        content: const Text(
          'Are you sure you want to sign out of your account?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.burntOrange),
            child: const Text('Sign out'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    try {
      await AuthService().signOut();
    } catch (_) {
      // Invalidate local session even if remote signout fails
    }
    await ApiClient.instance.clearTokens();
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
  }

  // ---- Build ----------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }
    if (_profile == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _error ?? 'Profile not found.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.secondaryText),
              ),
              const SizedBox(height: 12),
              TextButton.icon(
                onPressed: _load,
                icon: const Icon(Icons.refresh),
                label: const Text('Try again'),
              ),
            ],
          ),
        ),
      );
    }

    final p = _profile!;
    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: _load,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          const Text(
            'Profile',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: AppColors.black,
            ),
          ),
          const SizedBox(height: 16),
          _header(p),
          const SizedBox(height: 28),
          _sectionTitle('Details'),
          const SizedBox(height: 10),
          _detailsCard(p),
          const SizedBox(height: 28),
          _sectionTitle(
            'My vehicles',
            trailing: TextButton.icon(
              onPressed: () => _openVehicleSheet(),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Add vehicle'),
              style: TextButton.styleFrom(foregroundColor: AppColors.primary),
            ),
          ),
          const SizedBox(height: 10),
          if (_vehicles.isEmpty) _emptyVehicles(),
          for (final v in _vehicles) _vehicleCard(v),
          const SizedBox(height: 32),
          OutlinedButton.icon(
            onPressed: _signOut,
            icon: const Icon(Icons.logout, color: AppColors.burntOrange),
            label: const Text(
              'Sign out',
              style: TextStyle(
                color: AppColors.burntOrange,
                fontWeight: FontWeight.bold,
              ),
            ),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppColors.burntOrange),
              minimumSize: const Size(double.infinity, 50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---- Header ---------------------------------------------------------------

  Widget _header(UserProfile p) {
    final hasBio = (p.bio ?? '').trim().isNotEmpty;
    final name = p.fullName.trim();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 34,
                backgroundColor: AppColors.amber,
                child: Text(
                  _initials(p),
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name.isEmpty ? 'Your name' : name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: AppColors.background,
                      ),
                    ),
                    if (p.username.isNotEmpty)
                      Text(
                        '@${p.username}',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.background.withOpacity(0.7),
                        ),
                      ),
                    const SizedBox(height: 8),
                    _verificationBadge(p),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  hasBio ? p.bio!.trim() : 'No bio added yet. Tap to add one.',
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.5,
                    fontStyle: hasBio ? FontStyle.normal : FontStyle.italic,
                    color: AppColors.background.withOpacity(hasBio ? 0.9 : 0.6),
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(
                  Icons.edit_outlined,
                  size: 18,
                  color: AppColors.amber,
                ),
                tooltip: 'Edit bio',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: _editBio,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _verificationBadge(UserProfile p) {
    final verified = _isVerified(p);
    final status = (p.verificationStatus ?? '').trim();
    final label = verified
        ? 'Verified'
        : status.isEmpty
        ? 'Not verified'
        : '${status[0].toUpperCase()}${status.substring(1)}';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: verified ? AppColors.amber : const Color(0x33FFF9EC),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            verified ? Icons.verified : Icons.schedule,
            size: 14,
            color: verified ? AppColors.primary : AppColors.background,
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: verified ? AppColors.primary : AppColors.background,
            ),
          ),
        ],
      ),
    );
  }

  // ---- Details --------------------------------------------------------------

  Widget _sectionTitle(String text, {Widget? trailing}) {
    return Row(
      children: [
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppColors.primary,
            ),
          ),
        ),
        if (trailing != null) trailing,
      ],
    );
  }

  Widget _detailsCard(UserProfile p) {
    final rows = <Widget>[
      _detailRow(
        icon: Icons.mail_outline,
        label: 'Email',
        value: p.email,
        emptyText: 'No email on file',
      ),
      _detailRow(
        icon: Icons.phone_outlined,
        label: 'Phone',
        value: p.phone == null ? null : _fmtPhone(p.phone!),
        emptyText: 'Add your phone number',
        onEdit: _editPhone,
      ),
      _detailRow(
        icon: Icons.cake_outlined,
        label: 'Date of birth',
        value: _fmtDate(p.dob),
        emptyText: 'Not set',
        onEdit: _editDob,
      ),
      _detailRow(
        icon: Icons.event_available_outlined,
        label: 'Member since',
        value: _fmtDate(p.createdAt),
        emptyText: 'Unknown',
      ),
    ];

    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          for (var i = 0; i < rows.length; i++) ...[
            rows[i],
            if (i != rows.length - 1)
              const Divider(height: 1, indent: 68, color: AppColors.divider),
          ],
        ],
      ),
    );
  }

  Widget _detailRow({
    required IconData icon,
    required String label,
    required String? value,
    required String emptyText,
    VoidCallback? onEdit,
  }) {
    final empty = value == null || value.isEmpty;
    final content = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              color: _tint,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 20, color: AppColors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.secondaryText,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  empty ? emptyText : value,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: empty ? AppColors.burntOrange : AppColors.black,
                  ),
                ),
              ],
            ),
          ),
          if (onEdit != null)
            const Icon(Icons.edit_outlined, size: 20, color: AppColors.primary),
        ],
      ),
    );

    if (onEdit == null) return content;
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onEdit,
      child: content,
    );
  }

  // ---- Vehicles -------------------------------------------------------------

  Widget _emptyVehicles() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.divider, width: 1.5),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.directions_car_outlined,
            size: 36,
            color: AppColors.secondaryText,
          ),
          const SizedBox(height: 10),
          const Text(
            'No vehicles yet',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          const Text(
            'Add your vehicle to get started.',
            style: TextStyle(color: AppColors.secondaryText, fontSize: 13),
          ),
          const SizedBox(height: 14),
          TextButton(
            onPressed: () => _openVehicleSheet(),
            style: TextButton.styleFrom(foregroundColor: AppColors.primary),
            child: const Text('Add vehicle'),
          ),
        ],
      ),
    );
  }

  Widget _vehicleCard(Vehicle v) {
    final swatch = _colorFor(v.color);
    final subtitleParts = <String>[
      if (v.color.isNotEmpty) v.color,
      if (v.seatCapacity > 0)
        '${v.seatCapacity} ${v.seatCapacity == 1 ? 'seat' : 'seats'}',
    ];

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 14, 4, 14),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: swatch ?? _tint,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.divider, width: 1.5),
              ),
              child: Icon(
                Icons.directions_car_filled,
                size: 22,
                color: swatch == null
                    ? AppColors.primary
                    : (swatch.computeLuminance() > 0.5
                          ? AppColors.primary
                          : AppColors.background),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    v.displayName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppColors.black,
                    ),
                  ),
                  if (subtitleParts.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitleParts.join(', '),
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.secondaryText,
                      ),
                    ),
                  ],
                  const SizedBox(height: 10),
                  _plate(v.registrationNo),
                ],
              ),
            ),
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, color: AppColors.primary),
              color: AppColors.background,
              onSelected: (action) {
                if (action == 'edit') _openVehicleSheet(v);
                if (action == 'delete') _deleteVehicle(v);
              },
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'edit', child: Text('Edit')),
                PopupMenuItem(
                  value: 'delete',
                  child: Text(
                    'Delete',
                    style: TextStyle(color: AppColors.burntOrange),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Registration number styled like a number plate.
  Widget _plate(String regNo) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: _plateFill,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.primary, width: 1.5),
      ),
      child: Text(
        regNo,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.5,
          color: AppColors.black,
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Bottom sheets
// -----------------------------------------------------------------------------

class _SheetFrame extends StatelessWidget {
  const _SheetFrame({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.divider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 20),
            child,
          ],
        ),
      ),
    );
  }
}

/// Edit phone number sheet.
class _PhoneSheet extends StatefulWidget {
  const _PhoneSheet({this.initial});

  final int? initial;

  @override
  State<_PhoneSheet> createState() => _PhoneSheetState();
}

class _PhoneSheetState extends State<_PhoneSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    var text = widget.initial == null ? '' : '${widget.initial}';
    if (text.length > 10) text = text.substring(text.length - 10);
    _controller = TextEditingController(text: text);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    final parsed = int.tryParse(_controller.text.trim());
    if (parsed == null) return;
    Navigator.pop(context, parsed);
  }

  @override
  Widget build(BuildContext context) {
    return _SheetFrame(
      title: 'Phone number',
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            TextFormField(
              controller: _controller,
              autofocus: true,
              keyboardType: TextInputType.phone,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(10),
              ],
              style: const TextStyle(fontWeight: FontWeight.w600),
              decoration: const InputDecoration(
                labelText: 'Mobile number',
                prefixText: '+$_countryCode  ',
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) {
                  return 'Please enter your mobile number';
                }
                if (v.trim().length != 10) {
                  return 'Enter a 10-digit mobile number';
                }
                return null;
              },
              onFieldSubmitted: (_) => _save(),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _save,
              child: const Text('Save phone number'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Add or edit vehicle sheet.
class _VehicleSheet extends StatefulWidget {
  const _VehicleSheet({this.vehicle});

  final Vehicle? vehicle;

  @override
  State<_VehicleSheet> createState() => _VehicleSheetState();
}

class _VehicleSheetState extends State<_VehicleSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _make;
  late final TextEditingController _model;
  late final TextEditingController _reg;
  String _color = 'White';
  int _seats = 4;

  bool get _isEditing => widget.vehicle != null;

  @override
  void initState() {
    super.initState();
    final v = widget.vehicle;
    _make = TextEditingController(text: v?.make ?? '');
    _model = TextEditingController(text: v?.model ?? '');
    _reg = TextEditingController(text: v?.registrationNo ?? '');
    _color = (v?.color != null && v!.color.isNotEmpty) ? v.color : 'White';
    _seats = (v == null || v.seatCapacity < 1)
        ? 4
        : v.seatCapacity.clamp(1, 12);
  }

  @override
  void dispose() {
    _make.dispose();
    _model.dispose();
    _reg.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    if (_color.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a vehicle colour')),
      );
      return;
    }

    final base =
        widget.vehicle ??
        const Vehicle(
          id: '',
          ownerId: '',
          make: '',
          model: '',
          color: '',
          registrationNo: '',
          seatCapacity: 0,
        );

    Navigator.pop(
      context,
      base.copyWith(
        make: _make.text.trim(),
        model: _model.text.trim(),
        color: _color.trim(),
        registrationNo: _reg.text.trim().toUpperCase().replaceAll(
          RegExp(r'\s+'),
          ' ',
        ),
        seatCapacity: _seats,
      ),
    );
  }

  String? _required(String? v) =>
      (v == null || v.trim().isEmpty) ? 'Required' : null;

  @override
  Widget build(BuildContext context) {
    final colorNames = [
      ..._vehicleColors.keys,
      if (_color.isNotEmpty && _colorFor(_color) == null) _color,
    ];

    return _SheetFrame(
      title: _isEditing ? 'Edit vehicle' : 'Add vehicle',
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _make,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      labelText: 'Make',
                      hintText: 'Hyundai',
                    ),
                    validator: _required,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _model,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      labelText: 'Model',
                      hintText: 'Creta',
                    ),
                    validator: _required,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _reg,
              textCapitalization: TextCapitalization.characters,
              decoration: const InputDecoration(
                labelText: 'Registration number',
                hintText: 'DL 05 CD 5678',
              ),
              validator: _required,
            ),
            const SizedBox(height: 20),
            const Text(
              'Colour',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final name in colorNames)
                  ChoiceChip(
                    selected: _color.toLowerCase() == name.toLowerCase(),
                    onSelected: (_) => setState(() => _color = name),
                    showCheckmark: false,
                    backgroundColor: AppColors.card,
                    selectedColor: AppColors.amber,
                    side: BorderSide.none,
                    avatar: Container(
                      decoration: BoxDecoration(
                        color: _colorFor(name) ?? AppColors.divider,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.divider),
                      ),
                    ),
                    label: Text(
                      name,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.black,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Seats (including driver)',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                IconButton.outlined(
                  onPressed: _seats > 1 ? () => setState(() => _seats--) : null,
                  icon: const Icon(Icons.remove, size: 18),
                  color: AppColors.primary,
                ),
                SizedBox(
                  width: 36,
                  child: Text(
                    '$_seats',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                IconButton.outlined(
                  onPressed: _seats < 12
                      ? () => setState(() => _seats++)
                      : null,
                  icon: const Icon(Icons.add, size: 18),
                  color: AppColors.primary,
                ),
              ],
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _save,
              child: Text(_isEditing ? 'Save changes' : 'Add vehicle'),
            ),
          ],
        ),
      ),
    );
  }
}
