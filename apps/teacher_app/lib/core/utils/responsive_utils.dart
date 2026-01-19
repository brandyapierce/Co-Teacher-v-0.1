import 'package:flutter/material.dart';

/// =============================================================================
/// RESPONSIVE UTILITIES - TABLET & MULTI-DEVICE SUPPORT
/// =============================================================================
/// 
/// LEARNING GUIDE: Responsive Design in Flutter
/// 
/// WHAT IS RESPONSIVE DESIGN?
/// Making your app look good on ALL screen sizes:
/// - Phones (small, narrow screens)
/// - Tablets (medium, wider screens)  
/// - Desktops (large, very wide screens)
/// 
/// WHY IS IT IMPORTANT?
/// Users expect apps to adapt to their device. A phone layout on a 
/// 12" tablet wastes space and looks unprofessional.
/// 
/// HOW DO WE ACHIEVE IT?
/// 1. MediaQuery - Get screen size information
/// 2. LayoutBuilder - Build different layouts based on constraints
/// 3. Breakpoints - Define when to switch between layouts
/// 4. Responsive widgets - Components that adapt their size
/// =============================================================================

/// Screen size categories based on width
/// 
/// LEARNING: Breakpoints
/// Breakpoints are the screen widths where your layout changes.
/// These values are based on common device sizes:
/// - Phones: typically 320-480dp wide
/// - Small tablets: 600-800dp wide
/// - Large tablets: 800-1200dp wide
/// - Desktops: 1200dp+ wide
enum ScreenSize {
  /// Phone in portrait mode (< 600dp)
  mobile,
  
  /// Small tablet or phone in landscape (600-900dp)
  tablet,
  
  /// Large tablet or small desktop (900-1200dp)
  desktop,
  
  /// Large desktop (> 1200dp)
  largeDesktop,
}

/// Responsive layout helper class
/// 
/// USAGE EXAMPLE:
/// ```dart
/// if (ResponsiveLayout.isTablet(context)) {
///   // Show tablet layout
/// } else {
///   // Show mobile layout
/// }
/// ```
class ResponsiveLayout {
  // Private constructor - use static methods only
  ResponsiveLayout._();

  // ==========================================================================
  // BREAKPOINT CONSTANTS
  // ==========================================================================
  
  /// Minimum width for tablet layout (portrait tablet)
  static const double tabletBreakpoint = 600;
  
  /// Minimum width for desktop layout (landscape tablet / small desktop)
  static const double desktopBreakpoint = 900;
  
  /// Minimum width for large desktop layout
  static const double largeDesktopBreakpoint = 1200;
  
  /// Maximum content width for readability (text shouldn't be too wide)
  static const double maxContentWidth = 800;
  
  /// Maximum form width (forms are easier to fill when not too wide)
  static const double maxFormWidth = 500;

  // ==========================================================================
  // SCREEN SIZE DETECTION
  // ==========================================================================
  
  /// Get the current screen size category
  /// 
  /// LEARNING: MediaQuery
  /// MediaQuery.of(context) gives you information about the device:
  /// - size: width and height in logical pixels
  /// - orientation: portrait or landscape
  /// - textScaleFactor: user's text size preference
  /// - padding: safe area insets (notches, status bar)
  static ScreenSize getScreenSize(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    
    if (width >= largeDesktopBreakpoint) {
      return ScreenSize.largeDesktop;
    } else if (width >= desktopBreakpoint) {
      return ScreenSize.desktop;
    } else if (width >= tabletBreakpoint) {
      return ScreenSize.tablet;
    } else {
      return ScreenSize.mobile;
    }
  }

  /// Check if the current screen is mobile-sized
  static bool isMobile(BuildContext context) {
    return getScreenSize(context) == ScreenSize.mobile;
  }

  /// Check if the current screen is tablet-sized or larger
  static bool isTablet(BuildContext context) {
    final size = getScreenSize(context);
    return size == ScreenSize.tablet || 
           size == ScreenSize.desktop || 
           size == ScreenSize.largeDesktop;
  }

  /// Check if the current screen is desktop-sized or larger
  static bool isDesktop(BuildContext context) {
    final size = getScreenSize(context);
    return size == ScreenSize.desktop || size == ScreenSize.largeDesktop;
  }

  /// Check if the current screen is in landscape orientation
  static bool isLandscape(BuildContext context) {
    return MediaQuery.of(context).orientation == Orientation.landscape;
  }

