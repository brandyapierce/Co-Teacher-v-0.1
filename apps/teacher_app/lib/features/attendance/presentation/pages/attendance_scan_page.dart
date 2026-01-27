import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/responsive_utils.dart';
import '../providers/attendance_scan_cubit.dart';
import '../providers/attendance_scan_state.dart';
import '../widgets/scan_results_panel.dart';
import '../widgets/confidence_confirmation_dialog.dart';
import '../widgets/manual_attendance_entry.dart';
import '../widgets/sync_status_widget.dart';
import '../../../../shared/data/services/offline_queue_service.dart';

/// =============================================================================
/// ATTENDANCE SCAN PAGE - TABLET OPTIMIZED
/// =============================================================================
/// 
/// LEARNING GUIDE: Tablet-Optimized Scanning UI
/// 
/// TABLET CONSIDERATIONS FOR SCANNING:
/// 1. Split view layout (camera + results side by side on tablet)
/// 2. Larger touch targets for confirmation buttons
/// 3. Better visibility of scanning status
/// 4. Easy to hold and use while walking around classroom
/// =============================================================================

class AttendanceScanPage extends StatelessWidget {
  final String teacherId;
  final String classId;
  final int totalStudents;
  final String? className;

  const AttendanceScanPage({
    super.key,
    required this.teacherId,
    required this.classId,
    this.totalStudents = 25,
    this.className,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => AttendanceScanCubit(
        teacherId: teacherId,
        classId: classId,
        queueService: OfflineQueueService(),
      )..startScanSession(totalStudents: totalStudents),
      child: _AttendanceScanView(className: className),
    );
  }
}

class _AttendanceScanView extends StatefulWidget {
  final String? className;
  
  const _AttendanceScanView({this.className});

  @override
  State<_AttendanceScanView> createState() => _AttendanceScanViewState();
}

