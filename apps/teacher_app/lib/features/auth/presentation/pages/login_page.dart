import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../providers/login_cubit.dart';
import '../providers/login_state.dart';

/// Login page where teachers enter credentials
/// 
/// WIDGET STRUCTURE:
/// LoginPage (provides Cubit)
///   └─ _LoginForm (actual UI)
///        ├─ Email field
///        ├─ Password field
///        └─ Login button
/// 
/// WHY SPLIT INTO TWO WIDGETS?
/// - LoginPage: Provides the BLoC (created once)
/// - _LoginForm: Consumes the BLoC (can rebuild many times)
/// - This prevents recreating the Cubit on every rebuild

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    // BlocProvider creates and provides the LoginCubit
    // All child widgets can access it using context.read<LoginCubit>()
    return BlocProvider(
      create: (context) => LoginCubit()..checkAuthStatus(),
      child: const _LoginForm(),
    );
  }
}

/// The actual login form UI
/// 
/// This is a StatefulWidget because we need to:
/// - Store TextEditingController instances
/// - Store form validation state
/// - Show/hide password
class _LoginForm extends StatefulWidget {
  const _LoginForm();

  @override
  State<_LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<_LoginForm> {
  /// Controllers for text fields
  /// 
  /// WHY TEXT CONTROLLERS?
  /// TextEditingController lets us:
  /// - Get the current text: _emailController.text
  /// - Set text programmatically: _emailController.text = 'email@test.com'
  /// - Listen for changes: _emailController.addListener(...)
  /// - Clear text: _emailController.clear()
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  /// Form key for validation
  /// 
  /// The GlobalKey<FormState> lets us:
  /// - Validate all fields: _formKey.currentState?.validate()
  /// - Save all fields: _formKey.currentState?.save()
  /// - Reset form: _formKey.currentState?.reset()
  final _formKey = GlobalKey<FormState>();

  /// Track password visibility
  /// 
  /// When true, show password as text
  /// When false, show password as dots (•••)
  bool _obscurePassword = true;

  /// Track "Remember Me" checkbox state
  /// 
  /// EDUCATIONAL NOTE - Why separate from state?
  /// This is UI-only state (checkbox checked/unchecked).
  /// It doesn't need to be in BLoC state because:
  /// 1. Only this widget needs it
  /// 2. Doesn't affect other parts of app
  /// 3. Simpler to use setState() for UI-only state
  bool _rememberMe = false;

  @override
  void initState() {
    super.initState();
    // Auto-fill email if remembered from previous login
    // We do this in initState (runs once when widget is created)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final rememberedEmail = context.read<LoginCubit>().state.rememberedEmail;
      if (rememberedEmail != null) {
        _emailController.text = rememberedEmail;
        setState(() {
          _rememberMe = true; // Check the box since we have a remembered email
        });
      }
    });
  }

  @override
  void dispose() {
    // IMPORTANT: Always dispose controllers to prevent memory leaks!
    // 
    // Controllers keep listeners and resources in memory.
    // If we don't dispose them, they stay in memory even after widget is destroyed.
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // BlocListener listens for state changes and performs side effects
      // Side effects = things that aren't just UI updates (navigation, dialogs, etc.)
      body: BlocListener<LoginCubit, LoginState>(
        // When should we listen? When status changes to success or failure
        listener: (context, state) {
          if (state.isSuccess) {
            // Login succeeded! Navigate to home
            // 
            // context.go() replaces current page (can't go back to login)
            // context.push() adds new page (can go back)
            // We use go() because user shouldn't go back to login after logging in
            context.go('/home');
          } else if (state.isFailure) {
            // Login failed! Show error message
            // 
            // SnackBar is a temporary message at bottom of screen
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.errorMessage ?? 'Login failed'),
                backgroundColor: Colors.red,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        },
        // BlocBuilder rebuilds UI when state changes
        child: BlocBuilder<LoginCubit, LoginState>(
          builder: (context, state) {
            return Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // App logo/title
                      const Icon(
                        Icons.school,
                        size: 80,
                        color: Colors.blue,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Co-Teacher',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Teacher Login',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: Colors.grey[600],
                            ),
                      ),
                      const SizedBox(height: 48),

                      // Email field
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          labelText: 'Email',
                          hintText: 'teacher@school.com',
                          prefixIcon: Icon(Icons.email),
                          border: OutlineInputBorder(),
                        ),
                        // Validation function
                        // Returns null if valid, returns error message if invalid
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your email';
                          }
                          // Basic email validation
                          if (!value.contains('@')) {
                            return 'Please enter a valid email';
                          }
                          return null; // Valid!
                        },
                        // Disable field while loading
                        enabled: !state.isLoading,
                      ),
                      const SizedBox(height: 16),

                      // Password field
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        decoration: InputDecoration(
                          labelText: 'Password',
                          hintText: 'Enter your password',
                          prefixIcon: const Icon(Icons.lock),
                          border: const OutlineInputBorder(),
                          // Eye icon to show/hide password
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword ? Icons.visibility : Icons.visibility_off,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your password';
                          }
                          if (value.length < 6) {
                            return 'Password must be at least 6 characters';
                          }
                          return null;
                        },
                        enabled: !state.isLoading,
                      ),
                      const SizedBox(height: 16),

                      // Remember Me checkbox
                      // 
                      // EDUCATIONAL NOTE - CheckboxListTile:
                      // This is a pre-built widget that combines:
                      // - Checkbox (the box you click)
                      // - Text label (what it means)
                      // - Tap handling (can tap text OR box)
                      // 
                      // Much easier than building these separately!
                      CheckboxListTile(
                        title: const Text('Remember Me'),
                        subtitle: Text(
                          'Save email for next login',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                        value: _rememberMe,
                        onChanged: state.isLoading
                            ? null
                            : (value) {
                                // Update checkbox state
                                // 
                                // setState() tells Flutter to rebuild this widget
                                // with the new _rememberMe value
                                setState(() {
                                  _rememberMe = value ?? false;
                                });
                              },
                        controlAffinity: ListTileControlAffinity.leading,
                        contentPadding: EdgeInsets.zero,
                      ),
                      const SizedBox(height: 8),

                      // Login button
                      ElevatedButton(
                        onPressed: state.isLoading
                            ? null // Disable button while loading
                            : () {
                                // Validate form
                                if (_formKey.currentState?.validate() ?? false) {
                                  // Form is valid, proceed with login
                                  // 
                                  // NEW: Pass rememberMe parameter
                                  context.read<LoginCubit>().login(
                                        email: _emailController.text.trim(),
                                        password: _passwordController.text,
                                        rememberMe: _rememberMe,
                                      );
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: state.isLoading
                            // Show loading spinner while logging in
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : const Text(
                                'Login',
                                style: TextStyle(fontSize: 16),
                              ),
                      ),
                      const SizedBox(height: 16),

                      // Forgot password link
                      TextButton(
                        onPressed: state.isLoading
                            ? null
                            : () {
                                // Navigate to forgot password page
                                context.push('/forgot-password');
                              },
                        child: const Text('Forgot Password?'),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
