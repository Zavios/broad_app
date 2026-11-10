import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:broad_app/pages/auth_and_signup/landing_page.dart';
import 'package:broad_app/pages/auth_and_signup/login_page.dart';
import 'package:broad_app/pages/auth_and_signup/signup_page.dart';
import 'package:broad_app/pages/homepage.dart';
import 'package:broad_app/pages/auth_and_signup/profile_details_page.dart';
import 'package:broad_app/providers/auth_provider.dart';
import 'package:broad_app/themes/app_theme.dart';

void main() {
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      routes: {
        '/home': (context) => const Homepage(),
        '/login': (context) => const LoginPage(),
        '/signup': (context) => const SignupPage(),
        '/profile_details': (context) => const ProfileDetailsPage(),
      },
      theme: AppTheme.lightTheme,
      home: const _AuthGate(),
    );
  }
}

/// Checks stored auth token on startup, then routes to the correct screen.
class _AuthGate extends ConsumerStatefulWidget {
  const _AuthGate();

  @override
  ConsumerState<_AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends ConsumerState<_AuthGate> {
  @override
  void initState() {
    super.initState();
    // Check if the user already has a saved session.
    Future.microtask(
      () => ref.read(authProvider.notifier).checkAuthStatus(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);

    if (auth.isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    if (auth.isAuthenticated) {
      return const Homepage();
    }

    return const LandingPage();
  }
}
