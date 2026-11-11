import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/maps_model.dart';
import '../providers/maps_provider.dart';
import '../services/maps_service.dart';
import '../themes/app_theme.dart';

/// Result returned when the user selects a location.
class LocationResult {
  final String displayName;
  final double lat;
  final double lng;

  const LocationResult({
    required this.displayName,
    required this.lat,
    required this.lng,
  });
}

/// A modal bottom sheet that provides live place autocomplete search.
/// Usage:
/// ```dart
/// final result = await showModalBottomSheet<LocationResult>(
///   context: context,
///   isScrollControlled: true,
///   builder: (_) => const LocationSearchSheet(title: 'Start location'),
/// );
/// ```
class LocationSearchSheet extends ConsumerStatefulWidget {
  /// Title shown at the top of the sheet.
  final String title;

  const LocationSearchSheet({super.key, required this.title});

  @override
  ConsumerState<LocationSearchSheet> createState() =>
      _LocationSearchSheetState();
}

class _LocationSearchSheetState extends ConsumerState<LocationSearchSheet> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();

  Timer? _debounce;
  bool _isGeocoding = false;
  String? _geocodeError;

  @override
  void initState() {
    super.initState();
    // Clear any previous suggestions when opening the sheet.
    Future.microtask(() {
      if (mounted) {
        ref.read(autocompleteProvider.notifier).clear();
      }
    });
    // Auto-focus the text field when the sheet opens.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  /// Triggered on every keystroke; debounced to 300 ms.
  void _onSearchChanged(String query) {
    _debounce?.cancel();
    if (query.trim().isEmpty) {
      ref.read(autocompleteProvider.notifier).clear();
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (!mounted) return;
      ref.read(autocompleteProvider.notifier).search(query.trim());
    });
  }

  /// Called when the user taps a suggestion.
  Future<void> _onSuggestionTap(PlaceSuggestion suggestion) async {
    _focusNode.unfocus();
    setState(() {
      _isGeocoding = true;
      _geocodeError = null;
    });

    try {
      final location = await MapsService().geocode(suggestion.fullText);
      if (mounted) {
        Navigator.pop(
          context,
          LocationResult(
            displayName: suggestion.mainText,
            lat: location.latitude,
            lng: location.longitude,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isGeocoding = false;
          _geocodeError = 'Could not get coordinates. Try again.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final acState = ref.watch(autocompleteProvider);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      // Sheet height: 60% of screen + keyboard inset
      height: MediaQuery.of(context).size.height * 0.6 + bottomInset,
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ---- Handle bar ----
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // ---- Title ----
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Text(
              widget.title,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
          ),

          // ---- Search field ----
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: _controller,
              focusNode: _focusNode,
              onChanged: _onSearchChanged,
              style: const TextStyle(
                fontFamily: 'monospace',
                color: AppColors.black,
              ),
              decoration: InputDecoration(
                hintText: 'Search for a place…',
                hintStyle: const TextStyle(
                  fontFamily: 'monospace',
                  color: AppColors.secondaryText,
                ),
                prefixIcon: const Icon(
                  Icons.search_rounded,
                  color: AppColors.primary,
                ),
                suffixIcon: _controller.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(
                          Icons.clear,
                          color: AppColors.secondaryText,
                          size: 18,
                        ),
                        onPressed: () {
                          _controller.clear();
                          ref.read(autocompleteProvider.notifier).clear();
                          setState(() {});
                        },
                      )
                    : null,
                filled: true,
                fillColor: AppColors.card,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 14,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(
                    color: AppColors.primary,
                    width: 1.5,
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 8),

          // ---- Suggestions list / states ----
          Expanded(child: _buildBody(acState)),
        ],
      ),
    );
  }

  Widget _buildBody(AutocompleteState state) {
    // Geocoding in progress after selection
    if (_isGeocoding) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    // Geocode failed
    if (_geocodeError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.location_off_outlined,
                color: AppColors.burntOrange,
                size: 40,
              ),
              const SizedBox(height: 8),
              Text(
                _geocodeError!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  color: AppColors.burntOrange,
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => setState(() => _geocodeError = null),
                child: const Text(
                  'Try again',
                  style: TextStyle(
                    fontFamily: 'monospace',
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Loading suggestions
    if (state.isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    // Empty state — no input yet
    if (_controller.text.trim().isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.place_outlined, size: 48, color: AppColors.divider),
            SizedBox(height: 8),
            Text(
              'Start typing to search',
              style: TextStyle(
                fontFamily: 'monospace',
                color: AppColors.secondaryText,
              ),
            ),
          ],
        ),
      );
    }

    // No suggestions found
    if (state.suggestions.isEmpty) {
      return const Center(
        child: Text(
          'No places found.',
          style: TextStyle(
            fontFamily: 'monospace',
            color: AppColors.secondaryText,
          ),
        ),
      );
    }

    // Suggestions list
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      itemCount: state.suggestions.length,
      separatorBuilder: (_, __) =>
          const Divider(color: AppColors.divider, height: 1),
      itemBuilder: (context, index) {
        final s = state.suggestions[index];
        return ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 4,
            vertical: 4,
          ),
          leading: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.place_outlined,
              color: AppColors.primary,
              size: 20,
            ),
          ),
          title: Text(
            s.mainText,
            style: const TextStyle(
              fontFamily: 'monospace',
              fontWeight: FontWeight.bold,
              color: AppColors.black,
              fontSize: 14,
            ),
          ),
          subtitle: Text(
            s.secondaryText,
            style: const TextStyle(
              fontFamily: 'monospace',
              color: AppColors.secondaryText,
              fontSize: 12,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          onTap: () => _onSuggestionTap(s),
        );
      },
    );
  }
}

/// Convenience helper to open the location search sheet.
Future<LocationResult?> showLocationSearchSheet(
  BuildContext context, {
  required String title,
}) {
  return showModalBottomSheet<LocationResult>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => LocationSearchSheet(title: title),
  );
}