  /// Get the screen width
  static double screenWidth(BuildContext context) {
    return MediaQuery.of(context).size.width;
  }

  /// Get the screen height
  static double screenHeight(BuildContext context) {
    return MediaQuery.of(context).size.height;
  }

  // ==========================================================================
  // RESPONSIVE VALUES
  // ==========================================================================
  
  /// Get a value based on screen size
  /// 
  /// USAGE:
  /// ```dart
  /// final padding = ResponsiveLayout.value<double>(
  ///   context,
  ///   mobile: 16,
  ///   tablet: 24,
  ///   desktop: 32,
  /// );
  /// ```
  static T value<T>({
    required BuildContext context,
    required T mobile,
    T? tablet,
    T? desktop,
    T? largeDesktop,
  }) {
    final size = getScreenSize(context);
    
    switch (size) {
      case ScreenSize.largeDesktop:
        return largeDesktop ?? desktop ?? tablet ?? mobile;
      case ScreenSize.desktop:
        return desktop ?? tablet ?? mobile;
      case ScreenSize.tablet:
        return tablet ?? mobile;
      case ScreenSize.mobile:
        return mobile;
    }
  }

  /// Get responsive padding based on screen size
  static EdgeInsets responsivePadding(BuildContext context) {
    return value<EdgeInsets>(
      context: context,
      mobile: const EdgeInsets.all(16),
      tablet: const EdgeInsets.all(24),
      desktop: const EdgeInsets.all(32),
    );
  }

  /// Get responsive horizontal padding
  static double responsiveHorizontalPadding(BuildContext context) {
    return value<double>(
      context: context,
      mobile: 16,
      tablet: 24,
      desktop: 32,
      largeDesktop: 48,
    );
  }

  /// Get number of grid columns based on screen size
  static int gridColumns(BuildContext context) {
    return value<int>(
      context: context,
      mobile: 1,
      tablet: 2,
      desktop: 3,
      largeDesktop: 4,
    );
  }
}

/// =============================================================================
/// RESPONSIVE BUILDER WIDGET
/// =============================================================================
/// 
/// LEARNING: Builder Pattern
/// This widget lets you define different layouts for different screen sizes.
/// Only one of the builders is called based on the current screen size.
/// 
/// USAGE:
/// ```dart
/// ResponsiveBuilder(
///   mobile: (context) => MobileLayout(),
///   tablet: (context) => TabletLayout(),
///   desktop: (context) => DesktopLayout(),
/// )
/// ```

class ResponsiveBuilder extends StatelessWidget {
  /// Builder for mobile screens (required)
  final Widget Function(BuildContext context) mobile;
  
  /// Builder for tablet screens (optional, falls back to mobile)
  final Widget Function(BuildContext context)? tablet;
  
  /// Builder for desktop screens (optional, falls back to tablet)
  final Widget Function(BuildContext context)? desktop;

  const ResponsiveBuilder({
    super.key,
    required this.mobile,
    this.tablet,
    this.desktop,
  });

  @override
  Widget build(BuildContext context) {
    final screenSize = ResponsiveLayout.getScreenSize(context);

    switch (screenSize) {
      case ScreenSize.largeDesktop:
      case ScreenSize.desktop:
        return desktop?.call(context) ?? 
               tablet?.call(context) ?? 
               mobile(context);
      case ScreenSize.tablet:
        return tablet?.call(context) ?? mobile(context);
      case ScreenSize.mobile:
        return mobile(context);
    }
  }
}

/// =============================================================================
/// CENTERED CONTENT WIDGET
/// =============================================================================
/// 
/// LEARNING: Content Width Constraints
/// On wide screens, text that spans the full width is hard to read.
/// Optimal line length is 50-75 characters.
/// This widget centers content with a maximum width.

class CenteredContent extends StatelessWidget {
  final Widget child;
  final double maxWidth;
  final EdgeInsets? padding;

  const CenteredContent({
    super.key,
    required this.child,
    this.maxWidth = ResponsiveLayout.maxContentWidth,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: padding != null
            ? Padding(padding: padding!, child: child)
            : child,
      ),
    );
  }
}

/// =============================================================================
/// TABLET-OPTIMIZED FORM CONTAINER
/// =============================================================================
/// 
/// Wraps forms with appropriate width and padding for tablet use.

class TabletFormContainer extends StatelessWidget {
  final Widget child;
  final double maxWidth;

