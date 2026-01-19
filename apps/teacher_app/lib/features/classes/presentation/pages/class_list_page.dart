import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/responsive_utils.dart';
import '../../data/models/class_model.dart';
import '../providers/class_list_cubit.dart';
import '../providers/class_list_state.dart';
import '../widgets/class_card.dart';
import '../widgets/create_class_dialog.dart';
import '../widgets/student_enrollment_dialog.dart';
import '../widgets/enrolled_students_list.dart';

/// =============================================================================
/// CLASS LIST PAGE - Tablet-optimized class management
/// =============================================================================
/// 
/// LEARNING GUIDE: Master-Detail Pattern
/// 
/// ON TABLETS:
/// - List on the left, details on the right
/// - Efficient use of screen real estate
/// - No navigation needed for viewing details
/// 
/// ON PHONES:
/// - Full-screen list
/// - Navigate to separate detail page
/// =============================================================================

class ClassListPage extends StatelessWidget {
  const ClassListPage({super.key});

  @override
  Widget build(BuildContext context) {
    // TODO: Get teacherId from auth state
    const teacherId = 'teacher-1';

    return BlocProvider(
      create: (context) => ClassListCubit(teacherId: teacherId)..loadClasses(),
      child: const _ClassListView(),
    );
  }
}

class _ClassListView extends StatelessWidget {
  const _ClassListView();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isTablet = context.isTablet;
    final isLandscape = ResponsiveLayout.isLandscape(context);

