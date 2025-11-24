import 'package:hive/hive.dart';

part 'attendance_record.g.dart';

@HiveType(typeId: 3)
class AttendanceRecord extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String studentId;

  @HiveField(2)
  String studentName;

  @HiveField(3)
  String teacherId;

  @HiveField(4)
  String classId;

  @HiveField(5)
  DateTime timestamp;

  @HiveField(6)
  double? confidence;

  @HiveField(7)
  String status; // 'present', 'absent', 'tardy'

  @HiveField(8)
  bool isManual; // true if manually entered, false if detected

  @HiveField(9)
  bool synced;

  @HiveField(10)
  String? notes;

  @HiveField(11)
  int retryCount;

  AttendanceRecord({
    required this.id,
    required this.studentId,
    required this.studentName,
    required this.teacherId,
    required this.classId,
    required this.timestamp,
    this.confidence,
    this.status = 'present',
    this.isManual = false,
    this.synced = false,
    this.notes,
    this.retryCount = 0,
  });

  // Convert to JSON for API
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'student_id': studentId,
      'teacher_id': teacherId,
      'class_id': classId,
      'timestamp': timestamp.toIso8601String(),
      'confidence': confidence,
      'status': status,
      'is_manual': isManual,
      'notes': notes,
    };
  }

  // Create from JSON
  factory AttendanceRecord.fromJson(Map<String, dynamic> json) {
    return AttendanceRecord(
      id: json['id'] as String,
      studentId: json['student_id'] as String,
      studentName: json['student_name'] ?? '',
      teacherId: json['teacher_id'] as String,
      classId: json['class_id'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      confidence: json['confidence'] as double?,
      status: json['status'] as String? ?? 'present',
      isManual: json['is_manual'] as bool? ?? false,
      synced: true, // From server means it's synced
      notes: json['notes'] as String?,
      retryCount: 0,
    );
  }

  // Copy with
  AttendanceRecord copyWith({
    String? id,
    String? studentId,
    String? studentName,
    String? teacherId,
    String? classId,
    DateTime? timestamp,
    double? confidence,
    String? status,
    bool? isManual,
    bool? synced,
    String? notes,
    int? retryCount,
  }) {
    return AttendanceRecord(
      id: id ?? this.id,
      studentId: studentId ?? this.studentId,
      studentName: studentName ?? this.studentName,
      teacherId: teacherId ?? this.teacherId,
      classId: classId ?? this.classId,
      timestamp: timestamp ?? this.timestamp,
      confidence: confidence ?? this.confidence,
      status: status ?? this.status,
      isManual: isManual ?? this.isManual,
      synced: synced ?? this.synced,
      notes: notes ?? this.notes,
      retryCount: retryCount ?? this.retryCount,
    );
  }
}




