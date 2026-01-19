import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/models/attendance_stats.dart';

/// =============================================================================
/// STUDENT LIST SECTION - Tablet-optimized student summary list
/// =============================================================================

class StudentListSection extends StatelessWidget {
  final List<StudentAttendanceSummary> students;
  final bool isTablet;
  final bool showWarning;

  const StudentListSection({
    super.key,
    required this.students,
    required this.isTablet,
    this.showWarning = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        children: students.asMap().entries.map((entry) {
          final index = entry.key;
          final student = entry.value;
          final isLast = index == students.length - 1;

          return Column(
            children: [
              _buildStudentTile(context, student),
              if (!isLast)
                Divider(
                  height: 1,
                  indent: isTablet ? 72 : 64,
                ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildStudentTile(BuildContext context, StudentAttendanceSummary student) {
    final theme = Theme.of(context);
    final rateColor = _getRateColor(student.attendanceRate);

    return ListTile(
      contentPadding: EdgeInsets.symmetric(
        horizontal: isTablet ? 20 : 16,
        vertical: isTablet ? 12 : 8,
      ),
      leading: _buildAvatar(context, student),
      title: Row(
        children: [
          Expanded(
            child: Text(
              student.studentName,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w500,
                fontSize: isTablet ? 18 : 16,
              ),
            ),
          ),
          if (showWarning && student.attendanceRate < 80) ...[
            Icon(
              Icons.warning_amber,
              size: isTablet ? 20 : 16,
              color: AppTheme.warningColor,
            ),
            SizedBox(width: isTablet ? 8 : 4),
          ],
        ],
      ),
      subtitle: Padding(
        padding: EdgeInsets.only(top: isTablet ? 8 : 4),
        child: Row(
          children: [
            // Stats chips
            _buildStatChip(
              context,
              '${student.presentDays}',
              'present',
              AppTheme.successColor,
            ),
            SizedBox(width: isTablet ? 8 : 4),
            _buildStatChip(
              context,
              '${student.absentDays}',
              'absent',
              AppTheme.errorColor,
            ),
            SizedBox(width: isTablet ? 8 : 4),
            _buildStatChip(
              context,
              '${student.tardyDays}',
              'tardy',
              AppTheme.warningColor,
            ),
          ],
        ),
      ),
      trailing: _buildRateBadge(context, student.attendanceRate, rateColor),
      onTap: () => _showStudentDetails(context, student),
    );
  }

  Widget _buildAvatar(BuildContext context, StudentAttendanceSummary student) {
    final initials = _getInitials(student.studentName);
    final rateColor = _getRateColor(student.attendanceRate);

    return CircleAvatar(
      radius: isTablet ? 28 : 24,
      backgroundColor: rateColor.withOpacity(0.1),
      child: Text(
        initials,
        style: TextStyle(
          color: rateColor,
          fontWeight: FontWeight.bold,
          fontSize: isTablet ? 18 : 16,
        ),
      ),
    );
  }

  Widget _buildStatChip(
    BuildContext context,
    String value,
    String label,
    Color color,
  ) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isTablet ? 10 : 8,
        vertical: isTablet ? 4 : 2,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: isTablet ? 14 : 12,
            ),
          ),
          SizedBox(width: isTablet ? 4 : 2),
          Text(
            label,
            style: TextStyle(
              color: color.withOpacity(0.8),
              fontSize: isTablet ? 12 : 10,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRateBadge(BuildContext context, double rate, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isTablet ? 14 : 10,
        vertical: isTablet ? 8 : 6,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '${rate.toStringAsFixed(1)}%',
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: isTablet ? 18 : 16,
            ),
          ),
          Text(
            'attendance',
            style: TextStyle(
              color: color.withOpacity(0.8),
              fontSize: isTablet ? 10 : 8,
            ),
          ),
        ],
      ),
    );
  }

  Color _getRateColor(double rate) {
    if (rate >= 95) return AppTheme.successColor;
    if (rate >= 90) return Colors.blue;
    if (rate >= 80) return AppTheme.warningColor;
    return AppTheme.errorColor;
  }

  String _getInitials(String name) {
    final parts = name.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.substring(0, name.length >= 2 ? 2 : 1).toUpperCase();
  }

  void _showStudentDetails(BuildContext context, StudentAttendanceSummary student) {
    final theme = Theme.of(context);
    final rateColor = _getRateColor(student.attendanceRate);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            _buildAvatar(context, student),
            SizedBox(width: isTablet ? 16 : 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    student.studentName,
                    style: TextStyle(fontSize: isTablet ? 20 : 18),
                  ),
                  Text(
                    '${student.attendanceRate.toStringAsFixed(1)}% attendance',
                    style: TextStyle(
                      fontSize: isTablet ? 14 : 12,
                      color: rateColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildDetailRow(
              context,
              Icons.calendar_today,
              'Total Days',
              '${student.totalDays}',
            ),
            _buildDetailRow(
              context,
              Icons.check_circle,
              'Present',
              '${student.presentDays}',
              valueColor: AppTheme.successColor,
            ),
            _buildDetailRow(
              context,
              Icons.cancel,
              'Absent',
              '${student.absentDays}',
              valueColor: AppTheme.errorColor,
            ),
            _buildDetailRow(
              context,
              Icons.schedule,
              'Tardy',
              '${student.tardyDays}',
              valueColor: AppTheme.warningColor,
            ),
            if (student.lastAttendance != null)
              _buildDetailRow(
                context,
                Icons.access_time,
                'Last Attendance',
                _formatDate(student.lastAttendance!),
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
    IconData icon,
    String label,
    String value, {
    Color? valueColor,
  }) {
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.symmetric(vertical: isTablet ? 8 : 6),
      child: Row(
        children: [
          Icon(
            icon,
            size: isTablet ? 22 : 18,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          SizedBox(width: isTablet ? 12 : 8),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: isTablet ? 16 : 14,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: isTablet ? 16 : 14,
              fontWeight: FontWeight.bold,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}/${date.year}';
  }
}
