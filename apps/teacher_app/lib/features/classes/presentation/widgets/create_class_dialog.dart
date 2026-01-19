import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/responsive_utils.dart';
import '../../data/models/class_model.dart';

/// =============================================================================
/// CREATE/EDIT CLASS DIALOG - Tablet-optimized form dialog
/// =============================================================================

class CreateClassDialog extends StatefulWidget {
  final ClassModel? classModel;
  final Future<void> Function(
    String name,
    String? gradeLevel,
    String? subject,
    String? room,
    String? color,
  ) onSubmit;

  const CreateClassDialog({
    super.key,
    this.classModel,
    required this.onSubmit,
  });

  @override
  State<CreateClassDialog> createState() => _CreateClassDialogState();
}

class _CreateClassDialogState extends State<CreateClassDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _gradeLevelController;
  late final TextEditingController _subjectController;
  late final TextEditingController _roomController;
  
  String? _selectedColor;
  bool _isLoading = false;

  // Predefined colors for classes
  static const _colorOptions = [
    '#3B82F6', // Blue
    '#10B981', // Green
    '#F59E0B', // Amber
    '#EF4444', // Red
    '#8B5CF6', // Purple
    '#EC4899', // Pink
    '#06B6D4', // Cyan
    '#84CC16', // Lime
    '#F97316', // Orange
    '#6366F1', // Indigo
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.classModel?.name);
    _gradeLevelController = TextEditingController(text: widget.classModel?.gradeLevel);
    _subjectController = TextEditingController(text: widget.classModel?.subject);
    _roomController = TextEditingController(text: widget.classModel?.room);
    _selectedColor = widget.classModel?.color ?? _colorOptions[0];
  }

  @override
  void dispose() {
    _nameController.dispose();
    _gradeLevelController.dispose();
    _subjectController.dispose();
    _roomController.dispose();
    super.dispose();
  }

  bool get isEditing => widget.classModel != null;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isTablet = context.isTablet;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
      ),
      child: Container(
        width: isTablet ? 500 : double.infinity,
        constraints: BoxConstraints(
          maxWidth: 500,
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header with color preview
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(isTablet ? 24 : 20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    _getColor(_selectedColor),
                    _getColor(_selectedColor).withOpacity(0.7),
                  ],
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
                        isEditing ? Icons.edit : Icons.add,
                        color: Colors.white,
                        size: isTablet ? 28 : 24,
                      ),
                      SizedBox(width: isTablet ? 16 : 12),
                      Expanded(
                        child: Text(
                          isEditing ? 'Edit Class' : 'Create New Class',
                          style: theme.textTheme.headlineSmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Form
            Flexible(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(isTablet ? 24 : 20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Class Name
                      TextFormField(
                        controller: _nameController,
                        style: TextStyle(fontSize: isTablet ? 18 : 16),
                        decoration: InputDecoration(
                          labelText: 'Class Name *',
                          hintText: 'e.g., 5th Grade Math',
                          labelStyle: TextStyle(fontSize: isTablet ? 18 : 16),
                          prefixIcon: Icon(Icons.class_, size: isTablet ? 24 : 22),
                        ),
                        textCapitalization: TextCapitalization.words,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter a class name';
                          }
                          return null;
                        },
                      ),
                      
                      SizedBox(height: isTablet ? 20 : 16),

                      // Grade Level & Subject (side by side on tablet)
                      if (isTablet)
                        Row(
                          children: [
                            Expanded(
                              child: _buildGradeField(isTablet),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildSubjectField(isTablet),
                            ),
                          ],
                        )
                      else ...[
                        _buildGradeField(isTablet),
                        SizedBox(height: isTablet ? 20 : 16),
                        _buildSubjectField(isTablet),
                      ],

                      SizedBox(height: isTablet ? 20 : 16),

                      // Room
                      TextFormField(
                        controller: _roomController,
                        style: TextStyle(fontSize: isTablet ? 18 : 16),
                        decoration: InputDecoration(
                          labelText: 'Room Number',
                          hintText: 'e.g., 101, Building A',
                          labelStyle: TextStyle(fontSize: isTablet ? 18 : 16),
                          prefixIcon: Icon(Icons.room, size: isTablet ? 24 : 22),
                        ),
                      ),

                      SizedBox(height: isTablet ? 24 : 20),

                      // Color picker
                      Text(
                        'Class Color',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                          fontSize: isTablet ? 18 : 16,
                        ),
                      ),
                      SizedBox(height: isTablet ? 12 : 8),
                      Wrap(
                        spacing: isTablet ? 12 : 8,
                        runSpacing: isTablet ? 12 : 8,
                        children: _colorOptions.map((color) {
                          final isSelected = _selectedColor == color;
                          return GestureDetector(
                            onTap: () => setState(() => _selectedColor = color),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              width: isTablet ? 44 : 36,
                              height: isTablet ? 44 : 36,
                              decoration: BoxDecoration(
                                color: _getColor(color),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isSelected ? theme.colorScheme.onSurface : Colors.transparent,
                                  width: 3,
                                ),
                                boxShadow: isSelected
                                    ? [
                                        BoxShadow(
                                          color: _getColor(color).withOpacity(0.4),
                                          blurRadius: 8,
                                          spreadRadius: 2,
                                        )
                                      ]
                                    : null,
                              ),
                              child: isSelected
                                  ? Icon(
                                      Icons.check,
                                      color: Colors.white,
                                      size: isTablet ? 24 : 20,
                                    )
                                  : null,
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Actions
            Container(
              padding: EdgeInsets.all(isTablet ? 24 : 20),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: theme.colorScheme.outlineVariant),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isLoading ? null : () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        minimumSize: Size(0, isTablet ? 52 : 48),
                      ),
                      child: Text(
                        'Cancel',
                        style: TextStyle(fontSize: isTablet ? 16 : 14),
                      ),
                    ),
                  ),
                  SizedBox(width: isTablet ? 16 : 12),
                  Expanded(
                    flex: 2,
                    child: FilledButton(
                      onPressed: _isLoading ? null : _handleSubmit,
                      style: FilledButton.styleFrom(
                        minimumSize: Size(0, isTablet ? 52 : 48),
                      ),
                      child: _isLoading
                          ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: theme.colorScheme.onPrimary,
                              ),
                            )
                          : Text(
                              isEditing ? 'Save Changes' : 'Create Class',
                              style: TextStyle(fontSize: isTablet ? 16 : 14),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGradeField(bool isTablet) {
    return TextFormField(
      controller: _gradeLevelController,
      style: TextStyle(fontSize: isTablet ? 18 : 16),
      decoration: InputDecoration(
        labelText: 'Grade Level',
        hintText: 'e.g., 5, K, 12',
        labelStyle: TextStyle(fontSize: isTablet ? 18 : 16),
        prefixIcon: Icon(Icons.school, size: isTablet ? 24 : 22),
      ),
    );
  }

  Widget _buildSubjectField(bool isTablet) {
    return TextFormField(
      controller: _subjectController,
      style: TextStyle(fontSize: isTablet ? 18 : 16),
      decoration: InputDecoration(
        labelText: 'Subject',
        hintText: 'e.g., Math, Science',
        labelStyle: TextStyle(fontSize: isTablet ? 18 : 16),
        prefixIcon: Icon(Icons.book, size: isTablet ? 24 : 22),
      ),
      textCapitalization: TextCapitalization.words,
    );
  }

  Color _getColor(String? hex) {
    if (hex == null) return AppTheme.primaryColor;
    try {
      return Color(int.parse(hex.replaceFirst('#', '0xFF')));
    } catch (e) {
      return AppTheme.primaryColor;
    }
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await widget.onSubmit(
        _nameController.text.trim(),
        _gradeLevelController.text.trim().isEmpty ? null : _gradeLevelController.text.trim(),
        _subjectController.text.trim().isEmpty ? null : _subjectController.text.trim(),
        _roomController.text.trim().isEmpty ? null : _roomController.text.trim(),
        _selectedColor,
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}
