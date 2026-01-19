import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:get_it/get_it.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/responsive_utils.dart';
import '../../../../shared/presentation/widgets/class_picker_dialog.dart';
import '../../../classes/data/models/class_model.dart';

/// =============================================================================
/// HOME PAGE - TABLET-OPTIMIZED DASHBOARD
/// =============================================================================
/// 
/// LEARNING GUIDE: Adaptive Navigation
/// 
/// TABLET VS MOBILE NAVIGATION:
/// - Mobile: BottomNavigationBar (thumb-reachable at bottom)
/// - Tablet: NavigationRail (side rail, uses horizontal space better)
/// - Desktop: Extended NavigationRail with labels
/// 
/// WHY ADAPTIVE?
/// Different screen sizes have different ergonomics:
/// - Phones are held with one hand, thumb reaches bottom
/// - Tablets are held with two hands or on a stand
/// - Side navigation works better on wider screens
/// =============================================================================

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;

  // Navigation destinations for both NavRail and BottomNav
  static const List<_NavDestination> _destinations = [
    _NavDestination(
      icon: Icons.people_outline,
      selectedIcon: Icons.people,
      label: 'Attendance',
    ),
    _NavDestination(
      icon: Icons.class_outlined,
      selectedIcon: Icons.class_,
      label: 'Classes',
    ),
    _NavDestination(
      icon: Icons.analytics_outlined,
      selectedIcon: Icons.analytics,
      label: 'Reports',
    ),
    _NavDestination(
      icon: Icons.rotate_right_outlined,
      selectedIcon: Icons.rotate_right,
      label: 'Rotations',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final isTablet = context.isTablet;
    
    // Different layout for tablet vs mobile
    if (isTablet) {
      return _buildTabletLayout(context);
    } else {
      return _buildMobileLayout(context);
    }
  }

  /// Tablet layout: Side NavigationRail + Content
  Widget _buildTabletLayout(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDesktop = context.isDesktop;
    
    return Scaffold(
      body: Row(
        children: [
          // Navigation Rail
          NavigationRail(
            extended: isDesktop,
            backgroundColor: colorScheme.surfaceContainerLow,
            selectedIndex: _currentIndex,
            onDestinationSelected: (index) {
              setState(() => _currentIndex = index);
            },
            labelType: isDesktop 
                ? NavigationRailLabelType.none 
                : NavigationRailLabelType.all,
            leading: _buildNavRailHeader(context, isDesktop),
            trailing: Expanded(
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: _buildLogoutButton(context, isRail: true),
                ),
              ),
            ),
            destinations: _destinations.map((d) {
              return NavigationRailDestination(
                icon: Icon(d.icon, size: 28),
                selectedIcon: Icon(d.selectedIcon, size: 28),
                label: Text(d.label),
                padding: const EdgeInsets.symmetric(vertical: 8),
              );
            }).toList(),
          ),
          
          // Divider
          VerticalDivider(
            thickness: 1,
            width: 1,
            color: colorScheme.outlineVariant,
          ),
          
          // Main content area
          Expanded(
            child: Column(
              children: [
                // App bar for tablets
                _buildTabletAppBar(context),
                
                // Content
                Expanded(
                  child: _buildPageContent(context),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Mobile layout: Content + Bottom Navigation
  Widget _buildMobileLayout(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Co-Teacher'),
        actions: _buildAppBarActions(context),
      ),
      body: _buildPageContent(context),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() => _currentIndex = index);
        },
        destinations: _destinations.map((d) {
          return NavigationDestination(
            icon: Icon(d.icon),
            selectedIcon: Icon(d.selectedIcon),
            label: d.label,
          );
        }).toList(),
      ),
    );
  }

  Widget _buildNavRailHeader(BuildContext context, bool isDesktop) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        children: [
          Container(
            width: isDesktop ? 56 : 48,
            height: isDesktop ? 56 : 48,
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              Icons.school_rounded,
              size: isDesktop ? 32 : 28,
              color: colorScheme.primary,
            ),
          ),
          if (isDesktop) ...[
            const SizedBox(height: 8),
            Text(
              'Co-Teacher',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
          const SizedBox(height: 16),
          const Divider(),
        ],
      ),
    );
  }

  Widget _buildTabletAppBar(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Container(
      height: 72,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: colorScheme.outlineVariant,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // Page title
          Text(
            _destinations[_currentIndex].label,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          // Action buttons
          ..._buildAppBarActions(context),
        ],
      ),
    );
  }

  List<Widget> _buildAppBarActions(BuildContext context) {
    final isTablet = context.isTablet;
    final iconSize = isTablet ? 28.0 : 24.0;
    
    return [
      IconButton(
        icon: Icon(Icons.people_alt, size: iconSize),
        tooltip: 'Students',
        onPressed: () => context.push('/students'),
      ),
      IconButton(
        icon: Icon(Icons.face_retouching_natural, size: iconSize),
        tooltip: 'Face Enrollment',
        onPressed: () => context.push('/enrollment'),
      ),
      if (!isTablet) _buildLogoutButton(context, isRail: false),
    ];
  }

  Widget _buildLogoutButton(BuildContext context, {required bool isRail}) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    if (isRail) {
      return IconButton(
        icon: Icon(Icons.logout, size: 28, color: colorScheme.error),
        tooltip: 'Logout',
        onPressed: () => _handleLogout(context),
      );
    }
    
    return IconButton(
      icon: const Icon(Icons.logout),
      tooltip: 'Logout',
      onPressed: () => _handleLogout(context),
    );
  }

  Future<void> _handleLogout(BuildContext context) async {
    final theme = Theme.of(context);
    final isTablet = context.isTablet;
    
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.logout, color: theme.colorScheme.error),
            const SizedBox(width: 12),
            const Text('Logout'),
          ],
        ),
        content: const Text('Are you sure you want to logout?'),
        contentPadding: EdgeInsets.all(isTablet ? 24 : 20),
        actionsPadding: EdgeInsets.all(isTablet ? 24 : 16),
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.of(context).pop(false),
            style: OutlinedButton.styleFrom(
              minimumSize: Size(isTablet ? 120 : 100, isTablet ? 56 : 48),
            ),
            child: const Text('Cancel'),
          ),
          const SizedBox(width: 12),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: theme.colorScheme.error,
              minimumSize: Size(isTablet ? 120 : 100, isTablet ? 56 : 48),
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (shouldLogout == true && context.mounted) {
      final authService = GetIt.instance<AuthService>();
      await authService.logout();
      
      if (context.mounted) {
        context.go('/login');
      }
    }
  }

  Widget _buildPageContent(BuildContext context) {
    switch (_currentIndex) {
      case 0:
        return const AttendanceTab();
      case 1:
        return const ClassesTab();
      case 2:
        return const ReportsTab();
      case 3:
        return const RotationsTab();
      default:
        return const AttendanceTab();
    }
  }
}

