import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../data/models/attendance_record.dart';

/// A card widget that displays a single attendance record
/// 
/// This is a "presentational widget" - it only displays data, doesn't manage state.
/// It receives data through parameters and calls callbacks when user interacts.
class AttendanceCard extends StatelessWidget {
  final AttendanceRecord record;
  final VoidCallback? onTap; // Called when card is tapped
  final VoidCallback? onEdit; // Called when edit button is tapped
  final VoidCallback? onDelete; // Called when delete button is tapped

  const AttendanceCard({
    super.key,
    required this.record,
    this.onTap,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    // Card provides elevation (shadow) and rounded corners
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      child: InkWell(
        // InkWell adds tap ripple effect
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Row: Student name and status badge
              Row(
                children: [
                  // Student avatar (circle with initials)
                  CircleAvatar(
                    backgroundColor: _getStatusColor().withOpacity(0.2),
                    child: Text(
                      _getInitials(record.studentName),
                      style: TextStyle(
                        color: _getStatusColor(),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  
                  // Student name
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          record.studentName,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 4),
                        // Timestamp (formatted nicely)
                        Text(
                          _formatTimestamp(record.timestamp),
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Colors.grey[600],
                              ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Status badge (Present/Absent/Tardy)
                  _buildStatusBadge(),
                ],
              ),

              // Divider line
              if (record.confidence != null || record.notes != null || !record.synced)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Divider(height: 1),
                ),

              // Details section (confidence, notes, sync status)
              if (record.confidence != null || record.notes != null || !record.synced)
                Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  children: [
                    // Confidence score (if auto-detected)
                    if (record.confidence != null && !record.isManual)
                      _buildInfoChip(
                        icon: Icons.verified,
                        label: '${(record.confidence! * 100).toStringAsFixed(0)}% confidence',
                        color: Colors.blue,
                      ),
                    
                    // Manual entry indicator
                    if (record.isManual)
                      _buildInfoChip(
                        icon: Icons.edit,
                        label: 'Manual entry',
                        color: Colors.orange,
                      ),
                    
                    // Sync status
                    if (!record.synced)
                      _buildInfoChip(
                        icon: Icons.cloud_off,
                        label: 'Not synced',
                        color: Colors.red,
                      ),
                    
                    // Notes indicator (shows if notes exist)
                    if (record.notes != null && record.notes!.isNotEmpty)
                      _buildInfoChip(
                        icon: Icons.note,
                        label: 'Has notes',
                        color: Colors.grey,
                      ),
                  ],
                ),

              // Notes text (if any)
              if (record.notes != null && record.notes!.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.note, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          record.notes!,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[800],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // Action buttons row (Edit & Delete)
              if (onEdit != null || onDelete != null) ...[
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (onEdit != null)
                      TextButton.icon(
                        onPressed: onEdit,
                        icon: const Icon(Icons.edit, size: 18),
                        label: const Text('Edit'),
                      ),
                    if (onDelete != null) ...[
                      const SizedBox(width: 8),
                      TextButton.icon(
                        onPressed: onDelete,
                        icon: const Icon(Icons.delete, size: 18),
                        label: const Text('Delete'),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.red,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// Build the status badge (Present/Absent/Tardy)
  Widget _buildStatusBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _getStatusColor(),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        record.status.toUpperCase(),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  /// Build small info chips (confidence, manual, etc.)
  Widget _buildInfoChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  /// Get color based on attendance status
  Color _getStatusColor() {
    switch (record.status.toLowerCase()) {
      case 'present':
        return Colors.green;
      case 'absent':
        return Colors.red;
      case 'tardy':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  /// Extract initials from student name
  String _getInitials(String name) {
    final parts = name.split(' ');
    if (parts.isEmpty) return '?';
    if (parts.length == 1) {
      return parts[0].substring(0, 1).toUpperCase();
    }
    return '${parts[0].substring(0, 1)}${parts[1].substring(0, 1)}'.toUpperCase();
  }

  /// Format timestamp to friendly string
  /// Examples: "Today at 2:30 PM", "Yesterday at 10:15 AM", "Jan 15 at 3:45 PM"
  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    // Today
    if (difference.inDays == 0) {
      return 'Today at ${DateFormat('h:mm a').format(timestamp)}';
    }
    
    // Yesterday
    if (difference.inDays == 1) {
      return 'Yesterday at ${DateFormat('h:mm a').format(timestamp)}';
    }
    
    // This week
    if (difference.inDays < 7) {
      return '${DateFormat('EEEE').format(timestamp)} at ${DateFormat('h:mm a').format(timestamp)}';
    }
    
    // Older
    return DateFormat('MMM d').format(timestamp) + ' at ' + DateFormat('h:mm a').format(timestamp);
  }
}

