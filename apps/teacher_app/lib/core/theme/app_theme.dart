import 'package:flutter/material.dart';

/// =============================================================================
/// APP THEME - TABLET-OPTIMIZED FOR CO-TEACHER
/// =============================================================================
/// 
/// LEARNING GUIDE: Understanding Flutter Theming
/// 
/// WHAT IS A THEME?
/// A theme defines the visual appearance of your entire app in one place:
/// - Colors (primary, secondary, background, text colors)
/// - Typography (font sizes, weights, families)
/// - Component styles (buttons, cards, inputs)
/// 
/// WHY USE THEMES?
/// 1. Consistency - All buttons look the same automatically
/// 2. Easy updates - Change one place, updates everywhere
/// 3. Dark mode support - Just swap themes
/// 4. Accessibility - Can adjust for larger text, high contrast
/// 
/// TABLET OPTIMIZATION:
/// Tablets have larger screens and are used with fingers (not mouse).
/// We optimize by:
/// - Larger touch targets (48dp minimum, we use 56dp)
/// - Bigger fonts for readability at arm's length
/// - More padding/spacing for visual comfort
/// - Larger icons and buttons
/// =============================================================================

class AppTheme {
  // Private constructor - can't instantiate this class
  AppTheme._();

  // ==========================================================================
  // COLOR PALETTE
  // ==========================================================================
  // 
  // LEARNING: Color theory in apps
  // - Primary: Main brand color, used for key actions
  // - Secondary: Accent color for highlights
  // - Surface: Background colors for cards, dialogs
  // - Error: Red for errors (universal meaning)
  // - Success: Green for success (universal meaning)
  
  static const Color primaryColor = Color(0xFF1565C0);      // Deep Blue - Trust, Education
  static const Color primaryLight = Color(0xFF5E92F3);      // Lighter for hover states
  static const Color primaryDark = Color(0xFF003C8F);       // Darker for pressed states
  
  static const Color secondaryColor = Color(0xFF00897B);    // Teal - Fresh, Modern
  static const Color secondaryLight = Color(0xFF4EBAAA);
  static const Color secondaryDark = Color(0xFF005B4F);
  
  static const Color successColor = Color(0xFF2E7D32);      // Green - Success
  static const Color warningColor = Color(0xFFF57C00);      // Orange - Warning
  static const Color errorColor = Color(0xFFC62828);        // Red - Error
  static const Color infoColor = Color(0xFF0288D1);         // Light Blue - Info

  // ==========================================================================
  // TABLET-SPECIFIC SIZING
  // ==========================================================================
  // 
  // LEARNING: Touch target guidelines
  // - Minimum touch target: 48x48dp (Google Material Design)
  // - Recommended for tablets: 56x56dp or larger
  // - Spacing between targets: at least 8dp
  
  /// Minimum touch target size for tablet accessibility
  static const double touchTargetSize = 56.0;
  
  /// Standard button height for tablets
  static const double buttonHeight = 56.0;
  
  /// Large button height for primary actions
  static const double buttonHeightLarge = 64.0;
  
  /// Icon size for toolbar/navigation
  static const double iconSizeMedium = 28.0;
  
  /// Icon size for large displays
  static const double iconSizeLarge = 32.0;
  
  /// Standard padding for tablet layouts
  static const double paddingSmall = 8.0;
  static const double paddingMedium = 16.0;
  static const double paddingLarge = 24.0;
  static const double paddingXLarge = 32.0;
  
  /// Border radius for rounded corners
  static const double radiusSmall = 8.0;
  static const double radiusMedium = 12.0;
  static const double radiusLarge = 16.0;
  static const double radiusXLarge = 24.0;

  // ==========================================================================
  // TYPOGRAPHY - TABLET OPTIMIZED
  // ==========================================================================
  // 
  // LEARNING: Typography for tablets
  // - Tablets are often viewed at arm's length (farther than phones)
  // - Base font size should be 16-18sp minimum
  // - Headers should be noticeably larger
  // - Line height (leading) helps readability
  
  static TextTheme get _textTheme => const TextTheme(
    // Display - Very large, for splash screens
    displayLarge: TextStyle(fontSize: 57, fontWeight: FontWeight.w400, letterSpacing: -0.25),
    displayMedium: TextStyle(fontSize: 45, fontWeight: FontWeight.w400),
    displaySmall: TextStyle(fontSize: 36, fontWeight: FontWeight.w400),
    
    // Headline - Page titles, major sections
    headlineLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.w600, letterSpacing: 0),
    headlineMedium: TextStyle(fontSize: 28, fontWeight: FontWeight.w500),
    headlineSmall: TextStyle(fontSize: 24, fontWeight: FontWeight.w500),
    
