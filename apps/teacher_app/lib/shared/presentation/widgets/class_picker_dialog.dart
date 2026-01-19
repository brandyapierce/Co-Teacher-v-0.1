import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/responsive_utils.dart';
import '../../../features/classes/data/models/class_model.dart';
import '../../../features/classes/data/repositories/class_repository.dart';

/// =============================================================================
/// CLASS PICKER DIALOG - Select a class before taking attendance
/// =============================================================================
/// 
/// LEARNING GUIDE: Reusable Dialog Pattern
/// 
/// WHY A SEPARATE WIDGET?
/// - Used in multiple places (home page, quick actions)
/// - Encapsulates the class loading logic
/// - Consistent UI across the app
/// =============================================================================

class ClassPickerDialog extends StatefulWidget {
  final String teacherId;
  final void Function(ClassModel selectedClass) onClassSelected;

  const ClassPickerDialog({
    super.key,
    required this.teacherId,
    required this.onClassSelected,
  });

  /// Show the dialog and return the selected class
  static Future<ClassModel?> show(BuildContext context, {
    required String teacherId,
  }) async {
    return showDialog<ClassModel>(
      context: context,
      builder: (context) => ClassPickerDialog(
        teacherId: teacherId,
        onClassSelected: (selected) => Navigator.pop(context, selected),
      ),
    );
  }

  @override
  State<ClassPickerDialog> createState() => _ClassPickerDialogState();
}

