import 'package:flutter/material.dart';
import '../../../../shared/data/models/student.dart';

/// Card widget to display a single student
/// 
/// EDUCATIONAL NOTE - Reusable Widgets:
/// Creating custom widgets makes your code:
/// - More organized (each widget has one job)
/// - Reusable (use StudentCard anywhere)
/// - Easier to test (test widget in isolation)
/// - Easier to modify (change once, updates everywhere)

class StudentCard extends StatelessWidget {
  final Student student;
  final int? index;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  const StudentCard({
    super.key,
    required this.student,
    this.index,
    this.onTap,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    // Add staggered animation
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 300 + ((index ?? 0) * 50)),
      curve: Curves.easeOut,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - value)),
          child: Opacity(
            opacity: value,
            child: child,
          ),
        );
      },
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Avatar with initials
                CircleAvatar(
                  radius: 28,
                  backgroundColor: _getColorForStudent(student.id),
                  child: Text(
                    student.initials,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ),
                const SizedBox(width: 16),

                // Student info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Name
                      Text(
                        student.fullName,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 4),

                      // Email or grade
                      if (student.email != null)
                        Text(
                          student.email!,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Colors.grey[600],
                              ),
                        )
                      else if (student.grade != null)
                        Text(
                          'Grade: ${student.grade}',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Colors.grey[600],
                              ),
                        ),

                      const SizedBox(height: 4),

                      // Face enrollment status
                      Row(
                        children: [
                          Icon(
                            student.isFaceEnrolled
                                ? Icons.check_circle
                                : Icons.pending_outlined,
                            size: 16,
                            color: student.isFaceEnrolled
                                ? Colors.green
                                : Colors.orange,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            student.isFaceEnrolled
                                ? 'Face enrolled'
                                : 'Face enrollment pending',
                            style: TextStyle(
                              fontSize: 12,
                              color: student.isFaceEnrolled
                                  ? Colors.green
                                  : Colors.orange,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Actions
                if (onDelete != null)
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    tooltip: 'Delete student',
                    onPressed: onDelete,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Generate consistent color for student based on ID
  /// 
  /// EDUCATIONAL NOTE - Color Generation:
  /// We use the student ID to generate a consistent color.
  /// Same student = same color every time.
  /// Different students = different colors.
  Color _getColorForStudent(String id) {
    // Use hashCode of ID to get a number
    final hash = id.hashCode;
    
    // Generate hue (0-360 degrees on color wheel)
    final hue = (hash % 360).toDouble();
    
    // Return color with that hue
    // Saturation: 0.7 (not too vibrant)
    // Value: 0.8 (not too dark)
    return HSVColor.fromAHSV(1.0, hue, 0.7, 0.8).toColor();
  }
}