  const TabletFormContainer({
    super.key,
    required this.child,
    this.maxWidth = ResponsiveLayout.maxFormWidth,
  });

  @override
  Widget build(BuildContext context) {
    final isTablet = ResponsiveLayout.isTablet(context);
    
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: isTablet ? maxWidth : double.infinity,
        ),
        child: Padding(
          padding: ResponsiveLayout.responsivePadding(context),
          child: child,
        ),
      ),
    );
  }
}

/// =============================================================================
/// RESPONSIVE GRID
/// =============================================================================
/// 
/// A grid that automatically adjusts columns based on screen size.

class ResponsiveGrid extends StatelessWidget {
  final List<Widget> children;
  final double spacing;
  final double runSpacing;
  final int? mobileColumns;
  final int? tabletColumns;
  final int? desktopColumns;

  const ResponsiveGrid({
    super.key,
    required this.children,
    this.spacing = 16,
    this.runSpacing = 16,
    this.mobileColumns,
    this.tabletColumns,
    this.desktopColumns,
  });

  @override
  Widget build(BuildContext context) {
    final columns = ResponsiveLayout.value<int>(
      context: context,
      mobile: mobileColumns ?? 1,
      tablet: tabletColumns ?? 2,
      desktop: desktopColumns ?? 3,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final itemWidth = (constraints.maxWidth - (spacing * (columns - 1))) / columns;
        
        return Wrap(
          spacing: spacing,
          runSpacing: runSpacing,
          children: children.map((child) {
            return SizedBox(
              width: itemWidth,
              child: child,
            );
          }).toList(),
        );
      },
    );
  }
}

/// =============================================================================
/// ADAPTIVE NAVIGATION
/// =============================================================================
/// 
/// Shows BottomNavigationBar on mobile, NavigationRail on tablet/desktop.
/// 
/// LEARNING: Adaptive UI
/// Different form factors need different navigation patterns:
/// - Mobile: Bottom tabs (thumb reachable)
/// - Tablet: Side rail (more space, persistent)
/// - Desktop: Full sidebar with labels

class AdaptiveNavigation extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onDestinationSelected;
  final List<NavigationDestination> destinations;
  final Widget body;

  const AdaptiveNavigation({
    super.key,
    required this.currentIndex,
    required this.onDestinationSelected,
    required this.destinations,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    final isDesktop = ResponsiveLayout.isDesktop(context);
    final isTablet = ResponsiveLayout.isTablet(context);

    // Desktop/Large Tablet: Use NavigationRail
    if (isDesktop || isTablet) {
      return Row(
        children: [
          NavigationRail(
            extended: isDesktop,
            selectedIndex: currentIndex,
            onDestinationSelected: onDestinationSelected,
            labelType: isDesktop 
                ? NavigationRailLabelType.none 
                : NavigationRailLabelType.all,
            destinations: destinations.map((d) {
              return NavigationRailDestination(
                icon: d.icon,
                selectedIcon: d.selectedIcon,
                label: Text(d.label),
              );
            }).toList(),
          ),
          const VerticalDivider(thickness: 1, width: 1),
          Expanded(child: body),
        ],
      );
    }

    // Mobile: Use BottomNavigationBar
    return Scaffold(
      body: body,
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: onDestinationSelected,
        destinations: destinations,
      ),
    );
  }
}

/// =============================================================================
/// SIZE EXTENSIONS
/// =============================================================================
/// 
/// LEARNING: Extension Methods
/// Extensions let you add methods to existing classes.
/// These add responsive helper methods to BuildContext.

extension ResponsiveContext on BuildContext {
  /// Check if this is a tablet or larger screen
  bool get isTablet => ResponsiveLayout.isTablet(this);
  
  /// Check if this is a mobile screen
  bool get isMobile => ResponsiveLayout.isMobile(this);
  
  /// Check if this is a desktop screen
  bool get isDesktop => ResponsiveLayout.isDesktop(this);
  
  /// Get responsive padding for this screen
  EdgeInsets get responsivePadding => ResponsiveLayout.responsivePadding(this);
  
  /// Get the current screen size category
  ScreenSize get screenSize => ResponsiveLayout.getScreenSize(this);
  
  /// Screen width
  double get screenWidth => ResponsiveLayout.screenWidth(this);
  
  /// Screen height
  double get screenHeight => ResponsiveLayout.screenHeight(this);
}
