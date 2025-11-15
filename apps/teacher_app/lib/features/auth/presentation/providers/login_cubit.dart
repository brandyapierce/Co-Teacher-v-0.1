import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
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

  /// Keys for storing preferences
  /// 
  /// EDUCATIONAL NOTE - SharedPreferences Keys:
  /// These are like variable names for storing data locally.
  /// Using constants prevents typos and makes it easy to change later.
  static const String _rememberMeKey = 'remember_me';
  static const String _rememberedEmailKey = 'remembered_email';

  /// Constructor - starts with initial state and loads saved email
  /// 
  /// When you create LoginCubit(), it:
  /// 1. Starts with initial state
  /// 2. Loads any remembered email from storage
  LoginCubit() : super(const LoginState()) {
    _loadRememberedEmail();
  }

  /// Load remembered email if "Remember Me" was checked previously
  /// 
  /// WHY ASYNC IN CONSTRUCTOR?
  /// We can't make constructor async, so we call this method instead.
  /// It runs in the background and updates state when done.
  Future<void> _loadRememberedEmail() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final rememberMe = prefs.getBool(_rememberMeKey) ?? false;
      
      if (rememberMe) {
        final email = prefs.getString(_rememberedEmailKey);
        if (email != null && email.isNotEmpty) {
          // Update state with remembered email
          emit(state.copyWith(rememberedEmail: email));
        }
      }
    } catch (e) {
      // If loading fails, just continue without remembered email
      // Not critical enough to show error to user
    }
  }

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
  /// 
  /// NEW: rememberMe parameter
  /// If true, saves email for next login
  Future<void> login({
    required String email,
    required String password,
    bool rememberMe = false,
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
        // Step 3a: Save email if "Remember Me" is checked
        // 
        // EDUCATIONAL NOTE - Why save here?
        // We only save after successful login, not on every attempt.
        // This prevents saving wrong emails.
        await _saveRememberMePreference(rememberMe, email);
        
        // Step 3b: Update state with user info
        emit(state.copyWith(
          status: LoginStatus.success,
          userId: result.userId,
          userEmail: result.email,
          errorMessage: null, // Clear any previous errors
          rememberedEmail: rememberMe ? email : null,
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

  /// Reset state to initial (but keep remembered email)
  /// 
  /// Useful when navigating back to login page
  void reset() {
    emit(LoginState(rememberedEmail: state.rememberedEmail));
  }

  /// Save "Remember Me" preference to local storage
  /// 
  /// EDUCATIONAL NOTE - SharedPreferences:
  /// SharedPreferences is like a simple key-value database:
  /// - Stores primitive types (bool, String, int, etc.)
  /// - Survives app restarts
  /// - Fast and easy to use
  /// - Not encrypted (don't store passwords here!)
  /// 
  /// HOW IT WORKS:
  /// ```
  /// // Save
  /// prefs.setBool('remember_me', true);
  /// 
  /// // Load
  /// bool rememberMe = prefs.getBool('remember_me') ?? false;
  /// ```
  Future<void> _saveRememberMePreference(bool rememberMe, String email) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      if (rememberMe) {
        // Save both the preference and the email
        await prefs.setBool(_rememberMeKey, true);
        await prefs.setString(_rememberedEmailKey, email);
      } else {
        // User unchecked "Remember Me", clear saved data
        await prefs.remove(_rememberMeKey);
        await prefs.remove(_rememberedEmailKey);
      }
    } catch (e) {
      // If saving fails, just continue
      // Not critical enough to fail the login
    }
  }

  /// Clear remembered email (for "Forgot Email" or logout)
  Future<void> clearRememberedEmail() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_rememberMeKey);
      await prefs.remove(_rememberedEmailKey);
      emit(state.copyWith(rememberedEmail: null));
    } catch (e) {
      // Ignore errors
    }
  }
}

