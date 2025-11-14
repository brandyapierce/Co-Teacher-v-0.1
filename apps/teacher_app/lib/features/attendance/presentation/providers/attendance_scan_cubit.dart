import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:uuid/uuid.dart';
import '../../data/models/attendance_record.dart';
import 'attendance_scan_state.dart';
import '../../../../shared/data/services/offline_queue_service.dart';

class AttendanceScanCubit extends Cubit<AttendanceScanState> {
  final OfflineQueueService _queueService;
  StreamSubscription? _connectivitySubscription;
  StreamSubscription? _queueCountSubscription;
  Timer? _autoScanTimer;
  final String teacherId;
  final String classId;

  AttendanceScanCubit({
    required this.teacherId,
    required this.classId,
    required OfflineQueueService queueService,
  })  : _queueService = queueService,
        super(const AttendanceScanState());

  /// Initialize and start scanning session
  Future<void> startScanSession({required int totalStudents}) async {
    emit(state.copyWith(
      isScanning: true,
      sessionStartTime: DateTime.now(),
      totalStudentsInClass: totalStudents,
      scannedStudents: [],
      pendingConfirmations: [],
    ));

    // Listen to connectivity changes
    _connectivitySubscription = Connectivity()
        .onConnectivityChanged
        .listen((ConnectivityResult result) {
      emit(state.copyWith(isOnline: result != ConnectivityResult.none));
    });

    // Listen to queue count changes
    _queueCountSubscription = _queueService.queueCountStream.listen((count) {
      emit(state.copyWith(queuedRecords: count));
    });

    // Check initial connectivity
    final connectivityResult = await Connectivity().checkConnectivity();
    final initialQueueCount = await _queueService.getPendingCount();
    emit(state.copyWith(
      isOnline: connectivityResult != ConnectivityResult.none,
      queuedRecords: initialQueueCount,
    ));
  }
  
  /// Get reference to queue service for sync status widget
  OfflineQueueService get queueService => _queueService;

  /// Process a face detection result
  Future<void> processFaceDetection({
    required String studentId,
    required String studentName,
    required double confidence,
  }) async {
    // Check if student already scanned
    final alreadyScanned = state.scannedStudents
        .any((record) => record.studentId == studentId);
    
    if (alreadyScanned) {
      return; // Already marked present
    }

    // High confidence - auto-accept
    if (confidence >= 0.85) {
      await _addAttendanceRecord(
        studentId: studentId,
        studentName: studentName,
        confidence: confidence,
        isManual: false,
      );
    } else {
      // Low confidence - require confirmation
      _addPendingConfirmation(
        studentId: studentId,
        studentName: studentName,
        confidence: confidence,
      );
    }
  }

  /// Add a pending confirmation
  void _addPendingConfirmation({
    required String studentId,
    required String studentName,
    required double confidence,
  }) {
    final pending = PendingConfirmation(
      detectionId: const Uuid().v4(),
      studentId: studentId,
      studentName: studentName,
      confidence: confidence,
      detectedAt: DateTime.now(),
    );

    final updatedPending = [...state.pendingConfirmations, pending];
    emit(state.copyWith(pendingConfirmations: updatedPending));
  }

  /// Confirm a pending detection
  Future<void> confirmDetection(String detectionId) async {
    final pending = state.pendingConfirmations
        .firstWhere((p) => p.detectionId == detectionId);

    await _addAttendanceRecord(
      studentId: pending.studentId,
      studentName: pending.studentName,
      confidence: pending.confidence,
      isManual: false,
    );

    _removePendingConfirmation(detectionId);
  }

  /// Reject a pending detection
  void rejectDetection(String detectionId) {
    _removePendingConfirmation(detectionId);
  }

  void _removePendingConfirmation(String detectionId) {
    final updatedPending = state.pendingConfirmations
        .where((p) => p.detectionId != detectionId)
        .toList();
    emit(state.copyWith(pendingConfirmations: updatedPending));
  }

  /// Add manual attendance entry
  Future<void> addManualAttendance({
    required String studentId,
    required String studentName,
    String status = 'present',
    String? notes,
  }) async {
    await _addAttendanceRecord(
      studentId: studentId,
      studentName: studentName,
      isManual: true,
      status: status,
      notes: notes,
    );
  }

  /// Internal method to add attendance record
  Future<void> _addAttendanceRecord({
    required String studentId,
    required String studentName,
    double? confidence,
    bool isManual = false,
    String status = 'present',
    String? notes,
  }) async {
    final record = AttendanceRecord(
      id: const Uuid().v4(),
      studentId: studentId,
      studentName: studentName,
      teacherId: teacherId,
      classId: classId,
      timestamp: DateTime.now(),
      confidence: confidence,
      status: status,
      isManual: isManual,
      synced: false,
      notes: notes,
    );

    // Add to local list
    final updatedScanned = [...state.scannedStudents, record];
    emit(state.copyWith(scannedStudents: updatedScanned));

    // Queue for sync
    await _queueService.addToQueue(
      QueueItemType.attendance,
      record.toJson(),
    );

    // Queued records are automatically synced by the OfflineQueueService
    // when connectivity is available
  }

  /// End scanning session
  void endScanSession() {
    _autoScanTimer?.cancel();
    _connectivitySubscription?.cancel();
    _queueCountSubscription?.cancel();
    
    emit(state.copyWith(
      isScanning: false,
      sessionStartTime: null,
    ));
  }

  @override
  Future<void> close() {
    _autoScanTimer?.cancel();
    _connectivitySubscription?.cancel();
    _queueCountSubscription?.cancel();
    return super.close();
  }
}