    return Scaffold(
      appBar: _buildAppBar(context, isTablet),
      body: Column(
        children: [
          _buildSearchBar(context, isTablet),
          Expanded(
            child: isTablet && isLandscape
                ? _buildMasterDetailLayout(context, isTablet)
                : _buildListOnlyLayout(context, isTablet),
          ),
        ],
      ),
      floatingActionButton: _buildFAB(context, isTablet),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context, bool isTablet) {
    final theme = Theme.of(context);
    
    return AppBar(
      toolbarHeight: isTablet ? 72 : 56,
      title: BlocBuilder<ClassListCubit, ClassListState>(
        builder: (context, state) {
          if (state.isSelectionMode) {
            return Text(
              '${state.selectionCount} selected',
              style: TextStyle(fontSize: isTablet ? 24 : 20),
            );
          }
          return Text(
            'My Classes',
            style: TextStyle(fontSize: isTablet ? 24 : 20),
          );
        },
      ),
      leading: BlocBuilder<ClassListCubit, ClassListState>(
        builder: (context, state) {
          if (state.isSelectionMode) {
            return IconButton(
              icon: Icon(Icons.close, size: isTablet ? 28 : 24),
              onPressed: () => context.read<ClassListCubit>().exitSelectionMode(),
            );
          }
          // Back button to go home
          return IconButton(
            icon: Icon(Icons.arrow_back, size: isTablet ? 28 : 24),
            tooltip: 'Back to Home',
            onPressed: () {
              if (Navigator.canPop(context)) {
                Navigator.pop(context);
              } else {
                context.go('/home');
              }
            },
          );
        },
      ),
      actions: [
        BlocBuilder<ClassListCubit, ClassListState>(
          builder: (context, state) {
            if (state.isSelectionMode) {
              return Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.select_all, size: isTablet ? 28 : 24),
                    tooltip: 'Select all',
                    onPressed: () => context.read<ClassListCubit>().selectAll(),
                  ),
                  IconButton(
                    icon: Icon(Icons.delete, size: isTablet ? 28 : 24),
                    tooltip: 'Delete selected',
                    onPressed: state.hasSelection
                        ? () => _confirmDeleteSelected(context, state.selectionCount)
                        : null,
                  ),
                ],
              );
            }
            return IconButton(
              icon: Icon(Icons.refresh, size: isTablet ? 28 : 24),
              tooltip: 'Refresh',
              onPressed: () => context.read<ClassListCubit>().refresh(),
            );
          },
        ),
        SizedBox(width: isTablet ? 8 : 0),
      ],
    );
  }

  Widget _buildSearchBar(BuildContext context, bool isTablet) {
    return CenteredContent(
      maxWidth: 800,
      padding: EdgeInsets.all(isTablet ? 24 : 16),
      child: BlocBuilder<ClassListCubit, ClassListState>(
        builder: (context, state) {
          return TextField(
            style: TextStyle(fontSize: isTablet ? 18 : 16),
            decoration: InputDecoration(
              hintText: 'Search classes...',
              hintStyle: TextStyle(fontSize: isTablet ? 18 : 16),
              prefixIcon: Padding(
                padding: EdgeInsets.symmetric(horizontal: isTablet ? 16 : 12),
                child: Icon(Icons.search, size: isTablet ? 28 : 24),
              ),
              prefixIconConstraints: BoxConstraints(minWidth: isTablet ? 60 : 48),
              suffixIcon: state.searchQuery.isNotEmpty
                  ? IconButton(
                      icon: Icon(Icons.clear, size: isTablet ? 24 : 20),
                      onPressed: () {
                        context.read<ClassListCubit>().clearSearch();
                      },
                    )
                  : null,
              contentPadding: EdgeInsets.symmetric(
                horizontal: isTablet ? 24 : 16,
                vertical: isTablet ? 20 : 16,
              ),
            ),
            onChanged: (query) {
              context.read<ClassListCubit>().updateSearchQuery(query);
            },
          );
        },
      ),
    );
  }

  Widget _buildMasterDetailLayout(BuildContext context, bool isTablet) {
    return Row(
      children: [
        // Master list (left side)
        Expanded(
          flex: 4,
          child: _buildClassList(context, isTablet),
        ),
        // Divider
        VerticalDivider(width: 1),
        // Detail view (right side)
        Expanded(
          flex: 6,
          child: _buildDetailPanel(context, isTablet),
        ),
      ],
    );
  }

  Widget _buildListOnlyLayout(BuildContext context, bool isTablet) {
    return _buildClassList(context, isTablet);
  }

  Widget _buildClassList(BuildContext context, bool isTablet) {
    return BlocBuilder<ClassListCubit, ClassListState>(
      builder: (context, state) {
        if (state.isLoading && state.classes.isEmpty) {
          return Center(
            child: SizedBox(
              width: isTablet ? 56 : 40,
              height: isTablet ? 56 : 40,
              child: const CircularProgressIndicator(strokeWidth: 3),
            ),
          );
        }

        if (state.errorMessage != null && state.classes.isEmpty) {
          return _buildErrorState(context, state, isTablet);
        }

        if (state.filteredClasses.isEmpty) {
          return _buildEmptyState(context, state, isTablet);
        }

        return RefreshIndicator(
          onRefresh: () => context.read<ClassListCubit>().refresh(),
          child: ListView.builder(
            padding: EdgeInsets.symmetric(
              horizontal: isTablet ? 16 : 8,
              vertical: isTablet ? 8 : 4,
            ),
            itemCount: state.filteredClasses.length,
            itemBuilder: (context, index) {
              final classModel = state.filteredClasses[index];
              final isSelected = state.selectedClass?.id == classModel.id;
              final isChecked = state.isClassSelected(classModel.id);

              return ClassCard(
                classModel: classModel,
                isSelected: isSelected,
                isChecked: isChecked,
                isSelectionMode: state.isSelectionMode,
                onTap: () {
                  if (state.isSelectionMode) {
                    context.read<ClassListCubit>().toggleClassSelection(classModel.id);
                  } else {
                    context.read<ClassListCubit>().selectClass(classModel);
                    // On phone, navigate to detail page
                    if (!context.isTablet || !ResponsiveLayout.isLandscape(context)) {
                      context.push('/classes/${classModel.id}');
                    }
                  }
                },
                onLongPress: () {
                  if (!state.isSelectionMode) {
                    context.read<ClassListCubit>().enterSelectionMode();
                    context.read<ClassListCubit>().toggleClassSelection(classModel.id);
                  }
                },
                onTakeAttendance: () {
                  // Navigate to attendance scan with this class
                  context.push('/attendance/scan', extra: classModel);
                },
                onEdit: () => _showEditDialog(context, classModel, isTablet),
                onDelete: () => _confirmDelete(context, classModel, isTablet),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildDetailPanel(BuildContext context, bool isTablet) {
    final theme = Theme.of(context);
    
    return BlocBuilder<ClassListCubit, ClassListState>(
      builder: (context, state) {
        if (state.selectedClass == null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.class_outlined,
                  size: 80,
                  color: theme.colorScheme.onSurfaceVariant.withOpacity(0.3),
                ),
                const SizedBox(height: 24),
                Text(
                  'Select a class to view details',
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          );
        }

        final classModel = state.selectedClass!;
        
        return SingleChildScrollView(
          padding: EdgeInsets.all(isTablet ? 32 : 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with color accent
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      _getClassColor(classModel.color),
                      _getClassColor(classModel.color).withOpacity(0.7),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      classModel.name,
                      style: theme.textTheme.headlineMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      classModel.displaySubtitle,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Stats row
              Row(
                children: [
                  _buildStatCard(
                    context,
                    icon: Icons.people,
                    label: 'Students',
                    value: '${classModel.studentCount}',
                    isTablet: isTablet,
                  ),
                  const SizedBox(width: 16),
                  _buildStatCard(
                    context,
                    icon: Icons.calendar_today,
                    label: 'Year',
                    value: classModel.academicYear ?? 'N/A',
                    isTablet: isTablet,
                  ),
                ],
              ),
              
              const SizedBox(height: 32),
              
              // Schedule section
              Text(
                'Schedule',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              if (classModel.schedule?.isNotEmpty ?? false)
                ...classModel.schedule!.map((s) => _buildScheduleTile(context, s, isTablet))
              else
                Text(
                  'No schedule set',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              
              const SizedBox(height: 32),
              
              // Actions - Primary
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () {
                        // Navigate to attendance scan with this class (passing ClassModel)
                        context.push('/attendance/scan', extra: classModel);
                      },
                      icon: const Icon(Icons.camera_alt),
                      label: const Text('Take Attendance'),
                      style: FilledButton.styleFrom(
                        minimumSize: Size(0, isTablet ? 56 : 48),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 32),

              // Enrolled Students Section
              EnrolledStudentsList(
                classModel: classModel,
                onStudentRemoved: () {
                  // Refresh the class list to update student counts
                  context.read<ClassListCubit>().refresh();
                },
                onManageStudents: () => _showStudentEnrollment(context, classModel, isTablet),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatCard(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    required bool isTablet,
  }) {
    final theme = Theme.of(context);
    
    return Expanded(
      child: Card(
        child: Padding(
          padding: EdgeInsets.all(isTablet ? 20 : 16),
          child: Row(
            children: [
              Icon(
                icon,
                size: isTablet ? 32 : 28,
                color: theme.colorScheme.primary,
              ),
              SizedBox(width: isTablet ? 16 : 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    label,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildScheduleTile(BuildContext context, ClassSchedule schedule, bool isTablet) {
    final theme = Theme.of(context);
    
    return Card(
      margin: EdgeInsets.only(bottom: isTablet ? 12 : 8),
      child: ListTile(
        contentPadding: EdgeInsets.symmetric(
          horizontal: isTablet ? 20 : 16,
          vertical: isTablet ? 8 : 4,
        ),
        leading: CircleAvatar(
          backgroundColor: theme.colorScheme.primaryContainer,
          child: Text(
            schedule.dayNameShort,
            style: TextStyle(
              color: theme.colorScheme.onPrimaryContainer,
              fontWeight: FontWeight.bold,
              fontSize: isTablet ? 14 : 12,
            ),
          ),
        ),
        title: Text(
          schedule.dayName,
          style: TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: isTablet ? 18 : 16,
          ),
        ),
        subtitle: Text(
          '${schedule.startTime} - ${schedule.endTime}${schedule.period != null ? ' (Period ${schedule.period})' : ''}',
          style: TextStyle(fontSize: isTablet ? 16 : 14),
        ),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, ClassListState state, bool isTablet) {
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
              onPressed: () => context.read<ClassListCubit>().loadClasses(),
              icon: Icon(Icons.refresh, size: isTablet ? 24 : 20),
              label: Text('Retry', style: TextStyle(fontSize: isTablet ? 18 : 16)),
              style: FilledButton.styleFrom(
                minimumSize: Size(isTablet ? 160 : 120, isTablet ? 56 : 48),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, ClassListState state, bool isTablet) {
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
                    state.searchQuery.isNotEmpty ? Icons.search_off : Icons.class_outlined,
                    size: isTablet ? 100 : 80,
                    color: theme.colorScheme.primary.withOpacity(0.3),
                  ),
                );
              },
            ),
            SizedBox(height: isTablet ? 32 : 24),
            Text(
              state.searchQuery.isNotEmpty
                  ? 'No classes match your search'
                  : 'No classes yet',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface,
                fontSize: isTablet ? 24 : 20,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: isTablet ? 16 : 12),
            Text(
              state.searchQuery.isNotEmpty
                  ? 'Try a different search term'
                  : 'Create your first class to get started',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontSize: isTablet ? 18 : 16,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: isTablet ? 32 : 24),
            if (state.searchQuery.isEmpty)
              FilledButton.icon(
                onPressed: () => _showCreateDialog(context, isTablet),
                icon: Icon(Icons.add, size: isTablet ? 24 : 20),
                label: Text(
                  'Create Class',
                  style: TextStyle(fontSize: isTablet ? 18 : 16),
                ),
                style: FilledButton.styleFrom(
                  minimumSize: Size(isTablet ? 180 : 140, isTablet ? 56 : 48),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFAB(BuildContext context, bool isTablet) {
    return BlocBuilder<ClassListCubit, ClassListState>(
      builder: (context, state) {
        if (state.isSelectionMode) return const SizedBox.shrink();
        
        return SizedBox(
          height: isTablet ? 64 : 56,
          child: FloatingActionButton.extended(
            onPressed: () => _showCreateDialog(context, isTablet),
            icon: Icon(Icons.add, size: isTablet ? 28 : 24),
            label: Text(
              'New Class',
              style: TextStyle(fontSize: isTablet ? 18 : 16),
            ),
          ),
        );
      },
    );
  }

  Color _getClassColor(String? hex) {
    if (hex == null) return AppTheme.primaryColor;
    try {
      return Color(int.parse(hex.replaceFirst('#', '0xFF')));
    } catch (e) {
      return AppTheme.primaryColor;
    }
  }

  void _showCreateDialog(BuildContext context, bool isTablet) {
    showDialog(
      context: context,
      builder: (dialogContext) => CreateClassDialog(
        onSubmit: (name, gradeLevel, subject, room, color) async {
          final cubit = context.read<ClassListCubit>();
          final newClass = await cubit.createClass(
            name: name,
            gradeLevel: gradeLevel,
            subject: subject,
            room: room,
            color: color,
          );
          if (newClass != null) {
            Navigator.pop(dialogContext);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const Icon(Icons.check_circle, color: Colors.white),
                    const SizedBox(width: 12),
                    Text('Class "$name" created!'),
                  ],
                ),
                backgroundColor: AppTheme.successColor,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        },
      ),
    );
  }

  void _showEditDialog(BuildContext context, ClassModel classModel, bool isTablet) {
    showDialog(
      context: context,
      builder: (dialogContext) => CreateClassDialog(
        classModel: classModel,
        onSubmit: (name, gradeLevel, subject, room, color) async {
          final cubit = context.read<ClassListCubit>();
          final updated = classModel.copyWith(
            name: name,
            gradeLevel: gradeLevel,
            subject: subject,
            room: room,
            color: color,
          );
          final success = await cubit.updateClass(updated);
          if (success) {
            Navigator.pop(dialogContext);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const Icon(Icons.check_circle, color: Colors.white),
                    const SizedBox(width: 12),
                    Text('Class "$name" updated!'),
                  ],
                ),
                backgroundColor: AppTheme.successColor,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        },
      ),
    );
  }

  void _confirmDelete(BuildContext context, ClassModel classModel, bool isTablet) {
    final theme = Theme.of(context);
    
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.delete_outline, color: theme.colorScheme.error),
            const SizedBox(width: 12),
            const Text('Delete Class?'),
          ],
        ),
        content: Text(
          'Are you sure you want to delete "${classModel.name}"? This action cannot be undone.',
        ),
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              final success = await context.read<ClassListCubit>().deleteClass(classModel.id);
              if (success) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('${classModel.name} deleted'),
                    backgroundColor: AppTheme.warningColor,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            style: FilledButton.styleFrom(backgroundColor: theme.colorScheme.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteSelected(BuildContext context, int count) {
    final theme = Theme.of(context);
    
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.delete_outline, color: theme.colorScheme.error),
            const SizedBox(width: 12),
            const Text('Delete Classes?'),
          ],
        ),
        content: Text(
          'Are you sure you want to delete $count class${count != 1 ? 'es' : ''}? This action cannot be undone.',
        ),
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              await context.read<ClassListCubit>().deleteSelectedClasses();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('$count class${count != 1 ? 'es' : ''} deleted'),
                  backgroundColor: AppTheme.warningColor,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            style: FilledButton.styleFrom(backgroundColor: theme.colorScheme.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showStudentEnrollment(BuildContext context, ClassModel classModel, bool isTablet) async {
    final saved = await StudentEnrollmentDialog.show(
      context,
      classModel: classModel,
    );

    if (saved && context.mounted) {
      // Refresh the class list to show updated student counts
      context.read<ClassListCubit>().refresh();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 12),
              Text('Student roster updated for "${classModel.name}"'),
            ],
          ),
          backgroundColor: AppTheme.successColor,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}
