import 'package:flutter/material.dart';

/// Dialog for confirming detected students with varying confidence levels
class ConfidenceConfirmationDialog extends StatelessWidget {
  final String studentId;
  final String studentName;
  final double confidence;
  final VoidCallback onConfirm;
  final VoidCallback onReject;

  const ConfidenceConfirmationDialog({
    super.key,
    required this.studentId,
    required this.studentName,
    required this.confidence,
    required this.onConfirm,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    final confidenceLevel = _getConfidenceLevel(confidence);
    final confidenceColor = _getConfidenceColor(confidenceLevel);
    final confidenceText = _getConfidenceText(confidenceLevel);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Title
            Text(
              'Confirm Detection',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 24),

            // Student Avatar/Thumbnail Placeholder
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: confidenceColor.withOpacity(0.1),
                shape: BoxShape.circle,
                border: Border.all(
                  color: confidenceColor,
                  width: 3,
                ),
              ),
              child: Center(
                child: Text(
                  _getInitials(studentName),
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: confidenceColor,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Student Name
            Text(
              studentName,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),

            // Confidence Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: confidenceColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: confidenceColor,
                  width: 1.5,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _getConfidenceIcon(confidenceLevel),
                    color: confidenceColor,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    confidenceText,
                    style: TextStyle(
                      color: confidenceColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // Confidence Percentage
            Text(
              '${(confidence * 100).toStringAsFixed(0)}% Match',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
            const SizedBox(height: 24),

            // Confidence Level Description
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: confidenceColor.withOpacity(0.05),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _getConfidenceDescription(confidenceLevel),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[700],
                    ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 24),

            // Action Buttons
            Row(
              children: [
                // Reject Button
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onReject,
                    icon: const Icon(Icons.close),
                    label: const Text('Reject'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Confirm Button
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: onConfirm,
                    icon: const Icon(Icons.check),
                    label: const Text('Confirm'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: confidenceColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Get confidence level: high, medium, or low
  ConfidenceLevel _getConfidenceLevel(double confidence) {
    if (confidence >= 0.85) return ConfidenceLevel.high;
    if (confidence >= 0.70) return ConfidenceLevel.medium;
    return ConfidenceLevel.low;
  }

  /// Get color based on confidence level
  Color _getConfidenceColor(ConfidenceLevel level) {
    switch (level) {
      case ConfidenceLevel.high:
        return Colors.green;
      case ConfidenceLevel.medium:
        return Colors.orange;
      case ConfidenceLevel.low:
        return Colors.red;
    }
  }

  /// Get text label for confidence level
  String _getConfidenceText(ConfidenceLevel level) {
    switch (level) {
      case ConfidenceLevel.high:
        return 'High Confidence';
      case ConfidenceLevel.medium:
        return 'Medium Confidence';
      case ConfidenceLevel.low:
        return 'Low Confidence';
    }
  }

  /// Get icon for confidence level
  IconData _getConfidenceIcon(ConfidenceLevel level) {
    switch (level) {
      case ConfidenceLevel.high:
        return Icons.check_circle;
      case ConfidenceLevel.medium:
        return Icons.help;
      case ConfidenceLevel.low:
        return Icons.warning;
    }
  }

  /// Get description for confidence level
  String _getConfidenceDescription(ConfidenceLevel level) {
    switch (level) {
      case ConfidenceLevel.high:
        return 'This detection has a high match confidence. The system is very sure this is the correct student.';
      case ConfidenceLevel.medium:
        return 'This detection has medium confidence. Please verify this is the correct student before confirming.';
      case ConfidenceLevel.low:
        return 'This detection has low confidence. Please carefully verify before confirming or reject and try again.';
    }
  }

  /// Get initials from student name
  String _getInitials(String name) {
    final parts = name.split(' ');
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts[0].substring(0, 1).toUpperCase();
    return '${parts[0].substring(0, 1)}${parts[1].substring(0, 1)}'.toUpperCase();
  }
}

/// Confidence level enumeration
enum ConfidenceLevel {
  high, // ≥85%
  medium, // 70-84%
  low, // <70%
}

