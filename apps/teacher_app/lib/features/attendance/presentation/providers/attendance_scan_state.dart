import 'package:equatable/equatable.dart';
import '../../data/models/attendance_record.dart';

/// State for attendance scanning
class AttendanceScanState extends Equatable {
  final bool isScanning;
  final bool isOnline;
  final List<AttendanceRecord> scannedStudents;
  final List<PendingConfirmation> pendingConfirmations;
  final int totalStudentsInClass;
  final int queuedRecords;
  final String? errorMessage;
  final DateTime? sessionStartTime;

  const AttendanceScanState({
    this.isScanning = false,
    this.isOnline = true,
    this.scannedStudents = const [],
    this.pendingConfirmations = const [],
    this.totalStudentsInClass = 0,
    this.queuedRecords = 0,
    this.errorMessage,
    this.sessionStartTime,
  });

  // Computed properties
  int get scannedCount => scannedStudents.length;
  double get progress => totalStudentsInClass > 0 
      ? scannedCount / totalStudentsInClass 
      : 0.0;

  AttendanceScanState copyWith({
    bool? isScanning,
    bool? isOnline,
    List<AttendanceRecord>? scannedStudents,
    List<PendingConfirmation>? pendingConfirmations,
    int? totalStudentsInClass,
    int? queuedRecords,
    String? errorMessage,
    DateTime? sessionStartTime,
  }) {
    return AttendanceScanState(
      isScanning: isScanning ?? this.isScanning,
      isOnline: isOnline ?? this.isOnline,
      scannedStudents: scannedStudents ?? this.scannedStudents,
      pendingConfirmations: pendingConfirmations ?? this.pendingConfirmations,
      totalStudentsInClass: totalStudentsInClass ?? this.totalStudentsInClass,
      queuedRecords: queuedRecords ?? this.queuedRecords,
      errorMessage: errorMessage,
      sessionStartTime: sessionStartTime ?? this.sessionStartTime,
    );
  }

  @override
  List<Object?> get props => [
        isScanning,
        isOnline,
        scannedStudents,
        pendingConfirmations,
        totalStudentsInClass,
        queuedRecords,
        errorMessage,
        sessionStartTime,
      ];
}

/// Represents a pending face detection that needs confirmation
class PendingConfirmation extends Equatable {
  final String detectionId;
  final String studentId;
  final String studentName;
  final double confidence;
  final DateTime detectedAt;

  const PendingConfirmation({
    required this.detectionId,
    required this.studentId,
    required this.studentName,
    required this.confidence,
    required this.detectedAt,
  });

  @override
  List<Object> get props => [detectionId, studentId, confidence, detectedAt];
}




