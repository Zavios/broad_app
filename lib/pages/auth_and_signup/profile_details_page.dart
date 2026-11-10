import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/auth_provider.dart';
import '../../providers/profile_provider.dart';
import '../../themes/app_theme.dart';

// Page that collects the user's personal details after signup.
class ProfileDetailsPage extends ConsumerStatefulWidget {
  const ProfileDetailsPage({super.key});

  @override
  ConsumerState<ProfileDetailsPage> createState() =>
      _ProfileDetailsPageState();
}

class _ProfileDetailsPageState extends ConsumerState<ProfileDetailsPage> {
  // Key used to validate the form.
  final _formKey = GlobalKey<FormState>();

  // Controllers for the input fields.
  final _usernameController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _dobController = TextEditingController();
  final _phoneController = TextEditingController();
  final _bioController = TextEditingController();

  // The date selected in the date picker.
  DateTime? _dob;

  @override
  void dispose() {
    // Release the controllers when the page is disposed.
    _usernameController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _dobController.dispose();
    _phoneController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  // Reusable decoration for the input fields.
  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      // Placeholder text inside the input field.
      hintText: hint,
      hintStyle: const TextStyle(
        color: Color(0xFF96A393),
        fontSize: 16,
        fontWeight: FontWeight.w100,
      ),

      // Remove the default filled background from the theme.
      filled: false,

      // Inner spacing of the text field.
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 18),

