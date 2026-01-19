import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/responsive_utils.dart';
import '../providers/login_cubit.dart';
import '../providers/login_state.dart';

/// =============================================================================
/// LOGIN PAGE - TABLET-OPTIMIZED
/// =============================================================================
/// 
/// LEARNING GUIDE: Building a Tablet-Friendly Login
/// 
/// TABLET CONSIDERATIONS:
/// 1. Larger touch targets (56dp+ buttons and inputs)
/// 2. Centered, constrained form width (not stretched across screen)
/// 3. Bigger fonts for arm's length viewing
/// 4. Visual feedback for touch interactions
/// 5. Landscape-friendly layout
/// 
/// ARCHITECTURE:
/// LoginPage (StatelessWidget)
///   └─ BlocProvider<LoginCubit>  ← Creates state management
///        └─ _LoginForm (StatefulWidget)  ← Handles form state
///             ├─ BlocListener  ← Handles navigation/errors
///             └─ BlocBuilder   ← Rebuilds UI on state change
/// =============================================================================

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => LoginCubit()..checkAuthStatus(),
      child: const _LoginForm(),
    );
  }
}

class _LoginForm extends StatefulWidget {
  const _LoginForm();

  @override
  State<_LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<_LoginForm> with SingleTickerProviderStateMixin {
  // Controllers for form fields
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  
  // UI state
  bool _obscurePassword = true;
  bool _rememberMe = false;
  
  // Animation controller for smooth transitions
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    
    // Setup entrance animations
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    );
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));
    
    // Start animation
    _animationController.forward();
    
    // Load remembered email
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final rememberedEmail = context.read<LoginCubit>().state.rememberedEmail;
      if (rememberedEmail != null) {
        _emailController.text = rememberedEmail;
        setState(() => _rememberMe = true);
      }
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isTablet = context.isTablet;
    
    return Scaffold(
      body: BlocListener<LoginCubit, LoginState>(
        listener: (context, state) {
          if (state.isSuccess) {
            context.go('/home');
          } else if (state.isFailure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const Icon(Icons.error_outline, color: Colors.white),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        state.errorMessage ?? 'Login failed',
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                  ],
                ),
                backgroundColor: colorScheme.error,
                behavior: SnackBarBehavior.floating,
                margin: EdgeInsets.all(isTablet ? 24 : 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            );
          }
        },
        child: BlocBuilder<LoginCubit, LoginState>(
          builder: (context, state) {
            return Container(
              // Beautiful gradient background
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    colorScheme.primaryContainer.withOpacity(0.3),
                    colorScheme.surface,
                    colorScheme.secondaryContainer.withOpacity(0.2),
                  ],
                ),
              ),
              child: SafeArea(
                child: Center(
                  child: SingleChildScrollView(
                    padding: context.responsivePadding,
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: SlideTransition(
                        position: _slideAnimation,
                        child: _buildLoginCard(context, state, isTablet),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildLoginCard(BuildContext context, LoginState state, bool isTablet) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxWidth: isTablet ? 480 : double.infinity,
      ),
      child: Card(
        elevation: isTablet ? 8 : 4,
        shadowColor: colorScheme.shadow.withOpacity(0.3),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        ),
        child: Padding(
          padding: EdgeInsets.all(isTablet ? 40 : 24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Logo and title
                _buildHeader(context, isTablet),
                SizedBox(height: isTablet ? 40 : 32),
                
                // Email field
                _buildEmailField(context, state, isTablet),
                SizedBox(height: isTablet ? 20 : 16),
                
                // Password field
                _buildPasswordField(context, state, isTablet),
                SizedBox(height: isTablet ? 16 : 12),
                
                // Remember me checkbox
                _buildRememberMe(context, state, isTablet),
                SizedBox(height: isTablet ? 28 : 20),
                
                // Login button
                _buildLoginButton(context, state, isTablet),
                SizedBox(height: isTablet ? 20 : 16),
                
                // Forgot password
                _buildForgotPassword(context, state, isTablet),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isTablet) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Column(
      children: [
        // Animated logo container
        Container(
          width: isTablet ? 100 : 80,
          height: isTablet ? 100 : 80,
          decoration: BoxDecoration(
            color: colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
            boxShadow: [
              BoxShadow(
                color: colorScheme.primary.withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Icon(
            Icons.school_rounded,
            size: isTablet ? 56 : 44,
            color: colorScheme.primary,
          ),
        ),
        SizedBox(height: isTablet ? 24 : 16),
        
        Text(
          'Co-Teacher',
          style: theme.textTheme.headlineLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: colorScheme.primary,
            fontSize: isTablet ? 36 : 28,
          ),
        ),
        const SizedBox(height: 8),
        
        Text(
          'Teacher Login',
          style: theme.textTheme.titleMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
            fontSize: isTablet ? 18 : 16,
          ),
        ),
      ],
    );
  }

  Widget _buildEmailField(BuildContext context, LoginState state, bool isTablet) {
    return TextFormField(
      controller: _emailController,
      keyboardType: TextInputType.emailAddress,
      textInputAction: TextInputAction.next,
      style: TextStyle(fontSize: isTablet ? 18 : 16),
      decoration: InputDecoration(
        labelText: 'Email',
        hintText: 'teacher@school.com',
        prefixIcon: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Icon(Icons.email_outlined, size: isTablet ? 28 : 24),
        ),
        prefixIconConstraints: BoxConstraints(
          minWidth: isTablet ? 60 : 48,
          minHeight: isTablet ? 60 : 48,
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter your email';
        }
        if (!value.contains('@')) {
          return 'Please enter a valid email';
        }
        return null;
      },
      enabled: !state.isLoading,
    );
  }

  Widget _buildPasswordField(BuildContext context, LoginState state, bool isTablet) {
    return TextFormField(
      controller: _passwordController,
      obscureText: _obscurePassword,
      textInputAction: TextInputAction.done,
      style: TextStyle(fontSize: isTablet ? 18 : 16),
      onFieldSubmitted: (_) => _submitForm(context, state),
      decoration: InputDecoration(
        labelText: 'Password',
        hintText: 'Enter your password',
        prefixIcon: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Icon(Icons.lock_outlined, size: isTablet ? 28 : 24),
        ),
        prefixIconConstraints: BoxConstraints(
          minWidth: isTablet ? 60 : 48,
          minHeight: isTablet ? 60 : 48,
        ),
        suffixIcon: IconButton(
          icon: Icon(
            _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
            size: isTablet ? 28 : 24,
          ),
          onPressed: () {
            setState(() => _obscurePassword = !_obscurePassword);
          },
          tooltip: _obscurePassword ? 'Show password' : 'Hide password',
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
    );
  }

  Widget _buildRememberMe(BuildContext context, LoginState state, bool isTablet) {
    final theme = Theme.of(context);
    
    return InkWell(
      onTap: state.isLoading ? null : () {
        setState(() => _rememberMe = !_rememberMe);
      },
      borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            SizedBox(
              width: isTablet ? 28 : 24,
              height: isTablet ? 28 : 24,
              child: Checkbox(
                value: _rememberMe,
                onChanged: state.isLoading ? null : (value) {
                  setState(() => _rememberMe = value ?? false);
                },
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Remember Me',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontSize: isTablet ? 18 : 16,
                    ),
                  ),
                  Text(
                    'Save email for next login',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontSize: isTablet ? 14 : 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoginButton(BuildContext context, LoginState state, bool isTablet) {
    final theme = Theme.of(context);
    
    return SizedBox(
      height: isTablet ? AppTheme.buttonHeightLarge : AppTheme.buttonHeight,
      child: FilledButton(
        onPressed: state.isLoading ? null : () => _submitForm(context, state),
        style: FilledButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          ),
        ),
        child: state.isLoading
            ? SizedBox(
                height: isTablet ? 28 : 24,
                width: isTablet ? 28 : 24,
                child: const CircularProgressIndicator(
                  strokeWidth: 3,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Text(
                'Login',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.onPrimary,
                  fontWeight: FontWeight.w600,
                  fontSize: isTablet ? 20 : 18,
                ),
              ),
      ),
    );
  }

  Widget _buildForgotPassword(BuildContext context, LoginState state, bool isTablet) {
    return Center(
      child: TextButton(
        onPressed: state.isLoading ? null : () {
          context.push('/forgot-password');
        },
        style: TextButton.styleFrom(
          minimumSize: Size(isTablet ? 200 : 150, isTablet ? 56 : 48),
        ),
        child: Text(
          'Forgot Password?',
          style: TextStyle(
            fontSize: isTablet ? 16 : 14,
          ),
        ),
      ),
    );
  }

  void _submitForm(BuildContext context, LoginState state) {
    if (_formKey.currentState?.validate() ?? false) {
      context.read<LoginCubit>().login(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        rememberMe: _rememberMe,
      );
    }
  }
}
