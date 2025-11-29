import 'package:flutter/material.dart';
import '../../data/models/attendance_record.dart';
import '../providers/attendance_scan_state.dart';

class ScanResultsPanel extends StatelessWidget {
  final List<AttendanceRecord> scannedStudents;
  final List<PendingConfirmation> pendingConfirmations;
  final int totalStudents;
  final VoidCallback onManualEntry;

  const ScanResultsPanel({
    super.key,
    required this.scannedStudents,
    required this.pendingConfirmations,
    required this.totalStudents,
    required this.onManualEntry,
  });

  @override
  Widget build(BuildContext context) {
    final scannedCount = scannedStudents.length;
    final progress = totalStudents > 0 ? scannedCount / totalStudents : 0.0;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Progress Section
          _buildProgressSection(context, scannedCount, totalStudents, progress),
          
          const Divider(height: 1),
          
          // Recently Detected Section
          if (scannedStudents.isNotEmpty || pendingConfirmations.isNotEmpty)
            _buildRecentlyDetected(context),
          
          // Manual Entry Button
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onManualEntry,
                icon: const Icon(Icons.edit),
                label: const Text('Manual Entry'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressSection(
    BuildContext context,
    int scanned,
    int total,
    double progress,
  ) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Attendance Progress',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '$scanned / $total students',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[700],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: progress,
            minHeight: 8,
            backgroundColor: Colors.grey[200],
            valueColor: AlwaysStoppedAnimation<Color>(
              progress >= 0.8 ? Colors.green : Colors.blue,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentlyDetected(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxHeight: 200),
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: [
          const Text(
            'Recently Detected:',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          
          // Show last 5 scanned students
          ...scannedStudents.reversed.take(5).map((record) {
            return _buildStudentCard(
              name: record.studentName,
              confidence: record.confidence,
              isConfirmed: true,
            );
          }),
          
          // Show pending confirmations
          ...pendingConfirmations.map((pending) {
            return _buildPendingCard(
              name: pending.studentName,
              confidence: pending.confidence,
            );
          }),
        ],
      ),
    );
  }

  Widget _buildStudentCard({
    required String name,
    double? confidence,
    required bool isConfirmed,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.green,
          child: const Icon(Icons.check, color: Colors.white, size: 20),
        ),
        title: Text(
          name,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        trailing: confidence != null
            ? Text(
                '${(confidence * 100).toStringAsFixed(0)}%',
                style: TextStyle(
                  color: _getConfidenceColor(confidence),
                  fontWeight: FontWeight.bold,
                ),
              )
            : null,
      ),
    );
  }

  Widget _buildPendingCard({
    required String name,
    required double confidence,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: Colors.orange[50],
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.orange,
          child: const Icon(Icons.help_outline, color: Colors.white, size: 20),
        ),
        title: Text(
          name,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: const Text('Tap to confirm'),
        trailing: Text(
          '${(confidence * 100).toStringAsFixed(0)}%',
          style: TextStyle(
            color: _getConfidenceColor(confidence),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Color _getConfidenceColor(double confidence) {
    if (confidence >= 0.85) return Colors.green;
    if (confidence >= 0.70) return Colors.orange;
    return Colors.red;
  }
}





