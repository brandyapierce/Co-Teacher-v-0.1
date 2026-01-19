import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/models/attendance_stats.dart';

/// =============================================================================
/// ATTENDANCE CHART - Simple bar chart for trends
/// =============================================================================
/// 
/// LEARNING GUIDE: Custom Painting in Flutter
/// 
/// WHY CUSTOM CHART?
/// - Lightweight (no heavy chart library)
/// - Full control over appearance
/// - Matches app theme perfectly
/// - Touch-friendly on tablets
/// 
/// ALTERNATIVE: Use fl_chart package for more complex charts
/// =============================================================================

class AttendanceChart extends StatelessWidget {
  final List<DailyAttendanceTrend> trends;
  final bool isTablet;

  const AttendanceChart({
    super.key,
    required this.trends,
    required this.isTablet,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (trends.isEmpty) {
      return SizedBox(
        height: isTablet ? 200 : 150,
        child: Center(
          child: Text(
            'No trend data available',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      );
    }

    final maxRate = trends.map((t) => t.attendanceRate).reduce((a, b) => a > b ? a : b);
    final chartHeight = isTablet ? 200.0 : 150.0;

    return Column(
      children: [
        // Chart
        SizedBox(
          height: chartHeight,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: trends.asMap().entries.map((entry) {
              final index = entry.key;
              final trend = entry.value;
              final barHeight = maxRate > 0
                  ? (trend.attendanceRate / 100) * (chartHeight - 30)
                  : 0.0;
              
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: isTablet ? 4 : 2,
                  ),
                  child: GestureDetector(
                    onTap: () => _showTrendDetails(context, trend),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        // Rate label
                        Text(
                          '${trend.attendanceRate.toStringAsFixed(0)}%',
                          style: TextStyle(
                            fontSize: isTablet ? 12 : 10,
                            fontWeight: FontWeight.bold,
                            color: _getBarColor(trend.attendanceRate),
                          ),
                        ),
                        SizedBox(height: isTablet ? 4 : 2),
                        // Bar
                        AnimatedContainer(
                          duration: Duration(milliseconds: 300 + (index * 50)),
                          curve: Curves.easeOutBack,
                          height: barHeight,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                _getBarColor(trend.attendanceRate),
                                _getBarColor(trend.attendanceRate).withOpacity(0.7),
                              ],
                            ),
                            borderRadius: BorderRadius.vertical(
                              top: Radius.circular(isTablet ? 6 : 4),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        
        SizedBox(height: isTablet ? 12 : 8),
        
        // X-axis labels (dates)
        Row(
          children: trends.map((trend) {
            return Expanded(
              child: Text(
                _formatDate(trend.date),
                style: TextStyle(
                  fontSize: isTablet ? 12 : 10,
                  color: colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            );
          }).toList(),
        ),
        
        SizedBox(height: isTablet ? 16 : 12),
        
        // Legend
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildLegendItem(context, AppTheme.successColor, 'Present'),
            SizedBox(width: isTablet ? 24 : 16),
            _buildLegendItem(context, AppTheme.errorColor, 'Absent'),
            SizedBox(width: isTablet ? 24 : 16),
            _buildLegendItem(context, AppTheme.warningColor, 'Tardy'),
          ],
        ),
      ],
    );
  }

  Color _getBarColor(double rate) {
    if (rate >= 95) return AppTheme.successColor;
    if (rate >= 90) return Colors.blue;
    if (rate >= 80) return AppTheme.warningColor;
    return AppTheme.errorColor;
  }

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}';
  }

  Widget _buildLegendItem(BuildContext context, Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: isTablet ? 14 : 12,
          height: isTablet ? 14 : 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        SizedBox(width: isTablet ? 6 : 4),
        Text(
          label,
          style: TextStyle(
            fontSize: isTablet ? 14 : 12,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  void _showTrendDetails(BuildContext context, DailyAttendanceTrend trend) {
    final theme = Theme.of(context);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          _formatFullDate(trend.date),
          style: TextStyle(fontSize: isTablet ? 20 : 18),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow(
              context,
              'Total Students',
              '${trend.totalStudents}',
            ),
            _buildDetailRow(
              context,
              'Present',
              '${trend.presentCount}',
              color: AppTheme.successColor,
            ),
            _buildDetailRow(
              context,
              'Absent',
              '${trend.absentCount}',
              color: AppTheme.errorColor,
            ),
            _buildDetailRow(
              context,
              'Tardy',
              '${trend.tardyCount}',
              color: AppTheme.warningColor,
            ),
            const Divider(),
            _buildDetailRow(
              context,
              'Attendance Rate',
              '${trend.attendanceRate.toStringAsFixed(1)}%',
              isBold: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(
    BuildContext context,
    String label,
    String value, {
    Color? color,
    bool isBold = false,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: isTablet ? 8 : 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isTablet ? 16 : 14,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: isTablet ? 16 : 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  String _formatFullDate(DateTime date) {
    const months = [
      '', 'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return '${months[date.month]} ${date.day}, ${date.year}';
  }
}
