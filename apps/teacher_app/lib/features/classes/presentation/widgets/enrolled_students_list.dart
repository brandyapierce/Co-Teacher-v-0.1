import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/responsive_utils.dart';
import '../../../../shared/data/models/student.dart';
import '../../../students/data/repositories/student_repository.dart';
import '../../data/models/class_model.dart';
import '../../data/repositories/class_repository.dart';

/// =============================================================================
/// ENROLLED STUDENTS LIST - Shows students in a class
/// =============================================================================
/// 
/// LEARNING GUIDE: Stateful Widget for Data Fetching
/// 
/// This widget:
/// - Fetches student details from IDs stored in the class
/// - Shows loading/empty/error states
/// - Allows quick removal of students
/// - Updates parent when changes occur
/// =============================================================================

class EnrolledStudentsList extends StatefulWidget {
  final ClassModel classModel;
  final VoidCallback? onStudentRemoved;
  final VoidCallback? onManageStudents;

  const EnrolledStudentsList({
    super.key,
    required this.classModel,
    this.onStudentRemoved,
    this.onManageStudents,
  });

  @override
  State<EnrolledStudentsList> createState() => _EnrolledStudentsListState();
}

class _EnrolledStudentsListState extends State<EnrolledStudentsList> {
  late final StudentRepository _studentRepository;
  late final ClassRepository _classRepository;
  
