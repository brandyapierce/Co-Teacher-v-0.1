import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/responsive_utils.dart';
import '../providers/attendance_list_cubit.dart';
import '../providers/attendance_list_state.dart';
import '../widgets/attendance_card.dart';

/// =============================================================================
/// ATTENDANCE LIST PAGE - TABLET OPTIMIZED
/// =============================================================================
/// 
/// LEARNING GUIDE: Tablet-Optimized List View
/// 
/// TABLET OPTIMIZATIONS:
/// 1. Larger search bar and filter chips
/// 2. Responsive grid for attendance cards on wider screens
/// 3. Better spacing and touch targets
/// 4. Centered content with max width constraints
/// =============================================================================

class AttendanceListPage extends StatelessWidget {
  const AttendanceListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) {
        final cubit = AttendanceListCubit();
        cubit.loadRecords();
        return cubit;
      },
      child: const _AttendanceListView(),
    );
  }
}

class _AttendanceListView extends StatelessWidget {
  const _AttendanceListView();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isTablet = context.isTablet;

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: isTablet ? 72 : 56,
        title: Text(
          'Attendance History',
          style: TextStyle(fontSize: isTablet ? 24 : 20),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.filter_list, size: isTablet ? 28 : 24),
            tooltip: 'Filter attendance records',
            onPressed: () => _showFilterBottomSheet(context),
            style: IconButton.styleFrom(
              minimumSize: Size(isTablet ? 56 : 48, isTablet ? 56 : 48),
            ),
          ),
          SizedBox(width: isTablet ? 8 : 0),
        ],
      ),
      body: Column(
        children: [
          _buildSearchBar(context, isTablet),
          _buildActiveFiltersRow(context, isTablet),
          Expanded(
            child: _buildContent(context, isTablet),
          ),
        ],
      ),
      floatingActionButton: SizedBox(
        width: isTablet ? 64 : 56,
        height: isTablet ? 64 : 56,
        child: FloatingActionButton(
          onPressed: () {
            context.read<AttendanceListCubit>().refresh();
          },
          tooltip: 'Refresh attendance records',
          child: Icon(Icons.refresh, size: isTablet ? 28 : 24),
        ),
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context, bool isTablet) {
    final theme = Theme.of(context);
    
    return Padding(
      padding: EdgeInsets.all(isTablet ? 24 : 16),
      child: CenteredContent(
        maxWidth: 800,
        child: TextField(
          style: TextStyle(fontSize: isTablet ? 18 : 16),
          decoration: InputDecoration(
            hintText: 'Search by student name...',
            hintStyle: TextStyle(fontSize: isTablet ? 18 : 16),
            prefixIcon: Padding(
              padding: EdgeInsets.symmetric(horizontal: isTablet ? 16 : 12),
              child: Icon(Icons.search, size: isTablet ? 28 : 24),
            ),
            prefixIconConstraints: BoxConstraints(
              minWidth: isTablet ? 60 : 48,
            ),
            contentPadding: EdgeInsets.symmetric(
              horizontal: isTablet ? 24 : 16,
              vertical: isTablet ? 20 : 16,
            ),
          ),
          onChanged: (query) {
            context.read<AttendanceListCubit>().updateSearchQuery(query);
          },
        ),
      ),
    );
  }

  Widget _buildActiveFiltersRow(BuildContext context, bool isTablet) {
    return BlocBuilder<AttendanceListCubit, AttendanceListState>(
      builder: (context, state) {
        if (!state.hasActiveFilters) return const SizedBox.shrink();

        return CenteredContent(
          maxWidth: 800,
          padding: EdgeInsets.symmetric(
            horizontal: isTablet ? 24 : 16,
            vertical: isTablet ? 12 : 8,
          ),
          child: Wrap(
            spacing: isTablet ? 12 : 8,
            runSpacing: isTablet ? 12 : 8,
            children: [
              if (state.filters.status != null)
                _buildFilterChip(
                  context,
                  label: 'Status: ${state.filters.status}',
                  onDelete: () {
                    context.read<AttendanceListCubit>().filterByStatus(null);
                  },
                  isTablet: isTablet,
                ),
              
              if (state.filters.startDate != null || state.filters.endDate != null)
                _buildFilterChip(
                  context,
                  label: 'Date range',
                  onDelete: () {
                    context.read<AttendanceListCubit>().filterByDateRange(null, null);
                  },
                  isTablet: isTablet,
                ),
              
              TextButton.icon(
                onPressed: () {
                  context.read<AttendanceListCubit>().clearFilters();
                },
                icon: Icon(Icons.clear, size: isTablet ? 20 : 16),
                label: Text(
                  'Clear all',
                  style: TextStyle(fontSize: isTablet ? 16 : 14),
                ),
                style: TextButton.styleFrom(
                  minimumSize: Size(isTablet ? 120 : 100, isTablet ? 48 : 40),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFilterChip(
    BuildContext context, {
    required String label,
    required VoidCallback onDelete,
    required bool isTablet,
  }) {
    final theme = Theme.of(context);
    
    return Chip(
      label: Text(
        label,
        style: TextStyle(fontSize: isTablet ? 16 : 14),
      ),
      onDeleted: onDelete,
      deleteIcon: Icon(Icons.close, size: isTablet ? 20 : 16),
      backgroundColor: theme.colorScheme.primaryContainer.withOpacity(0.5),
      labelStyle: TextStyle(color: theme.colorScheme.onPrimaryContainer),
      padding: EdgeInsets.symmetric(
        horizontal: isTablet ? 12 : 8,
        vertical: isTablet ? 8 : 4,
      ),
    );
  }

  Widget _buildContent(BuildContext context, bool isTablet) {
    return BlocBuilder<AttendanceListCubit, AttendanceListState>(
      builder: (context, state) {
        if (state.isLoading) {
          return Center(
            child: SizedBox(
              width: isTablet ? 56 : 40,
              height: isTablet ? 56 : 40,
              child: const CircularProgressIndicator(strokeWidth: 3),
            ),
          );
        }

        if (state.errorMessage != null) {
          return _buildErrorState(context, state, isTablet);
        }

        final records = state.filteredRecords;

        if (records.isEmpty) {
          return _buildEmptyState(context, state, isTablet);
        }

        return _buildRecordsList(context, state, records, isTablet);
      },
    );
  }

  Widget _buildErrorState(BuildContext context, AttendanceListState state, bool isTablet) {
    final theme = Theme.of(context);
    
    return Center(
      child: Padding(
        padding: EdgeInsets.all(isTablet ? 48 : 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: isTablet ? 80 : 64,
              color: theme.colorScheme.error.withOpacity(0.7),
            ),
            SizedBox(height: isTablet ? 24 : 16),
            Text(
              state.errorMessage!,
              style: TextStyle(
                color: theme.colorScheme.error,
                fontSize: isTablet ? 18 : 16,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: isTablet ? 24 : 16),
            FilledButton.icon(
              onPressed: () {
                context.read<AttendanceListCubit>().loadRecords();
              },
              icon: Icon(Icons.refresh, size: isTablet ? 24 : 20),
              label: Text(
                'Retry',
                style: TextStyle(fontSize: isTablet ? 18 : 16),
              ),
              style: FilledButton.styleFrom(
                minimumSize: Size(isTablet ? 160 : 120, isTablet ? 56 : 48),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, AttendanceListState state, bool isTablet) {
    final theme = Theme.of(context);
    
    return Center(
      child: Padding(
        padding: EdgeInsets.all(isTablet ? 48 : 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 600),
              curve: Curves.elasticOut,
              builder: (context, value, child) {
                return Transform.scale(
                  scale: value,
                  child: Icon(
                    state.hasActiveFilters ? Icons.search_off : Icons.history,
                    size: isTablet ? 100 : 80,
                    color: theme.colorScheme.primary.withOpacity(0.3),
                  ),
                );
              },
            ),
            SizedBox(height: isTablet ? 32 : 24),
            Text(
              state.hasActiveFilters
                  ? 'No records match your filters'
                  : 'No attendance records yet',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface,
                fontSize: isTablet ? 24 : 20,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: isTablet ? 16 : 12),
            Text(
              state.hasActiveFilters
                  ? 'Try adjusting your filters or search terms'
                  : 'Start taking attendance to see records here',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontSize: isTablet ? 18 : 16,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: isTablet ? 32 : 24),
            if (state.hasActiveFilters)
              FilledButton.tonalIcon(
                onPressed: () {
                  context.read<AttendanceListCubit>().clearFilters();
                },
                icon: Icon(Icons.clear_all, size: isTablet ? 24 : 20),
                label: Text(
                  'Clear Filters',
                  style: TextStyle(fontSize: isTablet ? 18 : 16),
                ),
                style: FilledButton.styleFrom(
                  minimumSize: Size(isTablet ? 180 : 140, isTablet ? 56 : 48),
                ),
              )
            else
              FilledButton.icon(
                onPressed: () {
                  context.push('/attendance/scan');
                },
                icon: Icon(Icons.camera_alt, size: isTablet ? 24 : 20),
                label: Text(
                  'Start Attendance Scan',
                  style: TextStyle(fontSize: isTablet ? 18 : 16),
                ),
                style: FilledButton.styleFrom(
                  minimumSize: Size(isTablet ? 220 : 180, isTablet ? 56 : 48),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecordsList(
    BuildContext context,
    AttendanceListState state,
    List records,
    bool isTablet,
  ) {
    final theme = Theme.of(context);
    
    return Column(
      children: [
        // Results count
        CenteredContent(
          maxWidth: 800,
          padding: EdgeInsets.symmetric(
            horizontal: isTablet ? 24 : 16,
            vertical: isTablet ? 12 : 8,
          ),
          child: Row(
            children: [
              Icon(
                Icons.list_alt,
                size: isTablet ? 24 : 20,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              SizedBox(width: isTablet ? 12 : 8),
              Text(
                '${records.length} record${records.length != 1 ? 's' : ''}',
                style: TextStyle(
                  fontSize: isTablet ? 18 : 14,
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        
        // Scrollable list
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async {
              await context.read<AttendanceListCubit>().refresh();
            },
            child: ListView.builder(
              padding: EdgeInsets.symmetric(
                horizontal: isTablet ? 16 : 8,
                vertical: isTablet ? 12 : 8,
              ),
              itemCount: records.length,
              itemBuilder: (context, index) {
                final record = records[index];
                
                return CenteredContent(
                  maxWidth: 800,
                  child: AttendanceCard(
                    record: record,
                    index: index,
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Viewing: ${record.studentName}'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                    onEdit: () => _showEditDialog(context, record, isTablet),
                    onDelete: () => _showDeleteConfirmation(context, record, isTablet),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  void _showFilterBottomSheet(BuildContext context) {
    final isTablet = context.isTablet;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(isTablet ? 24 : 16),
        ),
      ),
      builder: (sheetContext) {
        final cubit = context.read<AttendanceListCubit>();
        final currentFilters = cubit.state.filters;
        final theme = Theme.of(context);

        return Container(
          padding: EdgeInsets.all(isTablet ? 32 : 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.onSurfaceVariant.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              SizedBox(height: isTablet ? 24 : 16),
              
              Text(
                'Filter Attendance',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: isTablet ? 28 : 22,
                ),
              ),
              SizedBox(height: isTablet ? 28 : 20),
              
              Text(
                'Status',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontSize: isTablet ? 20 : 16,
                ),
              ),
              SizedBox(height: isTablet ? 16 : 12),
              
              Wrap(
                spacing: isTablet ? 12 : 8,
                runSpacing: isTablet ? 12 : 8,
                children: [
                  _buildStatusChip(context, sheetContext, 'All', null, currentFilters, isTablet),
                  _buildStatusChip(context, sheetContext, 'Present', 'present', currentFilters, isTablet),
                  _buildStatusChip(context, sheetContext, 'Absent', 'absent', currentFilters, isTablet),
                  _buildStatusChip(context, sheetContext, 'Tardy', 'tardy', currentFilters, isTablet),
                ],
              ),
              
              SizedBox(height: isTablet ? 32 : 24),
              
              SizedBox(
                width: double.infinity,
                height: isTablet ? 56 : 48,
                child: OutlinedButton(
                  onPressed: () {
                    cubit.clearFilters();
                    Navigator.pop(sheetContext);
                  },
                  child: Text(
                    'Clear All Filters',
                    style: TextStyle(fontSize: isTablet ? 18 : 16),
                  ),
                ),
              ),
              SizedBox(height: isTablet ? 16 : 8),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatusChip(
    BuildContext context,
    BuildContext sheetContext,
    String label,
    String? status,
    AttendanceFilters currentFilters,
    bool isTablet,
  ) {
    final cubit = context.read<AttendanceListCubit>();
    final isSelected = currentFilters.status == status;
    
    return ChoiceChip(
      label: Text(
        label,
        style: TextStyle(fontSize: isTablet ? 16 : 14),
      ),
      selected: isSelected,
      onSelected: (_) {
        cubit.filterByStatus(status);
        Navigator.pop(sheetContext);
      },
      padding: EdgeInsets.symmetric(
        horizontal: isTablet ? 16 : 12,
        vertical: isTablet ? 12 : 8,
      ),
    );
  }

  void _showEditDialog(BuildContext context, record, bool isTablet) {
    String selectedStatus = record.status;
    final notesController = TextEditingController(text: record.notes ?? '');
    final theme = Theme.of(context);

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.edit, size: isTablet ? 28 : 24),
            SizedBox(width: isTablet ? 16 : 12),
            Expanded(
              child: Text(
                'Edit: ${record.studentName}',
                style: TextStyle(fontSize: isTablet ? 22 : 18),
              ),
            ),
          ],
        ),
        contentPadding: EdgeInsets.all(isTablet ? 28 : 20),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Status:',
              style: TextStyle(fontSize: isTablet ? 18 : 16),
            ),
            SizedBox(height: isTablet ? 12 : 8),
            DropdownButtonFormField<String>(
              initialValue: selectedStatus,
              style: TextStyle(fontSize: isTablet ? 18 : 16, color: theme.colorScheme.onSurface),
              items: const [
                DropdownMenuItem(value: 'present', child: Text('Present')),
                DropdownMenuItem(value: 'absent', child: Text('Absent')),
                DropdownMenuItem(value: 'tardy', child: Text('Tardy')),
              ],
              onChanged: (value) {
                if (value != null) selectedStatus = value;
              },
            ),
            SizedBox(height: isTablet ? 20 : 16),
            TextField(
              controller: notesController,
              style: TextStyle(fontSize: isTablet ? 18 : 16),
              decoration: InputDecoration(
                labelText: 'Notes',
                labelStyle: TextStyle(fontSize: isTablet ? 18 : 16),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actionsPadding: EdgeInsets.all(isTablet ? 24 : 16),
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.pop(dialogContext),
            style: OutlinedButton.styleFrom(
              minimumSize: Size(isTablet ? 120 : 100, isTablet ? 52 : 44),
            ),
            child: Text('Cancel', style: TextStyle(fontSize: isTablet ? 16 : 14)),
          ),
          SizedBox(width: isTablet ? 12 : 8),
          FilledButton(
            onPressed: () {
              context.read<AttendanceListCubit>().editRecord(
                record.id,
                status: selectedStatus,
                notes: notesController.text,
              );
              Navigator.pop(dialogContext);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      const Icon(Icons.check_circle, color: Colors.white),
                      const SizedBox(width: 12),
                      Text('${record.studentName} updated'),
                    ],
                  ),
                  backgroundColor: AppTheme.successColor,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            style: FilledButton.styleFrom(
              minimumSize: Size(isTablet ? 120 : 100, isTablet ? 52 : 44),
            ),
            child: Text('Save', style: TextStyle(fontSize: isTablet ? 16 : 14)),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, record, bool isTablet) {
    final theme = Theme.of(context);

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.delete_outline, color: theme.colorScheme.error, size: isTablet ? 28 : 24),
            SizedBox(width: isTablet ? 16 : 12),
            Text(
              'Delete Record?',
              style: TextStyle(fontSize: isTablet ? 22 : 18),
            ),
          ],
        ),
        content: Text(
          'Are you sure you want to delete the attendance record for ${record.studentName}?',
          style: TextStyle(fontSize: isTablet ? 18 : 16),
        ),
        contentPadding: EdgeInsets.all(isTablet ? 28 : 20),
        actionsPadding: EdgeInsets.all(isTablet ? 24 : 16),
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.pop(dialogContext),
            style: OutlinedButton.styleFrom(
              minimumSize: Size(isTablet ? 120 : 100, isTablet ? 52 : 44),
            ),
            child: Text('Cancel', style: TextStyle(fontSize: isTablet ? 16 : 14)),
          ),
          SizedBox(width: isTablet ? 12 : 8),
          FilledButton(
            onPressed: () {
              context.read<AttendanceListCubit>().deleteRecord(record.id);
              Navigator.pop(dialogContext);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      const Icon(Icons.delete_outline, color: Colors.white),
                      const SizedBox(width: 12),
                      Text('${record.studentName} removed'),
                    ],
                  ),
                  backgroundColor: AppTheme.warningColor,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            style: FilledButton.styleFrom(
              backgroundColor: theme.colorScheme.error,
              minimumSize: Size(isTablet ? 120 : 100, isTablet ? 52 : 44),
            ),
            child: Text('Delete', style: TextStyle(fontSize: isTablet ? 16 : 14)),
          ),
        ],
      ),
    );
  }
}
