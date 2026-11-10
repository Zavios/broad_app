import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../providers/auth_provider.dart';
import '../../themes/app_theme.dart';

// Signup page for the B-road application.
class SignupPage extends ConsumerStatefulWidget {
  const SignupPage({super.key});

  @override
  ConsumerState<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends ConsumerState<SignupPage> {
  // Key used to validate all fields in the signup form.
  final _formKey = GlobalKey<FormState>();

  // Controllers to access the values entered by the user.
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  // Controls whether the password is visible or hidden.
  bool _obscurePassword = true;

  @override
  void dispose() {
    // Dispose controllers to release resources when the page is removed.
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // Reusable input decoration to maintain consistent styling
  // for the email and password fields.
  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      // Placeholder displayed inside the input field.
      hintText: hint,
      hintStyle: const TextStyle(
        color: Color(0xFF96A393),
        fontSize: 16,
        fontWeight: FontWeight.w100,
      ),

      // Space between the text and the field borders.
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),

      // Border shown when the field is not focused.
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: AppColors.primary, width: 1),
      ),

      // Border shown when the user taps the field.
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.8),
      ),

      // Border shown when the field contains invalid data.
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: AppColors.burntOrange),
      ),

      // Border shown when an invalid field is focused.
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: AppColors.burntOrange),
      ),
    );
  }

  /// Sign up with email and password.
  Future<void> _onSignup() async {
    if (!_formKey.currentState!.validate()) return;

    final success = await ref.read(authProvider.notifier).signUp(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );

    if (!mounted) return;

    if (!success) {
      final error = ref.read(authProvider).error ?? 'Sign-up failed';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error, style: const TextStyle(fontFamily: 'monospace')),
          backgroundColor: AppColors.burntOrange,
        ),
      );
      return;
    }

    final authState = ref.read(authProvider);

    if (authState.isAuthenticated) {
      // Session was returned immediately — go to profile details.
      Navigator.pushReplacementNamed(context, '/profile_details');
    } else {
      // Email confirmation is required before a session is issued.
      showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: AppColors.background,
          title: const Text(
            'Confirm your email',
            style: TextStyle(
              fontFamily: 'monospace',
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
          content: const Text(
            'We sent a confirmation link to your email address. '
            'Please check your inbox and click the link to activate your account.',
            style: TextStyle(
              fontFamily: 'monospace',
              color: AppColors.black,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.pushReplacementNamed(context, '/login');
              },
              child: const Text(
                'Go to Login',
                style: TextStyle(
                  fontFamily: 'monospace',
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      );
    }
  }

  /// Launch Google OAuth URL in the browser.
  Future<void> _onGoogleSignup() async {
    final url = await ref.read(authProvider.notifier).getGoogleOAuthUrl();
    if (url == null || !mounted) return;
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final isLoading = authState.isLoading;

    return Scaffold(
      // Set the page background to the B-road cream color.
      backgroundColor: AppColors.background,

      body: SafeArea(
        // Prevent content from overlapping system UI.
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),

          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 32),

              // Back button aligned to the top-left corner.
              Align(
                alignment: Alignment.centerLeft,
                child: SizedBox(
                  width: 0,
                  height: 48,
                  child: IconButton(
                    // Return to the previous page.
                    onPressed: () => Navigator.pop(context),

                    icon: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: AppColors.black,
                      size: 27,
                    ),
                  ),
                ),
              ),

              // Space between the back button and heading.
              const SizedBox(height: 32),

              // Main heading displayed over two lines.
              const Text(
                "Lets get\nStarted!",
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 44,
                  height: 0.98,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                ),
              ),

              const SizedBox(height: 10),

              // Subtitle below the main heading.
              const Text(
                'Create a new account',
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),

              const SizedBox(height: 46),

              // The form area expands to use available vertical space.
              // It scrolls when the keyboard or a smaller screen reduces space.
              Expanded(
                child: SingleChildScrollView(
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // ---------------- EMAIL FIELD ----------------

                        const Text(
                          'Email*',
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 12,
                            color: AppColors.primary,
                          ),
                        ),

                        const SizedBox(height: 8),

                        TextFormField(
                          // Connect the field to its controller.
                          controller: _emailController,

                          // Display an email-friendly keyboard.
                          keyboardType: TextInputType.emailAddress,

                          style: const TextStyle(
                            fontFamily: 'monospace',
                            color: AppColors.primary,
                          ),

                          decoration: _inputDecoration('example@mail.com'),

                          // Validate the email before submission.
                          validator: (value) {
                            if (value == null ||
                                !RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$')
                                    .hasMatch(value.trim())) {
                              return 'Enter a valid email address';
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: 20),

                        // ---------------- PASSWORD FIELD ----------------
                        const Text(
                          'Password*',
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 12,
                            color: AppColors.primary,
                          ),
                        ),

                        const SizedBox(height: 8),

                        TextFormField(
                          controller: _passwordController,

                          // Hide or reveal the password based on the boolean.
                          obscureText: _obscurePassword,

                          style: const TextStyle(
                            fontFamily: 'monospace',
                            color: AppColors.primary,
                          ),

                          // Reuse the common field styling and add
                          // a visibility toggle on the right.
                          decoration: _inputDecoration('Enter your password')
                              .copyWith(
                                suffixIcon: IconButton(
                                  onPressed: () {
                                    // Toggle password visibility.
                                    setState(() {
                                      _obscurePassword = !_obscurePassword;
                                    });
                                  },

                                  // Change the icon to reflect visibility.
                                  icon: Icon(
                                    _obscurePassword
                                        ? Icons.visibility_off_outlined
                                        : Icons.visibility_outlined,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ),

                          // Require a minimum password length.
                          validator: (value) {
                            if (value == null || value.length < 8) {
                              return 'Use at least 8 characters';
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: 40),

                        // ---------------- SIGNUP BUTTON ----------------
                        SizedBox(
                          height: 52,
                          child: ElevatedButton(
                            onPressed: isLoading ? null : _onSignup,

                            // Apply the primary green button style.
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
                                    'Sign up',
                                    style: TextStyle(
                                      fontFamily: 'monospace',
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                          ),
                        ),

                        const SizedBox(height: 24),

                        // ---------------- OR DIVIDER ----------------

                        // Horizontal lines with OR centered between them.
                        const Row(
                          children: [
                            Expanded(child: Divider(color: Color(0xFF888888))),

                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 12),
                              child: Text(
                                'OR',
                                style: TextStyle(
                                  fontFamily: 'monospace',
                                  color: Color(0xFF888888),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),

                            Expanded(child: Divider(color: Color(0xFF888888))),
                          ],
                        ),

                        const SizedBox(height: 20),

                        // ---------------- GOOGLE SIGNUP BUTTON ----------------
                        SizedBox(
                          height: 52,
                          child: ElevatedButton(
                            onPressed: isLoading ? null : _onGoogleSignup,

                            // Amber background matches the B-road palette.
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.amber,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(17),
                              ),
                            ),

                            // G is a placeholder for the Google logo.
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'G',
                                  style: TextStyle(
                                    fontFamily: 'Arial',
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),

                                SizedBox(width: 12),

                                Text(
                                  'Google',
                                  style: TextStyle(
                                    fontFamily: 'monospace',
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // ---------------- BOTTOM FOOTER ----------------

              // Keep the login link and terms near the bottom of the screen.
              Padding(
                padding: const EdgeInsets.only(top: 16, bottom: 10),
                child: Column(
                  children: [
                    // Existing users can navigate to the login page.
                    Wrap(
                      alignment: WrapAlignment.center,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        const Text(
                          'Already have an account? ',
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 14,
                            color: Color(0xFF888888),
                          ),
                        ),

                        GestureDetector(
                          onTap: () {
                            // Navigate to the named login route.
                            Navigator.pushNamed(context, '/login');
                          },
                          child: const Text(
                            'Login',
                            style: TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 14,
                              color: AppColors.amber,
                              decoration: TextDecoration.underline,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 10),

                    // Terms and conditions acknowledgement.
                    Wrap(
                      alignment: WrapAlignment.center,
                      children: [
                        const Text(
                          'By signing up you agree to ',
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 12,
                            color: Color(0xFF999999),
                          ),
                        ),

                        GestureDetector(
                          onTap: () {
                            // Navigate to a terms page or open its URL.
                          },
                          child: const Text(
                            'Terms & Conditions',
                            style: TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 12,
                              color: Color(0xFF999999),
                              decoration: TextDecoration.underline,
                              fontWeight: FontWeight.bold,
                            ),
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
      ),
    );
  }
}