  List<Student> _students = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _studentRepository = GetIt.instance<StudentRepository>();
    _classRepository = GetIt.instance<ClassRepository>();
    _loadStudents();
  }

  @override
  void didUpdateWidget(EnrolledStudentsList oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Reload if the class changed or student IDs changed
    if (oldWidget.classModel.id != widget.classModel.id ||
        oldWidget.classModel.studentIds.length != widget.classModel.studentIds.length) {
      _loadStudents();
    }
  }

  Future<void> _loadStudents() async {
    if (widget.classModel.studentIds.isEmpty) {
      setState(() {
        _students = [];
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Get all students and filter by enrolled IDs
      final allStudents = await _studentRepository.getStudents();
      final enrolledIds = Set.from(widget.classModel.studentIds);
      
      setState(() {
        _students = allStudents.where((s) => enrolledIds.contains(s.id)).toList();
        _students.sort((a, b) => a.fullName.compareTo(b.fullName));
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load students';
        _isLoading = false;
      });
    }
  }

  Future<void> _removeStudent(Student student) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Student?'),
        content: Text(
          'Remove ${student.fullName} from ${widget.classModel.name}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _classRepository.removeStudentFromClass(
        widget.classModel.id,
        student.id,
      );
      
      setState(() {
        _students.removeWhere((s) => s.id == student.id);
      });
      
      widget.onStudentRemoved?.call();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${student.fullName} removed from class'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isTablet = context.isTablet;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header
        Row(
          children: [
            Icon(
              Icons.people,
              size: isTablet ? 24 : 20,
              color: colorScheme.primary,
            ),
            SizedBox(width: isTablet ? 12 : 8),
            Expanded(
              child: Text(
                'Enrolled Students',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  fontSize: isTablet ? 22 : 18,
                ),
              ),
            ),
            // Student count badge
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: isTablet ? 12 : 8,
                vertical: isTablet ? 6 : 4,
              ),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                '${widget.classModel.studentCount}',
                style: TextStyle(
                  color: colorScheme.onPrimaryContainer,
                  fontWeight: FontWeight.bold,
                  fontSize: isTablet ? 14 : 12,
                ),
              ),
            ),
            SizedBox(width: isTablet ? 12 : 8),
            // Manage button
            TextButton.icon(
              onPressed: widget.onManageStudents,
              icon: Icon(Icons.edit, size: isTablet ? 18 : 16),
              label: Text(
                'Manage',
                style: TextStyle(fontSize: isTablet ? 14 : 12),
              ),
            ),
          ],
        ),
        SizedBox(height: isTablet ? 16 : 12),

        // Content
        _buildContent(context, isTablet),
      ],
    );
  }

  Widget _buildContent(BuildContext context, bool isTablet) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (_isLoading) {
      return Container(
        padding: EdgeInsets.all(isTablet ? 32 : 24),
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return Container(
        padding: EdgeInsets.all(isTablet ? 24 : 16),
        decoration: BoxDecoration(
          color: colorScheme.errorContainer.withOpacity(0.3),
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        ),
        child: Row(
          children: [
            Icon(Icons.error_outline, color: colorScheme.error),
            SizedBox(width: isTablet ? 12 : 8),
            Expanded(child: Text(_error!)),
            TextButton(
              onPressed: _loadStudents,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_students.isEmpty) {
      return Container(
        padding: EdgeInsets.all(isTablet ? 32 : 24),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest.withOpacity(0.5),
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          border: Border.all(
            color: colorScheme.outline.withOpacity(0.2),
            style: BorderStyle.solid,
          ),
        ),
        child: Column(
          children: [
            Icon(
              Icons.person_add_alt_1,
              size: isTablet ? 48 : 40,
              color: colorScheme.onSurfaceVariant.withOpacity(0.5),
            ),
            SizedBox(height: isTablet ? 16 : 12),
            Text(
              'No students enrolled yet',
              style: theme.textTheme.titleMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            SizedBox(height: isTablet ? 8 : 4),
            Text(
              'Tap "Manage" to add students to this class',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant.withOpacity(0.7),
              ),
            ),
          ],
        ),
      );
    }

    // Show student list (max 5 visible, with "show more" if needed)
    final displayStudents = _students.take(5).toList();
    final hasMore = _students.length > 5;

    return Column(
      children: [
        // Student cards
        ...displayStudents.map((student) => _buildStudentTile(
          context,
          student,
          isTablet,
        )),

        // Show more indicator
        if (hasMore)
          Padding(
            padding: EdgeInsets.only(top: isTablet ? 12 : 8),
            child: TextButton.icon(
              onPressed: widget.onManageStudents,
              icon: Icon(Icons.expand_more, size: isTablet ? 20 : 18),
              label: Text(
                'View all ${_students.length} students',
                style: TextStyle(fontSize: isTablet ? 14 : 12),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildStudentTile(BuildContext context, Student student, bool isTablet) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      margin: EdgeInsets.only(bottom: isTablet ? 8 : 6),
      child: Padding(
        padding: EdgeInsets.all(isTablet ? 12 : 8),
        child: Row(
          children: [
            // Avatar
            CircleAvatar(
              radius: isTablet ? 22 : 18,
              backgroundColor: colorScheme.primaryContainer,
              child: Text(
                student.initials,
                style: TextStyle(
                  color: colorScheme.onPrimaryContainer,
                  fontWeight: FontWeight.bold,
                  fontSize: isTablet ? 14 : 12,
                ),
              ),
            ),
            SizedBox(width: isTablet ? 14 : 10),

            // Name and grade
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    student.fullName,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w500,
                      fontSize: isTablet ? 16 : 14,
                    ),
                  ),
                  if (student.grade != null)
                    Text(
                      student.grade!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        fontSize: isTablet ? 13 : 11,
                      ),
                    ),
                ],
              ),
            ),

            // Face enrolled badge
            if (student.isFaceEnrolled)
              Padding(
                padding: EdgeInsets.only(right: isTablet ? 8 : 4),
                child: Tooltip(
                  message: 'Face enrolled',
                  child: Icon(
                    Icons.face,
                    size: isTablet ? 20 : 16,
                    color: AppTheme.successColor,
                  ),
                ),
              ),

            // Remove button
            IconButton(
              onPressed: () => _removeStudent(student),
              icon: Icon(
                Icons.remove_circle_outline,
                size: isTablet ? 22 : 18,
                color: colorScheme.error,
              ),
              tooltip: 'Remove from class',
              visualDensity: VisualDensity.compact,
            ),
          ],
        ),
      ),
    );
  }
}
