import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/responsive_utils.dart';
import '../../data/models/class_model.dart';

/// =============================================================================
/// CLASS CARD - Tablet-optimized class display card
/// =============================================================================

class ClassCard extends StatelessWidget {
  final ClassModel classModel;
  final bool isSelected;
  final bool isChecked;
  final bool isSelectionMode;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onTakeAttendance;

  const ClassCard({
    super.key,
    required this.classModel,
    this.isSelected = false,
    this.isChecked = false,
    this.isSelectionMode = false,
    required this.onTap,
    this.onLongPress,
    this.onEdit,
    this.onDelete,
    this.onTakeAttendance,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isTablet = context.isTablet;
    
    final classColor = _getClassColor(classModel.color);

    return Card(
      margin: EdgeInsets.symmetric(
        horizontal: isTablet ? 8 : 4,
        vertical: isTablet ? 6 : 4,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        side: isSelected
            ? BorderSide(color: colorScheme.primary, width: 2)
            : BorderSide.none,
      ),
      elevation: isSelected ? 4 : 1,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        child: Container(
          padding: EdgeInsets.all(isTablet ? 16 : 12),
          child: Row(
            children: [
              // Selection checkbox (when in selection mode)
              if (isSelectionMode) ...[
                Checkbox(
                  value: isChecked,
                  onChanged: (_) => onTap(),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                SizedBox(width: isTablet ? 12 : 8),
              ],
              
              // Color indicator / avatar
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
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: isTablet ? 6 : 4),
                    Text(
                      classModel.displaySubtitle,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        fontSize: isTablet ? 14 : 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              
              // Student count
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: isTablet ? 14 : 10,
                  vertical: isTablet ? 8 : 6,
                ),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.people,
                      size: isTablet ? 18 : 16,
                      color: colorScheme.onPrimaryContainer,
                    ),
                    SizedBox(width: isTablet ? 6 : 4),
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
              
              // Quick attendance button (when not in selection mode)
              if (!isSelectionMode && onTakeAttendance != null) ...[
                SizedBox(width: isTablet ? 8 : 4),
                IconButton(
                  onPressed: onTakeAttendance,
                  icon: Icon(
                    Icons.camera_alt,
                    size: isTablet ? 24 : 20,
                    color: colorScheme.primary,
                  ),
                  tooltip: 'Take Attendance',
                  style: IconButton.styleFrom(
                    backgroundColor: colorScheme.primaryContainer.withOpacity(0.3),
                  ),
                ),
              ],
              
              // More options menu (when not in selection mode)
              if (!isSelectionMode && (onEdit != null || onDelete != null)) ...[
                SizedBox(width: isTablet ? 4 : 2),
                PopupMenuButton<String>(
                  icon: Icon(
                    Icons.more_vert,
                    size: isTablet ? 24 : 20,
                  ),
                  itemBuilder: (context) => [
                    if (onTakeAttendance != null)
                      PopupMenuItem(
                        value: 'attendance',
                        child: Row(
                          children: [
                            Icon(Icons.camera_alt, size: isTablet ? 22 : 20, color: colorScheme.primary),
                            SizedBox(width: isTablet ? 12 : 8),
                            Text('Take Attendance', style: TextStyle(fontSize: isTablet ? 16 : 14)),
                          ],
                        ),
                      ),
                    if (onEdit != null)
                      PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit, size: isTablet ? 22 : 20),
                            SizedBox(width: isTablet ? 12 : 8),
                            Text('Edit', style: TextStyle(fontSize: isTablet ? 16 : 14)),
                          ],
                        ),
                      ),
                    if (onDelete != null)
                      PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, size: isTablet ? 22 : 20, color: Colors.red),
                            SizedBox(width: isTablet ? 12 : 8),
                            Text('Delete', style: TextStyle(fontSize: isTablet ? 16 : 14, color: Colors.red)),
                          ],
                        ),
                      ),
                  ],
                  onSelected: (value) {
                    if (value == 'attendance') onTakeAttendance?.call();
                    if (value == 'edit') onEdit?.call();
                    if (value == 'delete') onDelete?.call();
                  },
                ),
              ],
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