class _AttendanceScanViewState extends State<_AttendanceScanView> {
  bool _isCameraActive = false;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) setState(() => _isCameraActive = true);
    });
    _startDemoDetections();
  }

  void _startDemoDetections() {
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
          Future.delayed(const Duration(seconds: 2), detectNext);
        }
      }
      detectNext();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isTablet = context.isTablet;
    final isLandscape = ResponsiveLayout.isLandscape(context);

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: isTablet ? 72 : 56,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Attendance Scan',
              style: TextStyle(fontSize: isTablet ? 24 : 20),
            ),
            if (widget.className != null)
              Text(
                widget.className!,
                style: TextStyle(
                  fontSize: isTablet ? 14 : 12,
                  fontWeight: FontWeight.normal,
                  color: colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
          ],
        ),
        actions: [
          Padding(
            padding: EdgeInsets.only(right: isTablet ? 24 : 16),
            child: SyncStatusWidget(
              queueService: context.read<AttendanceScanCubit>().queueService,
              onManualSync: () {
                context.read<AttendanceScanCubit>().queueService.manualSync();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Row(
                      children: [
                        Icon(Icons.sync, color: Colors.white),
                        SizedBox(width: 12),
                        Text('Syncing attendance records...'),
                      ],
                    ),
                    behavior: SnackBarBehavior.floating,
                    margin: EdgeInsets.all(isTablet ? 24 : 16),
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
                content: Row(
                  children: [
                    const Icon(Icons.error_outline, color: Colors.white),
                    const SizedBox(width: 12),
                    Expanded(child: Text(state.errorMessage!)),
                  ],
                ),
                backgroundColor: colorScheme.error,
                behavior: SnackBarBehavior.floating,
                margin: EdgeInsets.all(isTablet ? 24 : 16),
              ),
            );
          }
        },
        builder: (context, state) {
          // Tablet landscape: side-by-side layout
          if (isTablet && isLandscape) {
            return _buildTabletLandscapeLayout(context, state);
          }
          // Portrait or mobile: stacked layout
          return _buildStackedLayout(context, state, isTablet);
        },
      ),
      floatingActionButton: _buildCompleteFAB(context, isTablet),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  /// Tablet landscape: Camera and results side by side
  Widget _buildTabletLandscapeLayout(BuildContext context, AttendanceScanState state) {
    return Row(
      children: [
        // Camera preview (60% width)
        Expanded(
          flex: 6,
          child: _buildCameraPreview(context, state, isTablet: true),
        ),
        // Results panel (40% width)
        Expanded(
          flex: 4,
          child: _buildResultsPanel(context, state, isTablet: true),
        ),
      ],
    );
  }

  /// Portrait/mobile: Stacked layout
  Widget _buildStackedLayout(BuildContext context, AttendanceScanState state, bool isTablet) {
    return Column(
      children: [
        Expanded(
          flex: isTablet ? 5 : 3,
          child: _buildCameraPreview(context, state, isTablet: isTablet),
        ),
        _buildResultsPanel(context, state, isTablet: isTablet),
      ],
    );
  }

  Widget _buildCameraPreview(BuildContext context, AttendanceScanState state, {required bool isTablet}) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (!_isCameraActive) {
      return Container(
        color: Colors.black,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: isTablet ? 56 : 40,
                height: isTablet ? 56 : 40,
                child: const CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 3,
                ),
              ),
              SizedBox(height: isTablet ? 24 : 16),
              Text(
                'Initializing camera...',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: isTablet ? 18 : 14,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      color: Colors.black,
      child: Stack(
        children: [
          // Camera placeholder
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.videocam_rounded,
                  size: isTablet ? 100 : 80,
                  color: Colors.white.withOpacity(0.4),
                ),
                SizedBox(height: isTablet ? 24 : 16),
                Text(
                  'Camera View',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.6),
                    fontSize: isTablet ? 22 : 18,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: isTablet ? 12 : 8),
                Text(
                  'Point camera at students',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.4),
                    fontSize: isTablet ? 16 : 14,
                  ),
                ),
              ],
            ),
          ),
          
          // Scanning indicator (top)
          if (state.isScanning)
            Positioned(
              top: isTablet ? 24 : 16,
              left: isTablet ? 24 : 16,
              right: isTablet ? 24 : 16,
              child: _buildScanningIndicator(isTablet),
            ),
          
          // Progress indicator (bottom)
          Positioned(
            bottom: isTablet ? 24 : 16,
            left: isTablet ? 24 : 16,
            right: isTablet ? 24 : 16,
            child: _buildProgressBar(context, state, isTablet),
          ),
          
          // Confirmation dialog overlay
          if (state.pendingConfirmations.isNotEmpty)
            Positioned.fill(
              child: _buildConfirmationOverlay(context, state, isTablet),
            ),
        ],
      ),
    );
  }

  Widget _buildScanningIndicator(bool isTablet) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isTablet ? 20 : 16,
        vertical: isTablet ? 16 : 12,
      ),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.7),
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: isTablet ? 24 : 16,
            height: isTablet ? 24 : 16,
            child: const CircularProgressIndicator(
              strokeWidth: 2,
              color: Colors.white,
            ),
          ),
          SizedBox(width: isTablet ? 16 : 12),
          Text(
            'Scanning for faces...',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w500,
              fontSize: isTablet ? 18 : 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar(BuildContext context, AttendanceScanState state, bool isTablet) {
    final progress = state.totalStudentsInClass > 0
        ? state.scannedCount / state.totalStudentsInClass
        : 0.0;

    return Container(
      padding: EdgeInsets.all(isTablet ? 20 : 16),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.7),
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Progress',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: isTablet ? 16 : 14,
                ),
              ),
              Text(
                '${state.scannedCount} / ${state.totalStudentsInClass}',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: isTablet ? 20 : 16,
                ),
              ),
            ],
          ),
          SizedBox(height: isTablet ? 12 : 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: isTablet ? 10 : 6,
              backgroundColor: Colors.white24,
              valueColor: AlwaysStoppedAnimation<Color>(
                progress >= 1.0 ? AppTheme.successColor : Colors.blue,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConfirmationOverlay(BuildContext context, AttendanceScanState state, bool isTablet) {
    final pending = state.pendingConfirmations.first;
    
    return Container(
      color: Colors.black.withOpacity(0.6),
      child: Center(
        child: ConfidenceConfirmationDialog(
          studentId: pending.studentId,
          studentName: pending.studentName,
          confidence: pending.confidence,
          onConfirm: () {
            context.read<AttendanceScanCubit>().confirmDetection(pending.detectionId);
          },
          onReject: () {
            context.read<AttendanceScanCubit>().rejectDetection(pending.detectionId);
          },
        ),
      ),
    );
  }

  Widget _buildResultsPanel(BuildContext context, AttendanceScanState state, {required bool isTablet}) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
          top: ResponsiveLayout.isLandscape(context)
              ? BorderSide.none
              : BorderSide(color: colorScheme.outlineVariant),
          left: ResponsiveLayout.isLandscape(context)
              ? BorderSide(color: colorScheme.outlineVariant)
              : BorderSide.none,
        ),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: EdgeInsets.all(isTablet ? 20 : 16),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: colorScheme.outlineVariant),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.people,
                  size: isTablet ? 28 : 24,
                  color: colorScheme.primary,
                ),
                SizedBox(width: isTablet ? 16 : 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Scanned Students',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          fontSize: isTablet ? 20 : 16,
                        ),
                      ),
                      Text(
                        '${state.scannedCount} students marked present',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          fontSize: isTablet ? 14 : 12,
                        ),
                      ),
                    ],
                  ),
                ),
                // Manual entry button
                FilledButton.tonalIcon(
                  onPressed: () => _showManualEntryDialog(context),
                  icon: Icon(Icons.person_add, size: isTablet ? 24 : 20),
                  label: Text(
                    'Manual',
                    style: TextStyle(fontSize: isTablet ? 16 : 14),
                  ),
                  style: FilledButton.styleFrom(
                    minimumSize: Size(isTablet ? 120 : 100, isTablet ? 52 : 44),
                  ),
                ),
              ],
            ),
          ),
          
          // Student list
          Expanded(
            child: state.scannedStudents.isEmpty
                ? _buildEmptyResults(context, isTablet)
                : ListView.builder(
                    padding: EdgeInsets.symmetric(
                      vertical: isTablet ? 12 : 8,
                    ),
                    itemCount: state.scannedStudents.length,
                    itemBuilder: (context, index) {
                      final student = state.scannedStudents[index];
                      return _buildStudentTile(context, student, isTablet);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyResults(BuildContext context, bool isTablet) {
    final theme = Theme.of(context);
    
    return Center(
      child: Padding(
        padding: EdgeInsets.all(isTablet ? 32 : 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.person_search,
              size: isTablet ? 64 : 48,
              color: theme.colorScheme.onSurfaceVariant.withOpacity(0.5),
            ),
            SizedBox(height: isTablet ? 20 : 16),
            Text(
              'No students scanned yet',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontSize: isTablet ? 18 : 16,
              ),
            ),
            SizedBox(height: isTablet ? 12 : 8),
            Text(
              'Point the camera at your students\nor add them manually',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant.withOpacity(0.7),
                fontSize: isTablet ? 16 : 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStudentTile(BuildContext context, dynamic student, bool isTablet) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return ListTile(
      contentPadding: EdgeInsets.symmetric(
        horizontal: isTablet ? 20 : 16,
        vertical: isTablet ? 8 : 4,
      ),
      leading: CircleAvatar(
        radius: isTablet ? 24 : 20,
        backgroundColor: AppTheme.successColor.withOpacity(0.1),
        child: Icon(
          Icons.check,
          color: AppTheme.successColor,
          size: isTablet ? 28 : 24,
        ),
      ),
      title: Text(
        student.studentName,
        style: theme.textTheme.bodyLarge?.copyWith(
          fontWeight: FontWeight.w500,
          fontSize: isTablet ? 18 : 16,
        ),
      ),
      subtitle: Text(
        student.isManualEntry ? 'Manual entry' : 'Face detected',
        style: theme.textTheme.bodySmall?.copyWith(
          color: colorScheme.onSurfaceVariant,
          fontSize: isTablet ? 14 : 12,
        ),
      ),
      trailing: Container(
        padding: EdgeInsets.symmetric(
          horizontal: isTablet ? 12 : 8,
          vertical: isTablet ? 6 : 4,
        ),
        decoration: BoxDecoration(
          color: AppTheme.successColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          student.status.toUpperCase(),
          style: TextStyle(
            color: AppTheme.successColor,
            fontWeight: FontWeight.bold,
            fontSize: isTablet ? 12 : 10,
          ),
        ),
      ),
    );
  }

  Widget? _buildCompleteFAB(BuildContext context, bool isTablet) {
    return BlocBuilder<AttendanceScanCubit, AttendanceScanState>(
      builder: (context, state) {
        if (state.scannedCount >= state.totalStudentsInClass && 
            state.totalStudentsInClass > 0) {
          return SizedBox(
            height: isTablet ? 64 : 56,
            child: FloatingActionButton.extended(
              onPressed: () {
                context.read<AttendanceScanCubit>().endScanSession();
                Navigator.of(context).pop();
              },
              icon: Icon(Icons.check_circle, size: isTablet ? 28 : 24),
              label: Text(
                'Complete Attendance',
                style: TextStyle(
                  fontSize: isTablet ? 18 : 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              backgroundColor: AppTheme.successColor,
              foregroundColor: Colors.white,
            ),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }

  void _showManualEntryDialog(BuildContext context) {
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
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.white),
                  const SizedBox(width: 12),
                  Text('$studentName marked as $status'),
                ],
              ),
              backgroundColor: AppTheme.successColor,
              behavior: SnackBarBehavior.floating,
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
