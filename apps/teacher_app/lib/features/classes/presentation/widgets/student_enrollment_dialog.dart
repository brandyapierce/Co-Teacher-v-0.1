import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/responsive_utils.dart';
import '../../../../shared/data/models/student.dart';
import '../../../students/data/repositories/student_repository.dart';
import '../../data/models/class_model.dart';
import '../../data/repositories/class_repository.dart';

/// =============================================================================
/// STUDENT ENROLLMENT DIALOG - Manage class roster
/// =============================================================================
/// 
/// LEARNING GUIDE: Multi-Select Dialog Pattern
/// 
/// FEATURES:
/// - Searchable list of all students
/// - Checkboxes for selection
/// - Shows already enrolled students as checked
/// - Batch add/remove operations
/// - Tablet-optimized touch targets
/// =============================================================================

class StudentEnrollmentDialog extends StatefulWidget {
  final ClassModel classModel;
  final void Function(List<String> addedIds, List<String> removedIds)? onSave;

  const StudentEnrollmentDialog({
    super.key,
    required this.classModel,
    this.onSave,
  });

  /// Show the dialog and return true if changes were saved
  static Future<bool> show(BuildContext context, {
    required ClassModel classModel,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => StudentEnrollmentDialog(classModel: classModel),
    );
    return result ?? false;
  }

  @override
  State<StudentEnrollmentDialog> createState() => _StudentEnrollmentDialogState();
}

class _StudentEnrollmentDialogState extends State<StudentEnrollmentDialog> {
  late final StudentRepository _studentRepository;
  late final ClassRepository _classRepository;
  
  List<Student> _allStudents = [];
  Set<String> _selectedStudentIds = {};
  Set<String> _originalStudentIds = {};
  
