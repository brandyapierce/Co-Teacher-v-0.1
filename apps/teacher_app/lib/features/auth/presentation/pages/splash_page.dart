import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:get_it/get_it.dart';
import '../../../../core/services/auth_service.dart';

/// Splash screen that shows while checking authentication
/// 
/// EDUCATIONAL NOTE - Why a splash screen?
/// ---------------------------------------
/// The splash screen serves multiple purposes:
/// 1. Check if user is already logged in (has valid token)
/// 2. Initialize app services
/// 3. Show app branding while loading
/// 4. Smooth transition into the app
/// 
/// FLOW:
/// App starts → Splash shows → Check auth
///   ├─ If logged in → Navigate to /home
///   └─ If not logged in → Navigate to /login

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    _checkAuthentication();
  }

  /// Check if user is authenticated and navigate accordingly
  /// 
  /// WHY ASYNC IN initState?
  /// We can't make initState async, so we call an async method from it.
  /// The method runs in the background while the splash screen shows.
  Future<void> _checkAuthentication() async {
    // Get AuthService from dependency injection
    final authService = GetIt.instance<AuthService>();

    // Wait a minimum of 1 second for better UX
    // (so user can see the splash screen - feels more polished)
    await Future.delayed(const Duration(seconds: 1));

    // Check if user has valid token
    final isAuthenticated = await authService.isAuthenticated();

    // Make sure widget is still mounted before navigating
    // (user might have closed the app during the delay)
    if (!mounted) return;

    if (isAuthenticated) {
      // User is logged in! Go straight to home
      context.go('/home');
    } else {
      // User needs to login
      context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.school,
              size: 100,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 24),
            Text(
              'My AI CoTeacher',
              style: Theme.of(context).textTheme.headlineLarge,
            ),
            const SizedBox(height: 8),
            const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}