/// Navigation destination data
class _NavDestination {
  final IconData icon;
  final IconData selectedIcon;
  final String label;

  const _NavDestination({
    required this.icon,
    required this.selectedIcon,
    required this.label,
  });
}

/// =============================================================================
/// ATTENDANCE TAB - Tablet Optimized
/// =============================================================================

class AttendanceTab extends StatelessWidget {
  const AttendanceTab({super.key});

  void _showClassPickerAndScan(BuildContext context) async {
    // Get current teacher ID from cached storage
    final authService = GetIt.instance<AuthService>();
    final teacherId = await authService.getCachedUserId() ?? 'teacher-1';
    
    if (!context.mounted) return;
    
    // Show class picker dialog
    final selectedClass = await ClassPickerDialog.show(
      context,
      teacherId: teacherId,
    );
    
    // If a class was selected, navigate to scan with class info
    if (selectedClass != null && context.mounted) {
      context.push(
        '/attendance/scan',
        extra: selectedClass,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isTablet = context.isTablet;
    
    return SingleChildScrollView(
      padding: context.responsivePadding,
      child: CenteredContent(
        maxWidth: 600,
        child: Column(
          children: [
            SizedBox(height: isTablet ? 40 : 24),
            
            // Hero icon
            Container(
              width: isTablet ? 120 : 100,
              height: isTablet ? 120 : 100,
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(AppTheme.radiusXLarge),
                boxShadow: [
                  BoxShadow(
                    color: colorScheme.primary.withOpacity(0.2),
                    blurRadius: 24,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: Icon(
                Icons.people_rounded,
                size: isTablet ? 64 : 52,
                color: colorScheme.primary,
              ),
            ),
            SizedBox(height: isTablet ? 32 : 24),
            
            // Title
            Text(
              'Attendance Scanning',
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: isTablet ? 32 : 24,
              ),
            ),
            const SizedBox(height: 12),
            
            // Subtitle
            Text(
              'Scan your classroom to take attendance automatically\nusing face recognition technology',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontSize: isTablet ? 18 : 16,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: isTablet ? 48 : 32),
            
            // Primary action button - LARGE for tablet touch
            SizedBox(
              width: double.infinity,
              height: isTablet ? AppTheme.buttonHeightLarge : AppTheme.buttonHeight,
              child: FilledButton.icon(
                onPressed: () => _showClassPickerAndScan(context),
                icon: Icon(
                  Icons.camera_alt_rounded,
                  size: isTablet ? 28 : 24,
                ),
                label: Text(
                  'Start Attendance Scan',
                  style: TextStyle(
                    fontSize: isTablet ? 20 : 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            SizedBox(height: isTablet ? 20 : 16),
            
            // Secondary action button
            SizedBox(
              width: double.infinity,
              height: isTablet ? AppTheme.buttonHeight : 48,
              child: OutlinedButton.icon(
                onPressed: () => context.push('/attendance/history'),
                icon: Icon(
                  Icons.history_rounded,
                  size: isTablet ? 24 : 20,
                ),
                label: Text(
                  'View Attendance History',
                  style: TextStyle(
                    fontSize: isTablet ? 18 : 16,
                  ),
                ),
              ),
            ),
            SizedBox(height: isTablet ? 48 : 32),
            
            // Quick stats cards
            _buildQuickStats(context, isTablet),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickStats(BuildContext context, bool isTablet) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return ResponsiveGrid(
      spacing: isTablet ? 16 : 12,
      runSpacing: isTablet ? 16 : 12,
      mobileColumns: 2,
      tabletColumns: 2,
      children: [
        _StatCard(
          icon: Icons.check_circle,
          iconColor: AppTheme.successColor,
          label: 'Present Today',
          value: '--',
          isTablet: isTablet,
        ),
        _StatCard(
          icon: Icons.cancel,
          iconColor: AppTheme.errorColor,
          label: 'Absent Today',
          value: '--',
          isTablet: isTablet,
        ),
      ],
    );
  }
}

/// Quick stat card widget
class _StatCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  final bool isTablet;

  const _StatCard({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    required this.isTablet,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Card(
      child: Padding(
        padding: EdgeInsets.all(isTablet ? 20 : 16),
        child: Column(
          children: [
            Icon(
              icon,
              size: isTablet ? 36 : 28,
              color: iconColor,
            ),
            SizedBox(height: isTablet ? 12 : 8),
            Text(
              value,
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: isTablet ? 32 : 24,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontSize: isTablet ? 16 : 14,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

/// =============================================================================
/// CLASSES TAB - Class Management (Week 5)
/// =============================================================================

class ClassesTab extends StatelessWidget {
  const ClassesTab({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isTablet = context.isTablet;
    
    return SingleChildScrollView(
      padding: context.responsivePadding,
      child: CenteredContent(
        maxWidth: 600,
        child: Column(
          children: [
            SizedBox(height: isTablet ? 40 : 24),
            
            // Hero icon
            Container(
              width: isTablet ? 120 : 100,
              height: isTablet ? 120 : 100,
              decoration: BoxDecoration(
                color: colorScheme.tertiaryContainer,
                borderRadius: BorderRadius.circular(AppTheme.radiusXLarge),
                boxShadow: [
                  BoxShadow(
                    color: colorScheme.tertiary.withOpacity(0.2),
                    blurRadius: 24,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: Icon(
                Icons.class_rounded,
                size: isTablet ? 64 : 52,
                color: colorScheme.tertiary,
              ),
            ),
            SizedBox(height: isTablet ? 32 : 24),
            
            // Title
            Text(
              'Class Management',
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: isTablet ? 32 : 24,
              ),
            ),
            const SizedBox(height: 12),
            
            // Subtitle
            Text(
              'Organize your classes, manage students,\nand take attendance by class',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontSize: isTablet ? 18 : 16,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: isTablet ? 48 : 32),
            
            // Primary action button
            SizedBox(
              width: double.infinity,
              height: isTablet ? AppTheme.buttonHeightLarge : AppTheme.buttonHeight,
              child: FilledButton.icon(
                onPressed: () => context.push('/classes'),
                icon: Icon(
                  Icons.view_list_rounded,
                  size: isTablet ? 28 : 24,
                ),
                label: Text(
                  'View My Classes',
                  style: TextStyle(
                    fontSize: isTablet ? 20 : 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            SizedBox(height: isTablet ? 48 : 32),
            
            // Quick stats
            ResponsiveGrid(
              spacing: isTablet ? 16 : 12,
              runSpacing: isTablet ? 16 : 12,
              mobileColumns: 2,
              tabletColumns: 3,
              children: [
                _StatCard(
                  icon: Icons.class_,
                  iconColor: colorScheme.tertiary,
                  label: 'Active Classes',
                  value: '--',
                  isTablet: isTablet,
                ),
                _StatCard(
                  icon: Icons.group,
                  iconColor: colorScheme.secondary,
                  label: 'Total Students',
                  value: '--',
                  isTablet: isTablet,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// =============================================================================
/// REPORTS TAB - Week 6 Analytics Dashboard
/// =============================================================================

class ReportsTab extends StatelessWidget {
  const ReportsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isTablet = context.isTablet;
    
    return SingleChildScrollView(
      padding: context.responsivePadding,
      child: CenteredContent(
        maxWidth: 600,
        child: Column(
          children: [
            SizedBox(height: isTablet ? 40 : 24),
            
            // Hero icon
            Container(
              width: isTablet ? 120 : 100,
              height: isTablet ? 120 : 100,
              decoration: BoxDecoration(
                color: colorScheme.secondaryContainer,
                borderRadius: BorderRadius.circular(AppTheme.radiusXLarge),
                boxShadow: [
                  BoxShadow(
                    color: colorScheme.secondary.withOpacity(0.2),
                    blurRadius: 24,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: Icon(
                Icons.analytics_rounded,
                size: isTablet ? 64 : 52,
                color: colorScheme.secondary,
              ),
            ),
            SizedBox(height: isTablet ? 32 : 24),
            
            // Title
            Text(
              'Reports & Analytics',
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: isTablet ? 32 : 24,
              ),
            ),
            const SizedBox(height: 12),
            
            // Subtitle
            Text(
              'Track attendance trends, identify students at risk,\nand export reports',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontSize: isTablet ? 18 : 16,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: isTablet ? 48 : 32),
            
            // Primary action button
            SizedBox(
              width: double.infinity,
              height: isTablet ? AppTheme.buttonHeightLarge : AppTheme.buttonHeight,
              child: FilledButton.icon(
                onPressed: () => context.push('/reports'),
                icon: Icon(
                  Icons.bar_chart_rounded,
                  size: isTablet ? 28 : 24,
                ),
                label: Text(
                  'View Reports',
                  style: TextStyle(
                    fontSize: isTablet ? 20 : 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            SizedBox(height: isTablet ? 48 : 32),
            
            // Feature cards
            ResponsiveGrid(
              spacing: isTablet ? 16 : 12,
              runSpacing: isTablet ? 16 : 12,
              mobileColumns: 2,
              tabletColumns: 2,
              children: [
                _FeatureCard(
                  icon: Icons.trending_up,
                  title: 'Trends',
                  subtitle: 'Daily & weekly',
                  isTablet: isTablet,
                ),
                _FeatureCard(
                  icon: Icons.warning_amber,
                  title: 'At Risk',
                  subtitle: 'Students < 80%',
                  isTablet: isTablet,
                ),
                _FeatureCard(
                  icon: Icons.download,
                  title: 'Export',
                  subtitle: 'CSV reports',
                  isTablet: isTablet,
                ),
                _FeatureCard(
                  icon: Icons.compare,
                  title: 'Compare',
                  subtitle: 'Class stats',
                  isTablet: isTablet,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool isTablet;

  const _FeatureCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.isTablet,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Card(
      child: Padding(
        padding: EdgeInsets.all(isTablet ? 20 : 16),
        child: Column(
          children: [
            Icon(
              icon,
              size: isTablet ? 36 : 28,
              color: theme.colorScheme.secondary,
            ),
            SizedBox(height: isTablet ? 12 : 8),
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: isTablet ? 18 : 16,
              ),
            ),
            Text(
              subtitle,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontSize: isTablet ? 14 : 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// =============================================================================
/// ROTATIONS TAB - Coming Soon
/// =============================================================================

class RotationsTab extends StatelessWidget {
  const RotationsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return _ComingSoonPlaceholder(
      icon: Icons.rotate_right_rounded,
      title: 'Station Rotations',
      subtitle: 'Manage student rotations between learning stations',
      featureList: const [
        'Create rotation schedules',
        'Track student movements',
        'Timer and alerts',
        'Group management',
      ],
    );
  }
}

/// =============================================================================
/// EVIDENCE TAB - Coming Soon
/// =============================================================================

class EvidenceTab extends StatelessWidget {
  const EvidenceTab({super.key});

  @override
  Widget build(BuildContext context) {
    return _ComingSoonPlaceholder(
      icon: Icons.camera_alt_rounded,
      title: 'Evidence Collection',
      subtitle: 'Capture and organize student work evidence',
      featureList: const [
        'Photo documentation',
        'Work samples',
        'Progress tracking',
        'Portfolio building',
      ],
    );
  }
}

/// =============================================================================
/// COMING SOON PLACEHOLDER - Reusable
/// =============================================================================

class _ComingSoonPlaceholder extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final List<String> featureList;

  const _ComingSoonPlaceholder({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.featureList,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isTablet = context.isTablet;
    
    return SingleChildScrollView(
      padding: context.responsivePadding,
      child: CenteredContent(
        maxWidth: 500,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(height: isTablet ? 60 : 40),
            
            // Icon with badge
            Stack(
              alignment: Alignment.bottomRight,
              children: [
                Container(
                  width: isTablet ? 100 : 80,
                  height: isTablet ? 100 : 80,
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                  ),
                  child: Icon(
                    icon,
                    size: isTablet ? 52 : 44,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: colorScheme.secondaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'SOON',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colorScheme.onSecondaryContainer,
                      fontWeight: FontWeight.bold,
                      fontSize: isTablet ? 12 : 10,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: isTablet ? 32 : 24),
            
            Text(
              title,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: isTablet ? 28 : 22,
              ),
            ),
            const SizedBox(height: 8),
            
            Text(
              subtitle,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontSize: isTablet ? 18 : 16,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: isTablet ? 40 : 32),
            
            // Feature list
            Card(
              child: Padding(
                padding: EdgeInsets.all(isTablet ? 24 : 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Planned Features',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        fontSize: isTablet ? 18 : 16,
                      ),
                    ),
                    SizedBox(height: isTablet ? 16 : 12),
                    ...featureList.map((feature) {
                      return Padding(
                        padding: EdgeInsets.symmetric(
                          vertical: isTablet ? 8 : 6,
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.check_circle_outline,
                              size: isTablet ? 24 : 20,
                              color: colorScheme.primary,
                            ),
                            SizedBox(width: isTablet ? 16 : 12),
                            Text(
                              feature,
                              style: theme.textTheme.bodyLarge?.copyWith(
                                fontSize: isTablet ? 18 : 16,
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
