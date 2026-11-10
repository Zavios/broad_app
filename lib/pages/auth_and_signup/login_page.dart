import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../providers/auth_provider.dart';
import '../../themes/app_theme.dart';

// Login page for the B-road application.
class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  // Key used to validate the login form.
  final _formKey = GlobalKey<FormState>();

  // Controllers for the email and password input fields.
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  // Controls password visibility.
  bool _obscurePassword = true;

  @override
  void dispose() {
    // Release the controllers when the page is disposed.
    _emailController.dispose();
    _passwordController.dispose();
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
    );
  }

  /// Sign in with email and password.
  Future<void> _onLogin() async {
    if (!_formKey.currentState!.validate()) return;

    final success = await ref.read(authProvider.notifier).signIn(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );

    if (!mounted) return;

    if (success) {
      Navigator.pushReplacementNamed(context, '/home');
    } else {
      final error = ref.read(authProvider).error ?? 'Login failed';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error, style: const TextStyle(fontFamily: 'monospace')),
          backgroundColor: AppColors.burntOrange,
        ),
      );
    }
  }

  /// Launch Google OAuth URL in the browser.
  Future<void> _onGoogleLogin() async {
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

              // Main login heading.
              const Text(
                'Welcome\nBack!',
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
                'Login to your account',
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),

              const SizedBox(height: 46),

              // Scrollable form area for smaller screens.
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
                          // Store the entered email.
                          controller: _emailController,

                          // Show an email-friendly keyboard.
                          keyboardType: TextInputType.emailAddress,

                          style: const TextStyle(
                            fontFamily: 'monospace',
                            color: AppColors.primary,
                          ),

                          // Apply the common input styling.
                          decoration: _inputDecoration('example@mail.com'),

                          // Check that the email has a valid format.
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
                          // Store the entered password.
                          controller: _passwordController,

                          // Hide the password when visibility is disabled.
                          obscureText: _obscurePassword,

                          style: const TextStyle(
                            fontFamily: 'monospace',
                            color: AppColors.primary,
                          ),

                          // Add a visibility toggle to the input field.
                          decoration: _inputDecoration('Enter your password')
                              .copyWith(
                                suffixIcon: IconButton(
                                  onPressed: () {
                                    // Toggle between visible and hidden text.
                                    setState(() {
                                      _obscurePassword = !_obscurePassword;
                                    });
                                  },

                                  // Update the icon based on visibility.
                                  icon: Icon(
                                    _obscurePassword
                                        ? Icons.visibility_off_outlined
                                        : Icons.visibility_outlined,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ),

                          // Ensure that the password is not empty.
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your password';
                            }

                            return null;
                          },
                        ),

                        // ---------------- FORGOT PASSWORD ----------------
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () {
                              // Navigate to a password-reset flow.
                            },
                            child: const Text(
                              'Forgot password?',
                              style: TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 24),

                        // ---------------- LOGIN BUTTON ----------------
                        SizedBox(
                          height: 52,
                          child: ElevatedButton(
                            onPressed: isLoading ? null : _onLogin,

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
                                    'Login',
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

                        // Separate email login from Google login.
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

                        // ---------------- GOOGLE LOGIN BUTTON ----------------
                        SizedBox(
                          height: 52,
                          child: ElevatedButton(
                            onPressed: isLoading ? null : _onGoogleLogin,

                            // Use amber to match the signup page.
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.amber,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(17),
                              ),
                            ),

                            // Placeholder G; replace with the official
                            // Google logo when integrating Google Sign-In.
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

              // Keep the signup link at the bottom of the screen.
              Padding(
                padding: const EdgeInsets.only(top: 16, bottom: 10),
                child: Wrap(
                  alignment: WrapAlignment.center,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    const Text(
                      "Don't have an account? ",
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 14,
                        color: Color(0xFF888888),
                      ),
                    ),

                    GestureDetector(
                      onTap: () {
                        // Open the signup page.
                        Navigator.pushNamed(context, '/signup');
                      },
                      child: const Text(
                        'Sign up',
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
              ),
            ],
          ),
        ),
      ),
    );
  }
}