    // Title - Card titles, dialogs, app bars
    titleLarge: TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
    titleMedium: TextStyle(fontSize: 18, fontWeight: FontWeight.w500, letterSpacing: 0.15),
    titleSmall: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, letterSpacing: 0.1),
    
    // Body - Main content text (TABLET: larger than default)
    bodyLarge: TextStyle(fontSize: 18, fontWeight: FontWeight.w400, letterSpacing: 0.15),
    bodyMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w400, letterSpacing: 0.25),
    bodySmall: TextStyle(fontSize: 14, fontWeight: FontWeight.w400, letterSpacing: 0.4),
    
    // Label - Buttons, chips, form labels (TABLET: larger)
    labelLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, letterSpacing: 0.1),
    labelMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, letterSpacing: 0.5),
    labelSmall: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, letterSpacing: 0.5),
  );

  // ==========================================================================
  // LIGHT THEME
  // ==========================================================================
  
  static ThemeData get lightTheme {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: primaryColor,
      brightness: Brightness.light,
      primary: primaryColor,
      secondary: secondaryColor,
      error: errorColor,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      textTheme: _textTheme,
      
      // ------------------------------------
      // APP BAR - Tablet optimized
      // ------------------------------------
      appBarTheme: AppBarTheme(
        centerTitle: false,  // Left-align title (more content space)
        elevation: 0,
        scrolledUnderElevation: 2,
        toolbarHeight: 72,   // Taller for tablet (default is 56)
        titleTextStyle: _textTheme.titleLarge?.copyWith(
          color: colorScheme.onSurface,
          fontWeight: FontWeight.w600,
        ),
        iconTheme: IconThemeData(
          size: iconSizeMedium,
          color: colorScheme.onSurface,
        ),
      ),

      // ------------------------------------
      // CARDS - For content containers
      // ------------------------------------
      cardTheme: CardThemeData(
        elevation: 2,
        shadowColor: Colors.black26,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
        ),
        margin: const EdgeInsets.all(paddingSmall),
      ),

      // ------------------------------------
      // ELEVATED BUTTONS - Primary actions
      // ------------------------------------
      // LEARNING: Button styling
      // - minimumSize ensures touch target is large enough
      // - padding adds internal spacing
      // - textStyle controls font size
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(120, buttonHeight),
          padding: const EdgeInsets.symmetric(
            horizontal: paddingLarge,
            vertical: paddingMedium,
          ),
          textStyle: _textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMedium),
          ),
          elevation: 2,
        ),
      ),

      // ------------------------------------
      // FILLED BUTTONS - Secondary prominence
      // ------------------------------------
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(120, buttonHeight),
          padding: const EdgeInsets.symmetric(
            horizontal: paddingLarge,
            vertical: paddingMedium,
          ),
          textStyle: _textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMedium),
          ),
        ),
      ),

      // ------------------------------------
      // OUTLINED BUTTONS - Tertiary actions
      // ------------------------------------
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(120, buttonHeight),
          padding: const EdgeInsets.symmetric(
            horizontal: paddingLarge,
            vertical: paddingMedium,
          ),
          textStyle: _textTheme.labelLarge,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMedium),
          ),
          side: BorderSide(color: colorScheme.outline, width: 1.5),
        ),
      ),

      // ------------------------------------
      // TEXT BUTTONS - Low emphasis actions
      // ------------------------------------
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: const Size(touchTargetSize, touchTargetSize),
          padding: const EdgeInsets.symmetric(
            horizontal: paddingMedium,
            vertical: paddingSmall,
          ),
          textStyle: _textTheme.labelLarge,
        ),
      ),

      // ------------------------------------
      // ICON BUTTONS - Toolbar actions
      // ------------------------------------
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          minimumSize: const Size(touchTargetSize, touchTargetSize),
          iconSize: iconSizeMedium,
          padding: const EdgeInsets.all(paddingMedium),
        ),
      ),

      // ------------------------------------
      // FLOATING ACTION BUTTON - Large for tablet
      // ------------------------------------
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        sizeConstraints: const BoxConstraints.tightFor(
          width: 72,
          height: 72,
        ),
        iconSize: iconSizeLarge,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLarge),
        ),
      ),

      // ------------------------------------
      // INPUT DECORATION - Form fields
      // ------------------------------------
      // LEARNING: Input decoration for tablets
      // - contentPadding makes the input area larger
      // - prefixIcon/suffixIcon need adequate size
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surfaceContainerHighest.withOpacity(0.5),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: paddingLarge,
          vertical: paddingMedium + 4,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          borderSide: BorderSide(color: colorScheme.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          borderSide: BorderSide(color: colorScheme.outline.withOpacity(0.5)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          borderSide: BorderSide(color: colorScheme.error),
        ),
        labelStyle: _textTheme.bodyLarge,
        hintStyle: _textTheme.bodyLarge?.copyWith(
          color: colorScheme.onSurface.withOpacity(0.5),
        ),
        prefixIconColor: colorScheme.onSurfaceVariant,
        suffixIconColor: colorScheme.onSurfaceVariant,
      ),

      // ------------------------------------
      // LIST TILES - For lists and menus
      // ------------------------------------
      listTileTheme: ListTileThemeData(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: paddingLarge,
          vertical: paddingSmall,
        ),
        minVerticalPadding: paddingMedium,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusSmall),
        ),
        titleTextStyle: _textTheme.bodyLarge,
        subtitleTextStyle: _textTheme.bodyMedium?.copyWith(
          color: colorScheme.onSurfaceVariant,
        ),
        leadingAndTrailingTextStyle: _textTheme.labelLarge,
        iconColor: colorScheme.onSurfaceVariant,
      ),

      // ------------------------------------
      // CHIPS - For filters, tags
      // ------------------------------------
      chipTheme: ChipThemeData(
        labelStyle: _textTheme.labelMedium,
        padding: const EdgeInsets.symmetric(
          horizontal: paddingMedium,
          vertical: paddingSmall,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusSmall),
        ),
      ),

      // ------------------------------------
      // DIALOGS - Modal windows
      // ------------------------------------
      dialogTheme: DialogThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLarge),
        ),
        titleTextStyle: _textTheme.headlineSmall,
        contentTextStyle: _textTheme.bodyLarge,
        actionsPadding: const EdgeInsets.all(paddingLarge),
      ),

      // ------------------------------------
      // BOTTOM NAVIGATION - Tab bar
      // ------------------------------------
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        type: BottomNavigationBarType.fixed,
        selectedIconTheme: const IconThemeData(size: iconSizeMedium),
        unselectedIconTheme: const IconThemeData(size: iconSizeMedium),
        selectedLabelStyle: _textTheme.labelMedium,
        unselectedLabelStyle: _textTheme.labelMedium,
      ),

      // ------------------------------------
      // NAVIGATION RAIL - Side navigation (great for tablets!)
      // ------------------------------------
      navigationRailTheme: NavigationRailThemeData(
        minWidth: 80,
        minExtendedWidth: 256,
        labelType: NavigationRailLabelType.all,
        selectedIconTheme: const IconThemeData(size: iconSizeMedium),
        unselectedIconTheme: const IconThemeData(size: iconSizeMedium),
        selectedLabelTextStyle: _textTheme.labelMedium?.copyWith(
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelTextStyle: _textTheme.labelMedium,
      ),

      // ------------------------------------
      // SNACKBAR - Toast messages
      // ------------------------------------
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusSmall),
        ),
        contentTextStyle: _textTheme.bodyMedium?.copyWith(color: Colors.white),
      ),

      // ------------------------------------
      // DIVIDER
      // ------------------------------------
      dividerTheme: DividerThemeData(
        thickness: 1,
        space: paddingLarge,
        color: colorScheme.outlineVariant,
      ),

    );
  }

  // ==========================================================================
  // DARK THEME
  // ==========================================================================
  
  static ThemeData get darkTheme {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: primaryColor,
      brightness: Brightness.dark,
      primary: primaryLight,
      secondary: secondaryLight,
      error: const Color(0xFFEF5350),
    );

    // Dark theme uses the same structure as light, but with dark color scheme
    return lightTheme.copyWith(
      colorScheme: colorScheme,
      scaffoldBackgroundColor: colorScheme.surface,
      appBarTheme: lightTheme.appBarTheme.copyWith(
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
      ),
      cardTheme: lightTheme.cardTheme.copyWith(
        color: colorScheme.surfaceContainerHigh,
      ),
      inputDecorationTheme: lightTheme.inputDecorationTheme.copyWith(
        fillColor: colorScheme.surfaceContainerHighest.withOpacity(0.3),
      ),
    );
  }

  // ==========================================================================
  // HELPER METHODS
  // ==========================================================================

  /// Get color for attendance status
  static Color getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'present':
        return successColor;
      case 'absent':
        return errorColor;
      case 'tardy':
      case 'late':
        return warningColor;
      default:
        return infoColor;
    }
  }

  /// Get icon for attendance status
  static IconData getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'present':
        return Icons.check_circle;
      case 'absent':
        return Icons.cancel;
      case 'tardy':
      case 'late':
        return Icons.watch_later;
      default:
        return Icons.help;
    }
  }
}