      // Border when the field is not selected.
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: AppColors.primary, width: 1),
      ),

      // Border when the field is selected.
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.8),
      ),

      // Border for invalid input.
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: AppColors.burntOrange),
      ),

      // Border when an invalid field is focused.
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: AppColors.burntOrange),
      ),

      // Error text style.
      errorStyle: const TextStyle(
        fontFamily: 'monospace',
        color: AppColors.burntOrange,
      ),
    );
  }

  // Reusable label shown above each field.
  Widget _label(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: const TextStyle(
          fontFamily: 'monospace',
          fontSize: 12,
          color: AppColors.primary,
        ),
      ),
    );
  }

  // Shared text style for entered text.
  static const TextStyle _inputStyle = TextStyle(
    fontFamily: 'monospace',
    color: AppColors.primary,
  );

  // Formats a date as YYYY-MM-DD for the API.
  String _apiFormatDate(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }

  // Formats a date as DD/MM/YYYY for display.
  String _displayFormatDate(DateTime date) {
    final d = date.day.toString().padLeft(2, '0');
    final m = date.month.toString().padLeft(2, '0');
    return '$d/$m/${date.year}';
  }

  // Opens the date picker and stores the selected date.
  Future<void> _pickDob() async {
    final now = DateTime.now();

    final picked = await showDatePicker(
      context: context,
      initialDate: _dob ?? DateTime(now.year - 18, now.month, now.day),
      firstDate: DateTime(1900),
      lastDate: now,

      // Style the picker with the B-road palette.
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

    if (picked != null) {
      setState(() {
        _dob = picked;
        _dobController.text = _displayFormatDate(picked);
      });
    }
  }

  // Validates the form and submits the details.
  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final email = ref.read(authProvider).user?.email ?? '';

    // Strip all non-digit characters then parse as int (backend expects smallint).
    final phoneDigits =
        _phoneController.text.replaceAll(RegExp(r'\D'), '');
    final phone = int.tryParse(phoneDigits) ?? 0;

    final success = await ref.read(profileProvider.notifier).createProfile(
          username: _usernameController.text.trim(),
          firstName: _firstNameController.text.trim(),
          lastName: _lastNameController.text.trim(),
          email: email,
          dob: _apiFormatDate(_dob!),
          phone: phone,
          bio: _bioController.text.trim().isEmpty
              ? null
              : _bioController.text.trim(),
        );

    if (!mounted) return;

    if (success) {
      Navigator.pushReplacementNamed(context, '/home');
    } else {
      final error =
          ref.read(profileProvider).error ?? 'Failed to create profile';
      // Handle 409 conflict gracefully.
      if (error.toLowerCase().contains('already') ||
          error.toLowerCase().contains('conflict') ||
          error.toLowerCase().contains('409')) {
        Navigator.pushReplacementNamed(context, '/home');
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text(error, style: const TextStyle(fontFamily: 'monospace')),
          backgroundColor: AppColors.burntOrange,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileState = ref.watch(profileProvider);
    final isLoading = profileState.isLoading;

    return Scaffold(
      // Use the B-road cream background.
      backgroundColor: AppColors.background,

      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),

          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 32),

              // Back button in the top-left corner.
              Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(
                    Icons.arrow_back_ios_new_rounded,
                    size: 24,
                    color: AppColors.black,
                  ),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 40,
                    minHeight: 40,
                  ),
                  alignment: Alignment.centerLeft,
                ),
              ),

              const SizedBox(height: 32),

              // Main heading.
              const Text(
                'Tell us\nabout you',
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 44,
                  height: 0.98,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                ),
              ),

              const SizedBox(height: 10),

              // Subtitle below the heading.
              const Text(
                'Complete your profile',
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),

              const SizedBox(height: 32),

              // Scrollable form area for smaller screens.
              Expanded(
                child: SingleChildScrollView(
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // ---------------- USERNAME ----------------
                        _label('Username*'),

                        TextFormField(
                          controller: _usernameController,
                          keyboardType: TextInputType.text,
                          textInputAction: TextInputAction.next,
                          style: _inputStyle,
                          decoration: _inputDecoration('john_doe'),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter a username';
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: 20),

                        // ---------------- FIRST NAME ----------------
                        _label('First name*'),

                        TextFormField(
                          controller: _firstNameController,
                          keyboardType: TextInputType.name,
                          textCapitalization: TextCapitalization.words,
                          textInputAction: TextInputAction.next,
                          style: _inputStyle,
                          decoration: _inputDecoration('John'),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter your first name';
                            }

                            return null;
                          },
                        ),

                        const SizedBox(height: 20),

                        // ---------------- LAST NAME ----------------
                        _label('Last name*'),

                        TextFormField(
                          controller: _lastNameController,
                          keyboardType: TextInputType.name,
                          textCapitalization: TextCapitalization.words,
                          textInputAction: TextInputAction.next,
                          style: _inputStyle,
                          decoration: _inputDecoration('Doe'),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter your last name';
                            }

                            return null;
                          },
                        ),

                        const SizedBox(height: 20),

                        // ---------------- DATE OF BIRTH ----------------
                        _label('Date of birth*'),

                        TextFormField(
                          controller: _dobController,

                          // Prevent typing; the value comes from the picker.
                          readOnly: true,
                          onTap: _pickDob,
                          style: _inputStyle,
                          decoration: _inputDecoration('DD/MM/YYYY').copyWith(
                            suffixIcon: const Icon(
                              Icons.calendar_today_outlined,
                              color: AppColors.primary,
                              size: 20,
                            ),
                          ),
                          validator: (value) {
                            if (_dob == null) {
                              return 'Please select your date of birth';
                            }

                            return null;
                          },
                        ),

                        const SizedBox(height: 20),

                        // ---------------- PHONE ----------------
                        _label('Phone*'),

                        TextFormField(
                          controller: _phoneController,

                          // Show a phone-friendly keyboard.
                          keyboardType: TextInputType.phone,
                          textInputAction: TextInputAction.next,
                          style: _inputStyle,

                          // Allow only digits, +, spaces and dashes.
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                              RegExp(r'[0-9+\-\s]'),
                            ),
                          ],
                          decoration: _inputDecoration('+91 98765 43210'),

                          // Require between 7 and 15 digits.
                          validator: (value) {
                            final digits = (value ?? '').replaceAll(
                              RegExp(r'\D'),
                              '',
                            );

                            if (digits.length < 7 || digits.length > 15) {
                              return 'Enter a valid phone number';
                            }

                            return null;
                          },
                        ),

                        const SizedBox(height: 20),

                        // ---------------- BIO ----------------
                        _label('Bio'),

                        TextFormField(
                          controller: _bioController,
                          keyboardType: TextInputType.multiline,
                          textCapitalization: TextCapitalization.sentences,
                          minLines: 4,
                          maxLines: 6,
                          maxLength: 200,
                          style: _inputStyle,
                          decoration: _inputDecoration(
                            'Tell us a little about yourself',
                          ),
                        ),

                        const SizedBox(height: 16),

                        // ---------------- SUBMIT BUTTON ----------------
                        SizedBox(
                          height: 52,
                          child: ElevatedButton(
                            onPressed: isLoading ? null : _submit,

                            // Use the B-road forest green button style.
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: AppColors.background,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(17),
                              ),
                            ),

                            child: isLoading
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                      color: AppColors.background,
                                      strokeWidth: 2.5,
                                    ),
                                  )
                                : const Text(
                                    'Continue',
                                    style: TextStyle(
                                      fontFamily: 'monospace',
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                          ),
                        ),

                        const SizedBox(height: 24),
                      ],
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
}