  bool _isLoading = true;
  bool _isSaving = false;
  String? _error;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _studentRepository = GetIt.instance<StudentRepository>();
    _classRepository = GetIt.instance<ClassRepository>();
    _originalStudentIds = Set.from(widget.classModel.studentIds);
    _selectedStudentIds = Set.from(widget.classModel.studentIds);
    _loadStudents();
  }

  Future<void> _loadStudents() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final students = await _studentRepository.getStudents();
      setState(() {
        _allStudents = students;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load students';
        _isLoading = false;
      });
    }
  }

  List<Student> get _filteredStudents {
    if (_searchQuery.isEmpty) return _allStudents;
    final query = _searchQuery.toLowerCase();
    return _allStudents.where((s) {
      return s.fullName.toLowerCase().contains(query) ||
          (s.grade?.toLowerCase().contains(query) ?? false) ||
          (s.email?.toLowerCase().contains(query) ?? false);
    }).toList();
  }

  bool get _hasChanges {
    return !_setEquals(_selectedStudentIds, _originalStudentIds);
  }

  bool _setEquals(Set<String> a, Set<String> b) {
    if (a.length != b.length) return false;
    return a.every((element) => b.contains(element));
  }

  List<String> get _addedStudents {
    return _selectedStudentIds.where((id) => !_originalStudentIds.contains(id)).toList();
  }

  List<String> get _removedStudents {
    return _originalStudentIds.where((id) => !_selectedStudentIds.contains(id)).toList();
  }

  Future<void> _saveChanges() async {
    if (!_hasChanges) {
      Navigator.pop(context, false);
      return;
    }

    setState(() => _isSaving = true);

    try {
      // Add new students
      for (final studentId in _addedStudents) {
        await _classRepository.addStudentToClass(widget.classModel.id, studentId);
      }

      // Remove unselected students
      for (final studentId in _removedStudents) {
        await _classRepository.removeStudentFromClass(widget.classModel.id, studentId);
      }

      widget.onSave?.call(_addedStudents, _removedStudents);
      
      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      setState(() {
        _error = 'Failed to save changes';
        _isSaving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isTablet = context.isTablet;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
      ),
      child: Container(
        width: isTablet ? 600 : double.infinity,
        constraints: BoxConstraints(
          maxWidth: 600,
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            _buildHeader(context, isTablet),

            // Search bar
            _buildSearchBar(context, isTablet),

            // Stats bar
            _buildStatsBar(context, isTablet),

            // Student list
            Flexible(
              child: _buildContent(context, isTablet),
            ),

            // Actions
            _buildActions(context, isTablet),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isTablet) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final classColor = _getClassColor(widget.classModel.color);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isTablet ? 24 : 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [classColor, classColor.withOpacity(0.8)],
        ),
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppTheme.radiusLarge),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.people_alt,
                color: Colors.white,
                size: isTablet ? 28 : 24,
              ),
              SizedBox(width: isTablet ? 16 : 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Manage Students',
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      widget.classModel.name,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.pop(context, false),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context, bool isTablet) {
    return Padding(
      padding: EdgeInsets.all(isTablet ? 20 : 16),
      child: TextField(
        style: TextStyle(fontSize: isTablet ? 18 : 16),
        decoration: InputDecoration(
          hintText: 'Search students by name or grade...',
          prefixIcon: Icon(Icons.search, size: isTablet ? 24 : 20),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: Icon(Icons.clear, size: isTablet ? 24 : 20),
                  onPressed: () => setState(() => _searchQuery = ''),
                )
              : null,
          contentPadding: EdgeInsets.symmetric(
            horizontal: isTablet ? 20 : 16,
            vertical: isTablet ? 16 : 12,
          ),
        ),
        onChanged: (value) => setState(() => _searchQuery = value),
      ),
    );
  }

  Widget _buildStatsBar(BuildContext context, bool isTablet) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: isTablet ? 20 : 16),
      padding: EdgeInsets.symmetric(
        horizontal: isTablet ? 16 : 12,
        vertical: isTablet ? 12 : 8,
      ),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer.withOpacity(0.3),
        borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(
            context,
            icon: Icons.people,
            label: 'Total',
            value: '${_allStudents.length}',
            isTablet: isTablet,
          ),
          Container(
            width: 1,
            height: isTablet ? 32 : 24,
            color: colorScheme.outline.withOpacity(0.3),
          ),
          _buildStatItem(
            context,
            icon: Icons.check_circle,
            label: 'Selected',
            value: '${_selectedStudentIds.length}',
            color: AppTheme.successColor,
            isTablet: isTablet,
          ),
          if (_hasChanges) ...[
            Container(
              width: 1,
              height: isTablet ? 32 : 24,
              color: colorScheme.outline.withOpacity(0.3),
            ),
            _buildStatItem(
              context,
              icon: Icons.add_circle,
              label: 'Adding',
              value: '${_addedStudents.length}',
              color: AppTheme.infoColor,
              isTablet: isTablet,
            ),
            if (_removedStudents.isNotEmpty) ...[
              Container(
                width: 1,
                height: isTablet ? 32 : 24,
                color: colorScheme.outline.withOpacity(0.3),
              ),
              _buildStatItem(
                context,
                icon: Icons.remove_circle,
                label: 'Removing',
                value: '${_removedStudents.length}',
                color: AppTheme.warningColor,
                isTablet: isTablet,
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildStatItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    Color? color,
    required bool isTablet,
  }) {
    final theme = Theme.of(context);
    
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: isTablet ? 18 : 14, color: color),
            SizedBox(width: isTablet ? 4 : 2),
            Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: isTablet ? 16 : 14,
                color: color,
              ),
            ),
          ],
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: isTablet ? 12 : 10,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildContent(BuildContext context, bool isTablet) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (_isLoading) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(isTablet ? 48 : 32),
          child: const CircularProgressIndicator(),
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(isTablet ? 48 : 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.error_outline,
                size: isTablet ? 48 : 40,
                color: colorScheme.error,
              ),
              SizedBox(height: isTablet ? 16 : 12),
              Text(_error!, style: TextStyle(color: colorScheme.error)),
              SizedBox(height: isTablet ? 16 : 12),
              FilledButton(
                onPressed: _loadStudents,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    final students = _filteredStudents;

    if (students.isEmpty) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(isTablet ? 48 : 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _searchQuery.isEmpty ? Icons.people_outline : Icons.search_off,
                size: isTablet ? 64 : 48,
                color: colorScheme.onSurfaceVariant.withOpacity(0.5),
              ),
              SizedBox(height: isTablet ? 16 : 12),
              Text(
                _searchQuery.isEmpty
                    ? 'No students available'
                    : 'No students match your search',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      padding: EdgeInsets.symmetric(
        horizontal: isTablet ? 12 : 8,
        vertical: isTablet ? 8 : 4,
      ),
      itemCount: students.length,
      itemBuilder: (context, index) {
        final student = students[index];
        final isSelected = _selectedStudentIds.contains(student.id);
        final wasOriginallySelected = _originalStudentIds.contains(student.id);
        
        return _buildStudentTile(
          context,
          student,
          isSelected,
          wasOriginallySelected,
          isTablet,
        );
      },
    );
  }

  Widget _buildStudentTile(
    BuildContext context,
    Student student,
    bool isSelected,
    bool wasOriginallySelected,
    bool isTablet,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Determine status color
    Color? statusColor;
    if (isSelected && !wasOriginallySelected) {
      statusColor = AppTheme.infoColor; // Will be added
    } else if (!isSelected && wasOriginallySelected) {
      statusColor = AppTheme.warningColor; // Will be removed
    }

    return Card(
      margin: EdgeInsets.symmetric(
        horizontal: isTablet ? 8 : 4,
        vertical: isTablet ? 4 : 2,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
        side: statusColor != null
            ? BorderSide(color: statusColor, width: 2)
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: () {
          setState(() {
            if (isSelected) {
              _selectedStudentIds.remove(student.id);
            } else {
              _selectedStudentIds.add(student.id);
            }
          });
        },
        borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
        child: Padding(
          padding: EdgeInsets.all(isTablet ? 12 : 8),
          child: Row(
            children: [
              // Checkbox
              SizedBox(
                width: isTablet ? 48 : 40,
                height: isTablet ? 48 : 40,
                child: Checkbox(
                  value: isSelected,
                  onChanged: (value) {
                    setState(() {
                      if (value == true) {
                        _selectedStudentIds.add(student.id);
                      } else {
                        _selectedStudentIds.remove(student.id);
                      }
                    });
                  },
                ),
              ),
              SizedBox(width: isTablet ? 12 : 8),

              // Avatar
              CircleAvatar(
                radius: isTablet ? 24 : 20,
                backgroundColor: colorScheme.primaryContainer,
                child: Text(
                  student.initials,
                  style: TextStyle(
                    color: colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.bold,
                    fontSize: isTablet ? 16 : 14,
                  ),
                ),
              ),
              SizedBox(width: isTablet ? 16 : 12),

              // Student info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      student.fullName,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                        fontSize: isTablet ? 18 : 16,
                      ),
                    ),
                    if (student.grade != null) ...[
                      SizedBox(height: isTablet ? 4 : 2),
                      Text(
                        student.grade!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          fontSize: isTablet ? 14 : 12,
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // Face enrollment status
              if (student.isFaceEnrolled)
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: isTablet ? 8 : 6,
                    vertical: isTablet ? 4 : 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.successColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.face,
                        size: isTablet ? 16 : 14,
                        color: AppTheme.successColor,
                      ),
                      SizedBox(width: isTablet ? 4 : 2),
                      Text(
                        'Enrolled',
                        style: TextStyle(
                          fontSize: isTablet ? 12 : 10,
                          color: AppTheme.successColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActions(BuildContext context, bool isTablet) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: EdgeInsets.all(isTablet ? 20 : 16),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: colorScheme.outlineVariant),
        ),
      ),
      child: Row(
        children: [
          // Select all / Deselect all
          TextButton.icon(
            onPressed: () {
              setState(() {
                if (_selectedStudentIds.length == _allStudents.length) {
                  _selectedStudentIds.clear();
                } else {
                  _selectedStudentIds = Set.from(_allStudents.map((s) => s.id));
                }
              });
            },
            icon: Icon(
              _selectedStudentIds.length == _allStudents.length
                  ? Icons.deselect
                  : Icons.select_all,
              size: isTablet ? 20 : 18,
            ),
            label: Text(
              _selectedStudentIds.length == _allStudents.length
                  ? 'Deselect All'
                  : 'Select All',
              style: TextStyle(fontSize: isTablet ? 14 : 12),
            ),
          ),
          
          const Spacer(),

          // Cancel
          OutlinedButton(
            onPressed: () => Navigator.pop(context, false),
            style: OutlinedButton.styleFrom(
              minimumSize: Size(isTablet ? 100 : 80, isTablet ? 48 : 40),
            ),
            child: Text(
              'Cancel',
              style: TextStyle(fontSize: isTablet ? 16 : 14),
            ),
          ),
          SizedBox(width: isTablet ? 12 : 8),

          // Save
          FilledButton.icon(
            onPressed: _isSaving ? null : _saveChanges,
            icon: _isSaving
                ? SizedBox(
                    width: isTablet ? 20 : 16,
                    height: isTablet ? 20 : 16,
                    child: const CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Icon(Icons.save, size: isTablet ? 20 : 18),
            label: Text(
              _isSaving ? 'Saving...' : 'Save Changes',
              style: TextStyle(fontSize: isTablet ? 16 : 14),
            ),
            style: FilledButton.styleFrom(
              minimumSize: Size(isTablet ? 140 : 120, isTablet ? 48 : 40),
              backgroundColor: _hasChanges ? null : colorScheme.surfaceContainerHighest,
            ),
          ),
        ],
      ),
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
}
