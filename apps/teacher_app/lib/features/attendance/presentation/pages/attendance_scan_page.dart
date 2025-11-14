import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../providers/attendance_scan_cubit.dart';
import '../providers/attendance_scan_state.dart';
import '../widgets/scan_results_panel.dart';
import '../widgets/confidence_confirmation_dialog.dart';
import '../widgets/manual_attendance_entry.dart';
import '../widgets/sync_status_widget.dart';
import '../../../../shared/data/services/offline_queue_service.dart';

class AttendanceScanPage extends StatelessWidget {
  final String teacherId;
  final String classId;
  final int totalStudents;

  const AttendanceScanPage({
    super.key,
    required this.teacherId,
    required this.classId,
    this.totalStudents = 25, // Default for demo
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => AttendanceScanCubit(
        teacherId: teacherId,
        classId: classId,
        queueService: OfflineQueueService(),
      )..startScanSession(totalStudents: totalStudents),
      child: const _AttendanceScanView(),
    );
  }
}

class _AttendanceScanView extends StatefulWidget {
  const _AttendanceScanView();

  @override
  State<_AttendanceScanView> createState() => _AttendanceScanViewState();
}

class _AttendanceScanViewState extends State<_AttendanceScanView> {
  bool _isCameraActive = false;

  @override
  void initState() {
    super.initState();
    // Simulate camera initialization
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        setState(() => _isCameraActive = true);
      }
    });

    // Simulate face detections for demo
    _startDemoDetections();
  }

  void _startDemoDetections() {
    // Demo: Simulate detecting students over time
    final demoStudents = [
      {'name': 'Emma Johnson', 'confidence': 0.95},
      {'name': 'Liam Williams', 'confidence': 0.92},
      {'name': 'Olivia Brown', 'confidence': 0.68},
      {'name': 'Noah Davis', 'confidence': 0.88},
      {'name': 'Ava Miller', 'confidence': 0.75},
    ];

    int index = 0;
    Future.delayed(const Duration(seconds: 3), () {
      if (!mounted) return;
      
      void detectNext() {
        if (index < demoStudents.length && mounted) {
          final student = demoStudents[index];
          context.read<AttendanceScanCubit>().processFaceDetection(
                studentId: 'student-${index + 1}',
                studentName: student['name'] as String,
                confidence: student['confidence'] as double,
              );
          index++;
          
          // Schedule next detection
          Future.delayed(const Duration(seconds: 2), detectNext);
        }
      }
      
      detectNext();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Attendance Scan'),
        actions: [
          // Sync status widget
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: SyncStatusWidget(
              queueService: context.read<AttendanceScanCubit>().queueService,
              onManualSync: () {
                context.read<AttendanceScanCubit>().queueService.manualSync();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Syncing...'),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      body: BlocConsumer<AttendanceScanCubit, AttendanceScanState>(
        listener: (context, state) {
          if (state.errorMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.errorMessage!),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        builder: (context, state) {
          return Column(
            children: [
              // Camera Preview Section
              Expanded(
                flex: 3,
                child: _buildCameraPreview(context, state),
              ),
              
              // Results Panel
              ScanResultsPanel(
                scannedStudents: state.scannedStudents,
                pendingConfirmations: state.pendingConfirmations,
                totalStudents: state.totalStudentsInClass,
                onManualEntry: () => _showManualEntryDialog(context),
              ),
            ],
          );
        },
      ),
      floatingActionButton: BlocBuilder<AttendanceScanCubit, AttendanceScanState>(
        builder: (context, state) {
          if (state.scannedCount >= state.totalStudentsInClass && 
              state.totalStudentsInClass > 0) {
            return FloatingActionButton.extended(
              onPressed: () {
                context.read<AttendanceScanCubit>().endScanSession();
                Navigator.of(context).pop();
              },
              icon: const Icon(Icons.check),
              label: const Text('Complete'),
              backgroundColor: Colors.green,
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildCameraPreview(BuildContext context, AttendanceScanState state) {
    if (!_isCameraActive) {
      return Container(
        color: Colors.black,
        child: const Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    }

    return Container(
      color: Colors.black,
      child: Stack(
        children: [
          // Camera preview placeholder
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.videocam,
                  size: 80,
                  color: Colors.white.withOpacity(0.5),
                ),
                const SizedBox(height: 16),
                Text(
                  'Camera View',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Point camera at students',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.5),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          
          // Face detection overlay
          if (state.isScanning)
            Positioned(
              top: 20,
              left: 20,
              right: 20,
              child: _buildScanningIndicator(),
            ),
          
          // Show confidence dialog for pending confirmations
          if (state.pendingConfirmations.isNotEmpty)
            Positioned.fill(
              child: _buildConfirmationDialogOverlay(context, state),
            ),
        ],
      ),
    );
  }

  Widget _buildScanningIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.7),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Colors.white,
            ),
          ),
          SizedBox(width: 12),
          Text(
            'Scanning for faces...',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConfirmationDialogOverlay(
    BuildContext context,
    AttendanceScanState state,
  ) {
    final pending = state.pendingConfirmations.first;
    
    // Semi-transparent overlay
    return Container(
      color: Colors.black.withOpacity(0.5),
      child: Center(
        child: ConfidenceConfirmationDialog(
          studentId: pending.studentId,
          studentName: pending.studentName,
          confidence: pending.confidence,
          onConfirm: () {
            context
                .read<AttendanceScanCubit>()
                .confirmDetection(pending.detectionId);
          },
          onReject: () {
            context
                .read<AttendanceScanCubit>()
                .rejectDetection(pending.detectionId);
          },
        ),
      ),
    );
  }

  void _showManualEntryDialog(BuildContext context) {
    // Demo student list - in real app, fetch from database
    final demoStudents = [
      const StudentInfo(id: 'student-1', name: 'Emma Johnson', grade: '5'),
      const StudentInfo(id: 'student-2', name: 'Liam Williams', grade: '5'),
      const StudentInfo(id: 'student-3', name: 'Olivia Brown', grade: '5'),
      const StudentInfo(id: 'student-4', name: 'Noah Davis', grade: '5'),
      const StudentInfo(id: 'student-5', name: 'Ava Miller', grade: '5'),
      const StudentInfo(id: 'student-6', name: 'Sophia Martinez', grade: '5'),
      const StudentInfo(id: 'student-7', name: 'Jackson Garcia', grade: '5'),
      const StudentInfo(id: 'student-8', name: 'Isabella Rodriguez', grade: '5'),
      const StudentInfo(id: 'student-9', name: 'Lucas Wilson', grade: '5'),
      const StudentInfo(id: 'student-10', name: 'Mia Anderson', grade: '5'),
    ];
    
    showDialog(
      context: context,
      builder: (dialogContext) => ManualAttendanceEntry(
        students: demoStudents,
        onSubmit: (studentId, studentName, status, notes) {
          context.read<AttendanceScanCubit>().addManualAttendance(
                studentId: studentId,
                studentName: studentName,
                status: status,
                notes: notes,
              );
          Navigator.pop(dialogContext);
          
          // Show success feedback
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('$studentName marked as $status'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );
        },
        onCancel: () => Navigator.pop(dialogContext),
      ),
    );
  }

  @override
  void dispose() {
    context.read<AttendanceScanCubit>().endScanSession();
    super.dispose();
  }
}

