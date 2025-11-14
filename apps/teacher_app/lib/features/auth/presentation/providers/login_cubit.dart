import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import '../../../../core/services/auth_service.dart';
import 'login_state.dart';

/// Cubit that handles login business logic
/// 
/// WHAT IS A CUBIT?
/// ----------------
/// A Cubit is a simplified version of BLoC (Business Logic Component).
/// Think of it as a "state manager" that:
/// 1. Holds current state
/// 2. Provides methods to change state
/// 3. Notifies UI when state changes
/// 
/// CUBIT VS BLOC:
/// - Cubit: Uses methods (login(), logout())
/// - BLoC: Uses events (LoginButtonPressed, LogoutButtonPressed)
/// - Cubit is simpler, BLoC is more structured
/// - We use Cubit here because login logic is straightforward
/// 
/// HOW IT WORKS:
/// ```
/// User presses button → UI calls cubit.login()
///                     ↓
///             Cubit calls AuthService
///                     ↓
///             Cubit emits new state
///                     ↓
///             UI rebuilds automatically
/// ```

class LoginCubit extends Cubit<LoginState> {
  /// Get AuthService from dependency injection
  /// 
  /// WHY DEPENDENCY INJECTION?
  /// Instead of creating AuthService here (tight coupling):
  ///   final authService = AuthService(); // Hard to test!
  /// 
  /// We get it from GetIt (loose coupling):
  ///   final authService = GetIt.instance<AuthService>(); // Easy to mock for testing!
  final AuthService _authService = GetIt.instance<AuthService>();

  /// Constructor - starts with initial state
  /// 
  /// When you create LoginCubit(), it starts with:
  /// - status: initial
  /// - errorMessage: null
  /// - userId: null
  /// - userEmail: null
  LoginCubit() : super(const LoginState());

  /// Login with email and password
  /// 
  /// This is called when user presses the "Login" button.
  /// 
  /// ASYNC/AWAIT EXPLANATION:
  /// - async: This function runs asynchronously (doesn't block UI)
  /// - await: Wait for this operation to complete before continuing
  /// - Future: A value that will be available in the future
  /// 
  /// Think of it like ordering food:
  /// - You place order (login request)
  /// - You wait (await)
  /// - Food arrives (response)
  /// - Meanwhile, you can do other things (UI stays responsive)
  Future<void> login({
    required String email,
    required String password,
  }) async {
    // Step 1: Emit loading state
    // This makes the UI show a loading spinner
    emit(state.copyWith(status: LoginStatus.loading));

    try {
      // Step 2: Call AuthService to login
      // This makes the API request to the backend
      final result = await _authService.login(
        email: email,
        password: password,
      );

      // Step 3: Check if login succeeded
      if (result.success) {
        // Success! Update state with user info
        emit(state.copyWith(
          status: LoginStatus.success,
          userId: result.userId,
          userEmail: result.email,
          errorMessage: null, // Clear any previous errors
        ));
      } else {
        // Failed! Update state with error message
        emit(state.copyWith(
          status: LoginStatus.failure,
          errorMessage: result.message,
        ));
      }
    } catch (e) {
      // Step 4: Handle unexpected errors
      // This catches any errors that weren't handled by AuthService
      emit(state.copyWith(
        status: LoginStatus.failure,
        errorMessage: 'An unexpected error occurred: $e',
      ));
    }
  }

  /// Logout
  /// 
  /// This clears the stored tokens and resets state.
  Future<void> logout() async {
    // Emit loading state while logging out
    emit(state.copyWith(status: LoginStatus.loading));

    try {
      // Call AuthService to clear tokens
      await _authService.logout();

      // Reset to initial state
      emit(const LoginState());
    } catch (e) {
      // Even if logout API fails, reset state
      // (we don't want user stuck logged in)
      emit(const LoginState());
    }
  }

  /// Check if user is already logged in
  /// 
  /// This is useful for:
  /// - App startup (auto-login if token exists)
  /// - Navigation guards (redirect to login if not authenticated)
  Future<void> checkAuthStatus() async {
    final isAuthenticated = await _authService.isAuthenticated();

    if (isAuthenticated) {
      // User has valid token, get their info
      final userId = await _authService.getCachedUserId();
      final email = await _authService.getCachedUserEmail();

      emit(state.copyWith(
        status: LoginStatus.success,
        userId: userId,
        userEmail: email,
      ));
    } else {
      // No valid token, stay on login page
      emit(const LoginState());
    }
  }

  /// Reset state to initial
  /// 
  /// Useful when navigating back to login page
  void reset() {
    emit(const LoginState());
  }
}

