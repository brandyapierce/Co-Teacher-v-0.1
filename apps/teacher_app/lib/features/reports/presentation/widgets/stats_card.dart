import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/models/attendance_stats.dart';

/// =============================================================================
/// STATS CARD - Tablet-optimized statistics display
/// =============================================================================

class StatsCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  final String? subtitle;
  final AttendanceRateLevel? trend;
  final bool isTablet;

  const StatsCard({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    this.subtitle,
    this.trend,
    required this.isTablet,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: EdgeInsets.all(isTablet ? 20 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon and trend indicator row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: EdgeInsets.all(isTablet ? 10 : 8),
                  decoration: BoxDecoration(
                    color: iconColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                  ),
                  child: Icon(
                    icon,
                    size: isTablet ? 28 : 24,
                    color: iconColor,
                  ),
                ),
                if (trend != null) _buildTrendIndicator(context),
              ],
            ),
            SizedBox(height: isTablet ? 16 : 12),
            
            // Value
            Text(
              value,
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: isTablet ? 32 : 24,
              ),
            ),
            SizedBox(height: isTablet ? 4 : 2),
            
            // Label and subtitle
            Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontSize: isTablet ? 16 : 14,
              ),
            ),
            if (subtitle != null) ...[
              SizedBox(height: isTablet ? 4 : 2),
              Text(
                subtitle!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant.withOpacity(0.7),
                  fontSize: isTablet ? 14 : 12,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTrendIndicator(BuildContext context) {
    final color = _getTrendColor();
    final icon = _getTrendIcon();

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isTablet ? 10 : 8,
        vertical: isTablet ? 6 : 4,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: isTablet ? 18 : 14, color: color),
          SizedBox(width: isTablet ? 4 : 2),
          Text(
            _getTrendLabel(),
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: isTablet ? 12 : 10,
            ),
          ),
        ],
      ),
    );
  }

  Color _getTrendColor() {
    switch (trend) {
      case AttendanceRateLevel.excellent:
        return AppTheme.successColor;
      case AttendanceRateLevel.good:
        return Colors.blue;
      case AttendanceRateLevel.fair:
        return AppTheme.warningColor;
      case AttendanceRateLevel.poor:
        return AppTheme.errorColor;
      case null:
        return Colors.grey;
    }
  }

  IconData _getTrendIcon() {
    switch (trend) {
      case AttendanceRateLevel.excellent:
        return Icons.trending_up;
      case AttendanceRateLevel.good:
        return Icons.trending_flat;
      case AttendanceRateLevel.fair:
        return Icons.trending_down;
      case AttendanceRateLevel.poor:
        return Icons.trending_down;
      case null:
        return Icons.remove;
    }
  }

  String _getTrendLabel() {
    switch (trend) {
      case AttendanceRateLevel.excellent:
        return 'Excellent';
      case AttendanceRateLevel.good:
        return 'Good';
      case AttendanceRateLevel.fair:
        return 'Fair';
      case AttendanceRateLevel.poor:
        return 'Needs Attention';
      case null:
        return '';
    }
  }
}