class _ClassPickerDialogState extends State<ClassPickerDialog> {
  late final ClassRepository _classRepository;
  List<ClassModel> _classes = [];
  bool _isLoading = true;
  String? _error;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _classRepository = GetIt.instance<ClassRepository>();
    _loadClasses();
  }

  Future<void> _loadClasses() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final classes = await _classRepository.getClasses(
        teacherId: widget.teacherId,
      );
      setState(() {
        _classes = classes.where((c) => c.isActive).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load classes';
        _isLoading = false;
      });
    }
  }

  List<ClassModel> get _filteredClasses {
    if (_searchQuery.isEmpty) return _classes;
    final query = _searchQuery.toLowerCase();
    return _classes.where((c) {
      return c.name.toLowerCase().contains(query) ||
          (c.subject?.toLowerCase().contains(query) ?? false) ||
          (c.gradeLevel?.toLowerCase().contains(query) ?? false);
    }).toList();
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
        width: isTablet ? 500 : double.infinity,
        constraints: BoxConstraints(
          maxWidth: 500,
          maxHeight: MediaQuery.of(context).size.height * 0.7,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(isTablet ? 24 : 20),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
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
                        Icons.class_,
                        color: colorScheme.onPrimaryContainer,
                        size: isTablet ? 28 : 24,
                      ),
                      SizedBox(width: isTablet ? 16 : 12),
                      Expanded(
                        child: Text(
                          'Select a Class',
                          style: theme.textTheme.headlineSmall?.copyWith(
                            color: colorScheme.onPrimaryContainer,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.close,
                          color: colorScheme.onPrimaryContainer,
                        ),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  SizedBox(height: isTablet ? 12 : 8),
                  Text(
                    'Choose the class to take attendance for',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onPrimaryContainer.withOpacity(0.8),
                    ),
                  ),
                ],
              ),
            ),

            // Search bar
            Padding(
              padding: EdgeInsets.all(isTablet ? 20 : 16),
              child: TextField(
                style: TextStyle(fontSize: isTablet ? 18 : 16),
                decoration: InputDecoration(
                  hintText: 'Search classes...',
                  prefixIcon: Icon(Icons.search, size: isTablet ? 24 : 20),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: isTablet ? 20 : 16,
                    vertical: isTablet ? 16 : 12,
                  ),
                ),
                onChanged: (value) => setState(() => _searchQuery = value),
              ),
            ),

            // Class list
            Flexible(
              child: _buildContent(context, isTablet),
            ),

            // Quick create button
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(isTablet ? 20 : 16),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: colorScheme.outlineVariant),
                ),
              ),
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  // Navigate to create class
                  // context.push('/classes');
                },
                icon: Icon(Icons.add, size: isTablet ? 24 : 20),
                label: Text(
                  'Create New Class',
                  style: TextStyle(fontSize: isTablet ? 16 : 14),
                ),
                style: OutlinedButton.styleFrom(
                  minimumSize: Size(double.infinity, isTablet ? 52 : 44),
                ),
              ),
            ),
          ],
        ),
      ),
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
              Text(
                _error!,
                style: TextStyle(color: colorScheme.error),
              ),
              SizedBox(height: isTablet ? 16 : 12),
              FilledButton(
                onPressed: _loadClasses,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    final classes = _filteredClasses;

    if (classes.isEmpty) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(isTablet ? 48 : 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _searchQuery.isEmpty ? Icons.class_outlined : Icons.search_off,
                size: isTablet ? 64 : 48,
                color: colorScheme.onSurfaceVariant.withOpacity(0.5),
              ),
              SizedBox(height: isTablet ? 16 : 12),
              Text(
                _searchQuery.isEmpty
                    ? 'No classes yet'
                    : 'No classes match your search',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              if (_searchQuery.isEmpty) ...[
                SizedBox(height: isTablet ? 8 : 4),
                Text(
                  'Create a class to get started',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant.withOpacity(0.7),
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      padding: EdgeInsets.symmetric(horizontal: isTablet ? 12 : 8),
      itemCount: classes.length,
      itemBuilder: (context, index) {
        final classModel = classes[index];
        return _buildClassTile(context, classModel, isTablet);
      },
    );
  }

  Widget _buildClassTile(BuildContext context, ClassModel classModel, bool isTablet) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final classColor = _getClassColor(classModel.color);

    return Card(
      margin: EdgeInsets.symmetric(
        horizontal: isTablet ? 8 : 4,
        vertical: isTablet ? 6 : 4,
      ),
      child: InkWell(
        onTap: () => widget.onClassSelected(classModel),
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        child: Padding(
          padding: EdgeInsets.all(isTablet ? 16 : 12),
          child: Row(
            children: [
              // Color indicator
              Container(
                width: isTablet ? 56 : 48,
                height: isTablet ? 56 : 48,
                decoration: BoxDecoration(
                  color: classColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                ),
                child: Center(
                  child: Text(
                    _getInitials(classModel.name),
                    style: TextStyle(
                      color: classColor,
                      fontWeight: FontWeight.bold,
                      fontSize: isTablet ? 20 : 18,
                    ),
                  ),
                ),
              ),
              SizedBox(width: isTablet ? 16 : 12),

              // Class info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      classModel.name,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        fontSize: isTablet ? 18 : 16,
                      ),
                    ),
                    SizedBox(height: isTablet ? 4 : 2),
                    Text(
                      classModel.displaySubtitle,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        fontSize: isTablet ? 14 : 12,
                      ),
                    ),
                  ],
                ),
              ),

              // Student count
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: isTablet ? 12 : 8,
                  vertical: isTablet ? 6 : 4,
                ),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.people,
                      size: isTablet ? 18 : 16,
                      color: colorScheme.onPrimaryContainer,
                    ),
                    SizedBox(width: isTablet ? 4 : 2),
                    Text(
                      '${classModel.studentCount}',
                      style: TextStyle(
                        color: colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.bold,
                        fontSize: isTablet ? 14 : 12,
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(width: isTablet ? 12 : 8),

              // Arrow
              Icon(
                Icons.arrow_forward_ios,
                size: isTablet ? 20 : 16,
                color: colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
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

  String _getInitials(String name) {
    final words = name.split(' ');
    if (words.length >= 2) {
      return '${words[0][0]}${words[1][0]}'.toUpperCase();
    }
    return name.substring(0, name.length >= 2 ? 2 : 1).toUpperCase();
  }
}
