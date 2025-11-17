import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../providers/attendance_list_cubit.dart';
import '../providers/attendance_list_state.dart';
import '../widgets/attendance_card.dart';

/// Main page for viewing attendance history
/// 
/// This page demonstrates the BLoC pattern:
/// 1. BlocProvider creates and provides the Cubit
/// 2. BlocBuilder listens for state changes
/// 3. UI automatically rebuilds when state changes
/// 4. User interactions call Cubit methods
/// 
/// EDUCATIONAL NOTE - Repository Pattern Integration:
/// The Cubit now uses AttendanceRepository internally via GetIt,
/// so we no longer need to pass Hive boxes as parameters.
/// This makes the code cleaner and easier to test.
class AttendanceListPage extends StatelessWidget {
  const AttendanceListPage({super.key});

  @override
  Widget build(BuildContext context) {
    // BlocProvider creates the Cubit and makes it available to child widgets
    // When this widget is disposed, the Cubit is automatically closed
    return BlocProvider(
      create: (context) {
        // Create the Cubit (repository is injected via GetIt internally)
        final cubit = AttendanceListCubit();
        // Load records immediately when page opens
        cubit.loadRecords();
        return cubit;
      },
      child: const _AttendanceListView(),
    );
  }
}

/// The actual view - separated for cleaner code
/// This is where we build the UI based on the current state
class _AttendanceListView extends StatelessWidget {
  const _AttendanceListView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Attendance History'),
        actions: [
          // Filter button with tooltip
          IconButton(
            icon: const Icon(Icons.filter_list),
            tooltip: 'Filter attendance records', // POLISH: Helpful tooltip
            onPressed: () => _showFilterBottomSheet(context),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          _buildSearchBar(context),
          
          // Filter chips (show active filters)
          _buildActiveFiltersRow(context),
          
          // Main content: List or empty/loading/error state
          Expanded(
            child: _buildContent(context),
          ),
        ],
      ),
      // Floating action button to refresh with tooltip
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          context.read<AttendanceListCubit>().refresh();
        },
        tooltip: 'Refresh attendance records', // POLISH: Helpful tooltip
        child: const Icon(Icons.refresh),
      ),
    );
  }

  /// Build the search bar
  Widget _buildSearchBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: TextField(
        decoration: InputDecoration(
          hintText: 'Search by student name...',
          prefixIcon: const Icon(Icons.search),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          filled: true,
          fillColor: Colors.grey[100],
        ),
        onChanged: (query) {
          // Call Cubit method to update search query
          // This triggers a state change, which rebuilds the list
          context.read<AttendanceListCubit>().updateSearchQuery(query);
        },
      ),
    );
  }

  /// Show active filters as removable chips
  Widget _buildActiveFiltersRow(BuildContext context) {
    // BlocBuilder listens to state changes and rebuilds this widget
    return BlocBuilder<AttendanceListCubit, AttendanceListState>(
      builder: (context, state) {
        // Only show if filters are active
        if (!state.hasActiveFilters) return const SizedBox.shrink();

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              // Status filter chip
              if (state.filters.status != null)
                _buildFilterChip(
                  context,
                  label: 'Status: ${state.filters.status}',
                  onDelete: () {
                    context.read<AttendanceListCubit>().filterByStatus(null);
                  },
                ),
              
              // Date range filter chip
              if (state.filters.startDate != null || state.filters.endDate != null)
                _buildFilterChip(
                  context,
                  label: 'Date range',
                  onDelete: () {
                    context.read<AttendanceListCubit>().filterByDateRange(null, null);
                  },
                ),
              
              // Clear all button
              TextButton.icon(
                onPressed: () {
                  context.read<AttendanceListCubit>().clearFilters();
                },
                icon: const Icon(Icons.clear, size: 16),
                label: const Text('Clear all'),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Build a filter chip
  Widget _buildFilterChip(BuildContext context, {
    required String label,
    required VoidCallback onDelete,
  }) {
    return Chip(
      label: Text(label),
      onDeleted: onDelete,
      deleteIcon: const Icon(Icons.close, size: 16),
      backgroundColor: Colors.blue[50],
      labelStyle: TextStyle(color: Colors.blue[800]),
    );
  }

  /// Build the main content area
  /// This is where BLoC pattern shines - automatic UI updates based on state
  Widget _buildContent(BuildContext context) {
    // BlocBuilder rebuilds whenever the state changes
    return BlocBuilder<AttendanceListCubit, AttendanceListState>(
      builder: (context, state) {
        // Show loading spinner
        if (state.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        // Show error message
        if (state.errorMessage != null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                const SizedBox(height: 16),
                Text(
                  state.errorMessage!,
                  style: const TextStyle(color: Colors.red),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    context.read<AttendanceListCubit>().loadRecords();
                  },
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        // Get filtered records (computed property in state)
        final records = state.filteredRecords;

        // Show empty state with better design
        if (records.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // POLISH: Animated icon for empty state
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.0, end: 1.0),
                    duration: const Duration(milliseconds: 600),
                    curve: Curves.elasticOut,
                    builder: (context, value, child) {
                      return Transform.scale(
                        scale: value,
                        child: Icon(
                          state.hasActiveFilters ? Icons.search_off : Icons.history,
                          size: 80,
                          color: Colors.blue[200],
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 24),
                  Text(
                    state.hasActiveFilters
                        ? 'No records match your filters'
                        : 'No attendance records yet',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[700],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    state.hasActiveFilters
                        ? 'Try adjusting your filters or search terms'
                        : 'Start taking attendance to see records here',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[500],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  if (state.hasActiveFilters)
                    ElevatedButton.icon(
                      onPressed: () {
                        context.read<AttendanceListCubit>().clearFilters();
                      },
                      icon: const Icon(Icons.clear_all),
                      label: const Text('Clear Filters'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                      ),
                    )
                  else
                    OutlinedButton.icon(
                      onPressed: () {
                        context.push('/attendance/scan');
                      },
                      icon: const Icon(Icons.camera_alt),
                      label: const Text('Start Attendance Scan'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );
        }

        // Show list of records
        return Column(
          children: [
            // Results count
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Text(
                    '${records.length} record${records.length != 1 ? 's' : ''}',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
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
                  itemCount: records.length,
                  itemBuilder: (context, index) {
                    final record = records[index];
                    
                    // Use our custom AttendanceCard widget with animation
                    return AttendanceCard(
                      record: record,
                      index: index, // POLISH: For staggered animations
                      onTap: () {
                        // TODO: Navigate to detail page
                        // For now, just show a message
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Tapped: ${record.studentName}')),
                        );
                      },
                      onEdit: () {
                        _showEditDialog(context, record);
                      },
                      onDelete: () {
                        _showDeleteConfirmation(context, record);
                      },
                    );
                  },
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  /// Show filter bottom sheet
  void _showFilterBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (sheetContext) {
        // Important: Use context.read to get the Cubit from parent context
        final cubit = context.read<AttendanceListCubit>();
        final currentFilters = cubit.state.filters;

        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Filter Attendance',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 24),
              
              // Status filter
              Text(
                'Status',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                children: [
                  ChoiceChip(
                    label: const Text('All'),
                    selected: currentFilters.status == null,
                    onSelected: (_) {
                      cubit.filterByStatus(null);
                      Navigator.pop(sheetContext);
                    },
                  ),
                  ChoiceChip(
                    label: const Text('Present'),
                    selected: currentFilters.status == 'present',
                    onSelected: (_) {
                      cubit.filterByStatus('present');
                      Navigator.pop(sheetContext);
                    },
                  ),
                  ChoiceChip(
                    label: const Text('Absent'),
                    selected: currentFilters.status == 'absent',
                    onSelected: (_) {
                      cubit.filterByStatus('absent');
                      Navigator.pop(sheetContext);
                    },
                  ),
                  ChoiceChip(
                    label: const Text('Tardy'),
                    selected: currentFilters.status == 'tardy',
                    onSelected: (_) {
                      cubit.filterByStatus('tardy');
                      Navigator.pop(sheetContext);
                    },
                  ),
                ],
              ),
              
              const SizedBox(height: 24),
              
              // Clear all button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () {
                    cubit.clearFilters();
                    Navigator.pop(sheetContext);
                  },
                  child: const Text('Clear All Filters'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Show edit dialog
  void _showEditDialog(BuildContext context, record) {
    String selectedStatus = record.status;
    final notesController = TextEditingController(text: record.notes ?? '');

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Edit: ${record.studentName}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Status:'),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: selectedStatus,
              items: const [
                DropdownMenuItem(value: 'present', child: Text('Present')),
                DropdownMenuItem(value: 'absent', child: Text('Absent')),
                DropdownMenuItem(value: 'tardy', child: Text('Tardy')),
              ],
              onChanged: (value) {
                if (value != null) selectedStatus = value;
              },
            ),
            const SizedBox(height: 16),
            TextField(
              controller: notesController,
              decoration: const InputDecoration(
                labelText: 'Notes',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              context.read<AttendanceListCubit>().editRecord(
                    record.id,
                    status: selectedStatus,
                    notes: notesController.text,
                  );
              Navigator.pop(dialogContext);
              // POLISH: Better success feedback with icon and color
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      const Icon(Icons.check_circle, color: Colors.white),
                      const SizedBox(width: 12),
                      Text('${record.studentName} updated successfully'),
                    ],
                  ),
                  backgroundColor: Colors.green,
                  behavior: SnackBarBehavior.floating,
                  duration: const Duration(seconds: 2),
                ),
              );
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  /// Show delete confirmation
  void _showDeleteConfirmation(BuildContext context, record) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Record?'),
        content: Text(
          'Are you sure you want to delete the attendance record for ${record.studentName}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              context.read<AttendanceListCubit>().deleteRecord(record.id);
              Navigator.pop(dialogContext);
              // POLISH: Better delete feedback
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      const Icon(Icons.delete_outline, color: Colors.white),
                      const SizedBox(width: 12),
                      Text('${record.studentName} removed from records'),
                    ],
                  ),
                  backgroundColor: Colors.orange,
                  behavior: SnackBarBehavior.floating,
                  action: SnackBarAction(
                    label: 'UNDO',
                    textColor: Colors.white,
                    onPressed: () {
                      // TODO: Implement undo functionality
                    },
                  ),
                  duration: const Duration(seconds: 3),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

