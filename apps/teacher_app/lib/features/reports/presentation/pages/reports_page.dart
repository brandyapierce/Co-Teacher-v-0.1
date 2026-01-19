import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/responsive_utils.dart';
import '../../data/models/attendance_stats.dart';
import '../providers/reports_cubit.dart';
import '../providers/reports_state.dart';
import '../widgets/stats_card.dart';
import '../widgets/attendance_chart.dart';
import '../widgets/student_list_section.dart';

/// =============================================================================
/// REPORTS PAGE - Tablet-Optimized Analytics Dashboard
/// =============================================================================
/// 
/// LEARNING GUIDE: Dashboard Design
/// 
/// KEY PRINCIPLES:
/// 1. Most important info at the top (summary stats)
/// 2. Visual hierarchy with cards and sections
/// 3. Responsive grid layout
/// 4. Touch-friendly period selector
/// 5. Actionable insights (students at risk)
/// =============================================================================

class ReportsPage extends StatelessWidget {
  const ReportsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => ReportsCubit()..loadReports(),
      child: const _ReportsView(),
    );
  }
}

class _ReportsView extends StatelessWidget {
  const _ReportsView();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isTablet = context.isTablet;

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: isTablet ? 72 : 56,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, size: isTablet ? 28 : 24),
          tooltip: 'Back to Home',
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            } else {
              context.go('/home');
            }
          },
        ),
        title: Text(
          'Attendance Reports',
          style: TextStyle(fontSize: isTablet ? 24 : 20),
        ),
        actions: [
          // Export button
          BlocBuilder<ReportsCubit, ReportsState>(
            builder: (context, state) {
              return IconButton(
                icon: state.isExporting
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: colorScheme.onSurface,
                        ),
                      )
                    : Icon(Icons.download, size: isTablet ? 28 : 24),
                tooltip: 'Export to CSV',
                onPressed: state.isExporting
                    ? null
                    : () async {
                        final path = await context.read<ReportsCubit>().exportToCsv();
                        if (path != null && context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Row(
                                children: [
                                  const Icon(Icons.check_circle, color: Colors.white),
                                  const SizedBox(width: 12),
                                  Expanded(child: Text('Report saved to: $path')),
                                ],
                              ),
                              backgroundColor: AppTheme.successColor,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      },
              );
            },
          ),
          // Refresh button
          IconButton(
            icon: Icon(Icons.refresh, size: isTablet ? 28 : 24),
            tooltip: 'Refresh',
            onPressed: () => context.read<ReportsCubit>().loadReports(),
          ),
          SizedBox(width: isTablet ? 8 : 0),
        ],
      ),
      body: Column(
        children: [
          // Period selector
          _buildPeriodSelector(context, isTablet),
          
          // Main content
          Expanded(
            child: BlocBuilder<ReportsCubit, ReportsState>(
              builder: (context, state) {
                if (state.isLoading && !state.hasData) {
                  return Center(
                    child: SizedBox(
                      width: isTablet ? 56 : 40,
                      height: isTablet ? 56 : 40,
                      child: const CircularProgressIndicator(strokeWidth: 3),
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () => context.read<ReportsCubit>().loadReports(),
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: context.responsivePadding,
                    child: CenteredContent(
                      maxWidth: 1000,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Summary stats cards
                          _buildSummarySection(context, state, isTablet),
                          SizedBox(height: isTablet ? 32 : 24),

                          // Chart section
                          if (state.dailyTrends.isNotEmpty) ...[
                            _buildChartSection(context, state, isTablet),
                            SizedBox(height: isTablet ? 32 : 24),
                          ],

                          // Students at risk
                          if (state.studentsAtRisk.isNotEmpty) ...[
                            _buildAtRiskSection(context, state, isTablet),
                            SizedBox(height: isTablet ? 32 : 24),
                          ],

                          // All students breakdown
                          if (state.studentSummaries.isNotEmpty)
                            _buildAllStudentsSection(context, state, isTablet),
                          
                          SizedBox(height: isTablet ? 48 : 32),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodSelector(BuildContext context, bool isTablet) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isTablet ? 24 : 16,
        vertical: isTablet ? 16 : 12,
      ),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        border: Border(
          bottom: BorderSide(color: colorScheme.outlineVariant),
        ),
      ),
      child: BlocBuilder<ReportsCubit, ReportsState>(
        builder: (context, state) {
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: ReportPeriod.values
                  .where((p) => p != ReportPeriod.custom) // Hide custom for now
                  .map((period) {
                final isSelected = state.selectedPeriod == period;
                return Padding(
                  padding: EdgeInsets.only(right: isTablet ? 12 : 8),
                  child: ChoiceChip(
                    label: Text(
                      period.label,
                      style: TextStyle(
                        fontSize: isTablet ? 16 : 14,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                    selected: isSelected,
                    onSelected: (_) => context.read<ReportsCubit>().selectPeriod(period),
                    padding: EdgeInsets.symmetric(
                      horizontal: isTablet ? 16 : 12,
                      vertical: isTablet ? 12 : 8,
                    ),
                  ),
                );
              }).toList(),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSummarySection(BuildContext context, ReportsState state, bool isTablet) {
    final theme = Theme.of(context);
    final stats = state.overallStats;

    if (stats == null) {
      return _buildEmptyStats(context, isTablet);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.analytics,
              size: isTablet ? 28 : 24,
              color: theme.colorScheme.primary,
            ),
            SizedBox(width: isTablet ? 12 : 8),
            Text(
              'Summary',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: isTablet ? 24 : 20,
              ),
            ),
            const Spacer(),
            Text(
              state.activeDateRange.displayString,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontSize: isTablet ? 16 : 14,
              ),
            ),
          ],
        ),
        SizedBox(height: isTablet ? 20 : 16),
        
        ResponsiveGrid(
          spacing: isTablet ? 16 : 12,
          runSpacing: isTablet ? 16 : 12,
          mobileColumns: 2,
          tabletColumns: 4,
          children: [
            StatsCard(
              icon: Icons.check_circle,
              iconColor: AppTheme.successColor,
              label: 'Attendance Rate',
              value: '${stats.attendanceRate.toStringAsFixed(1)}%',
              trend: stats.rateLevel,
              isTablet: isTablet,
            ),
            StatsCard(
              icon: Icons.people,
              iconColor: AppTheme.successColor,
              label: 'Present',
              value: '${stats.presentCount}',
              subtitle: 'of ${stats.totalRecords}',
              isTablet: isTablet,
            ),
            StatsCard(
              icon: Icons.person_off,
              iconColor: AppTheme.errorColor,
              label: 'Absent',
              value: '${stats.absentCount}',
              subtitle: '${stats.absenceRate.toStringAsFixed(1)}%',
              isTablet: isTablet,
            ),
            StatsCard(
              icon: Icons.schedule,
              iconColor: AppTheme.warningColor,
              label: 'Tardy',
              value: '${stats.tardyCount}',
              subtitle: '${stats.tardyRate.toStringAsFixed(1)}%',
              isTablet: isTablet,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildEmptyStats(BuildContext context, bool isTablet) {
    final theme = Theme.of(context);
    
    return Card(
      child: Padding(
        padding: EdgeInsets.all(isTablet ? 32 : 24),
        child: Column(
          children: [
            Icon(
              Icons.bar_chart,
              size: isTablet ? 64 : 48,
              color: theme.colorScheme.onSurfaceVariant.withOpacity(0.5),
            ),
            SizedBox(height: isTablet ? 16 : 12),
            Text(
              'No attendance data for this period',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontSize: isTablet ? 18 : 16,
              ),
            ),
            SizedBox(height: isTablet ? 8 : 4),
            Text(
              'Take attendance to see statistics here',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant.withOpacity(0.7),
                fontSize: isTablet ? 16 : 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChartSection(BuildContext context, ReportsState state, bool isTablet) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.trending_up,
              size: isTablet ? 28 : 24,
              color: theme.colorScheme.primary,
            ),
            SizedBox(width: isTablet ? 12 : 8),
            Text(
              'Daily Trends',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: isTablet ? 24 : 20,
              ),
            ),
          ],
        ),
        SizedBox(height: isTablet ? 20 : 16),
        
        Card(
          child: Padding(
            padding: EdgeInsets.all(isTablet ? 24 : 16),
            child: AttendanceChart(
              trends: state.dailyTrends,
              isTablet: isTablet,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAtRiskSection(BuildContext context, ReportsState state, bool isTablet) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.warning_amber,
              size: isTablet ? 28 : 24,
              color: AppTheme.warningColor,
            ),
            SizedBox(width: isTablet ? 12 : 8),
            Text(
              'Students at Risk',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: isTablet ? 24 : 20,
              ),
            ),
            SizedBox(width: isTablet ? 12 : 8),
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: isTablet ? 12 : 8,
                vertical: isTablet ? 4 : 2,
              ),
              decoration: BoxDecoration(
                color: AppTheme.warningColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${state.studentsAtRisk.length}',
                style: TextStyle(
                  color: AppTheme.warningColor,
                  fontWeight: FontWeight.bold,
                  fontSize: isTablet ? 16 : 14,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: isTablet ? 12 : 8),
        Text(
          'Students with attendance below 80%',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            fontSize: isTablet ? 16 : 14,
          ),
        ),
        SizedBox(height: isTablet ? 16 : 12),
        
        StudentListSection(
          students: state.studentsAtRisk.take(5).toList(),
          isTablet: isTablet,
          showWarning: true,
        ),
      ],
    );
  }

  Widget _buildAllStudentsSection(BuildContext context, ReportsState state, bool isTablet) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.people,
              size: isTablet ? 28 : 24,
              color: theme.colorScheme.primary,
            ),
            SizedBox(width: isTablet ? 12 : 8),
            Text(
              'All Students',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: isTablet ? 24 : 20,
              ),
            ),
            SizedBox(width: isTablet ? 12 : 8),
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: isTablet ? 12 : 8,
                vertical: isTablet ? 4 : 2,
              ),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${state.studentSummaries.length}',
                style: TextStyle(
                  color: theme.colorScheme.onPrimaryContainer,
                  fontWeight: FontWeight.bold,
                  fontSize: isTablet ? 16 : 14,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: isTablet ? 16 : 12),
        
        StudentListSection(
          students: state.studentSummaries,
          isTablet: isTablet,
          showWarning: false,
        ),
      ],
    );
  }
}
