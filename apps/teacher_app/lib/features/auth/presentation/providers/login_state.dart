import 'package:equatable/equatable.dart';

/// State for the login page
/// 
/// EDUCATIONAL NOTE - Why use a state class?
/// -----------------------------------------
/// Instead of having multiple variables scattered around (isLoading, error, user),
/// we bundle everything into ONE immutable state object. This makes it easier to:
/// 1. Track what's happening (are we loading? did we get an error?)
/// 2. Rebuild UI when state changes
/// 3. Test our code (we can create test states easily)
/// 
/// The BLoC pattern uses this approach:
/// - UI sends "events" (e.g., "user pressed login button")
/// - BLoC processes event and emits new "state"
/// - UI rebuilds based on new state
/// 
/// Think of it like a traffic light:
/// - State can be: Red, Yellow, or Green
/// - Car (UI) reacts differently to each state
/// - Signal controller (BLoC) changes the state

/// Enum to track the status of login operation
/// 
/// WHY USE ENUMS?
/// Enums are like multiple choice options - you can only pick one valid option.
/// This prevents bugs like having isLoading=true AND isSuccess=true at the same time.
enum LoginStatus {
  initial,    // Default state, nothing has happened yet
  loading,    // Login request is in progress
  success,    // Login succeeded!
  failure,    // Login failed (wrong password, network error, etc.)
}

/// The complete state of the login page
/// 
/// EQUATABLE EXPLANATION:
/// By extending Equatable, we can easily compare states:
/// - LoginState(status: loading) == LoginState(status: loading) // true
/// - LoginState(status: loading) == LoginState(status: success) // false
/// 
/// This is crucial for BLoC - it only rebuilds UI when state ACTUALLY changes.
class LoginState extends Equatable {
  /// Current status of the login process
  final LoginStatus status;
  
  /// Error message if login failed
  /// null means no error
  final String? errorMessage;
  
  /// User ID after successful login
  /// null until login succeeds
  final String? userId;
  
  /// User email after successful login
  /// null until login succeeds
  final String? userEmail;

  /// Remembered email from last login
  /// Used to auto-fill email field if "Remember Me" was checked
  /// 
  /// EDUCATIONAL NOTE - Why store this?
  /// When user checks "Remember Me" and logs in successfully,
  /// we save their email. Next time they open the app, we can
  /// auto-fill this field to save them time.
  final String? rememberedEmail;

  const LoginState({
    this.status = LoginStatus.initial,
    this.errorMessage,
    this.userId,
    this.userEmail,
    this.rememberedEmail,
  });

  /// Create a copy of this state with some fields changed
  /// 
  /// WHY COPYUITH?
  /// States are immutable (can't be changed after creation).
  /// To "change" a state, we create a NEW state with updated values.
  /// 
  /// Example:
  /// ```dart
  /// final state1 = LoginState(status: LoginStatus.initial);
  /// final state2 = state1.copyWith(status: LoginStatus.loading);
  /// // state1 is unchanged, state2 is a new state with loading status
  /// ```
  /// 
  /// This is like creating a new version of a document instead of editing it.
  LoginState copyWith({
    LoginStatus? status,
    String? errorMessage,
    String? userId,
    String? userEmail,
    String? rememberedEmail,
  }) {
    return LoginState(
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
      userId: userId ?? this.userId,
      userEmail: userEmail ?? this.userEmail,
      rememberedEmail: rememberedEmail ?? this.rememberedEmail,
    );
  }

  /// Tell Equatable which fields to use for comparison
  /// 
  /// When comparing two LoginStates, Equatable checks if these fields are equal.
  /// If all fields match, the states are considered equal (no UI rebuild needed).
  @override
  List<Object?> get props => [status, errorMessage, userId, userEmail, rememberedEmail];

  /// Convenience getters for checking status
  /// 
  /// Instead of: state.status == LoginStatus.loading
  /// We can write: state.isLoading
  /// 
  /// Makes code more readable!
  bool get isInitial => status == LoginStatus.initial;
  bool get isLoading => status == LoginStatus.loading;
  bool get isSuccess => status == LoginStatus.success;
  bool get isFailure => status == LoginStatus.failure;
}

