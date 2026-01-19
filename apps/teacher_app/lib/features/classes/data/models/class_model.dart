import 'package:hive/hive.dart';

part 'class_model.g.dart';

/// =============================================================================
/// CLASS MODEL - Data representation of a classroom/class
/// =============================================================================
/// 
/// LEARNING GUIDE: Data Models in Flutter
/// 
/// WHAT IS A MODEL?
/// A model is a Dart class that represents data in your app. It defines:
/// - What properties the data has (name, id, etc.)
/// - How to convert to/from JSON (for API communication)
/// - How to store locally (for offline support)
/// 
/// HIVE ANNOTATIONS:
/// @HiveType - Marks this class for local storage
/// @HiveField - Marks each property with a unique ID for storage
/// 
/// WHY UNIQUE FIELD IDS?
/// Hive uses these IDs to identify fields when reading/writing.
/// Once assigned, NEVER change them - it would corrupt existing data.
/// =============================================================================

@HiveType(typeId: 3) // TypeId must be unique across all Hive models
class ClassModel extends HiveObject {
  /// Unique identifier for the class
  @HiveField(0)
  final String id;

  /// Name of the class (e.g., "5th Grade Math", "Mrs. Johnson's Class")
  @HiveField(1)
  final String name;

  /// Grade level (e.g., "5", "K", "12")
  @HiveField(2)
  final String? gradeLevel;

  /// Subject taught (e.g., "Math", "Science", "All Subjects")
  @HiveField(3)
  final String? subject;

  /// Room number or location
  @HiveField(4)
  final String? room;

  /// Teacher ID who owns this class
  @HiveField(5)
  final String teacherId;

  /// Academic year (e.g., "2025-2026")
  @HiveField(6)
  final String? academicYear;

  /// List of student IDs enrolled in this class
  @HiveField(7)
  final List<String> studentIds;

  /// Schedule - which periods/times this class meets
  @HiveField(8)
  final List<ClassSchedule>? schedule;

  /// Color for UI display (hex string like "#FF5733")
  @HiveField(9)
  final String? color;

  /// When the class was created
  @HiveField(10)
  final DateTime createdAt;

  /// When the class was last updated
  @HiveField(11)
  final DateTime updatedAt;

  /// Whether this class is active
  @HiveField(12)
  final bool isActive;

  ClassModel({
    required this.id,
    required this.name,
    this.gradeLevel,
    this.subject,
    this.room,
    required this.teacherId,
    this.academicYear,
    List<String>? studentIds,
    this.schedule,
    this.color,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.isActive = true,
  })  : studentIds = studentIds ?? [],
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  /// Number of students in this class
  int get studentCount => studentIds.length;

  /// Display string for grade and subject
  String get displaySubtitle {
    final parts = <String>[];
    if (gradeLevel != null) parts.add('Grade $gradeLevel');
    if (subject != null) parts.add(subject!);
    if (room != null) parts.add('Room $room');
    return parts.isEmpty ? 'No details' : parts.join(' • ');
  }

  /// Create from JSON (API response)
  factory ClassModel.fromJson(Map<String, dynamic> json) {
    return ClassModel(
      id: json['id'] as String? ?? json['class_id'] as String,
      name: json['name'] as String? ?? json['class_name'] as String,
      gradeLevel: json['grade_level'] as String?,
      subject: json['subject'] as String?,
      room: json['room'] as String?,
      teacherId: json['teacher_id'] as String,
      academicYear: json['academic_year'] as String?,
      studentIds: (json['student_ids'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      schedule: (json['schedule'] as List<dynamic>?)
          ?.map((e) => ClassSchedule.fromJson(e as Map<String, dynamic>))
          .toList(),
      color: json['color'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
      isActive: json['is_active'] as bool? ?? true,
    );
  }

  /// Convert to JSON (for API requests)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'grade_level': gradeLevel,
      'subject': subject,
      'room': room,
      'teacher_id': teacherId,
      'academic_year': academicYear,
      'student_ids': studentIds,
      'schedule': schedule?.map((e) => e.toJson()).toList(),
      'color': color,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'is_active': isActive,
    };
  }

  /// Create a copy with modified fields
  ClassModel copyWith({
    String? id,
    String? name,
    String? gradeLevel,
    String? subject,
    String? room,
    String? teacherId,
    String? academicYear,
    List<String>? studentIds,
    List<ClassSchedule>? schedule,
    String? color,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isActive,
  }) {
    return ClassModel(
      id: id ?? this.id,
      name: name ?? this.name,
      gradeLevel: gradeLevel ?? this.gradeLevel,
      subject: subject ?? this.subject,
      room: room ?? this.room,
      teacherId: teacherId ?? this.teacherId,
      academicYear: academicYear ?? this.academicYear,
      studentIds: studentIds ?? this.studentIds,
      schedule: schedule ?? this.schedule,
      color: color ?? this.color,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      isActive: isActive ?? this.isActive,
    );
  }

  @override
  String toString() => 'ClassModel(id: $id, name: $name, students: $studentCount)';
}

/// =============================================================================
/// CLASS SCHEDULE - When a class meets
/// =============================================================================

@HiveType(typeId: 4)
class ClassSchedule extends HiveObject {
  /// Day of week (1=Monday, 7=Sunday)
  @HiveField(0)
  final int dayOfWeek;

  /// Start time (e.g., "08:30")
  @HiveField(1)
  final String startTime;

  /// End time (e.g., "09:30")
  @HiveField(2)
  final String endTime;

  /// Period number (optional, e.g., "1", "2A")
  @HiveField(3)
  final String? period;

  ClassSchedule({
    required this.dayOfWeek,
    required this.startTime,
    required this.endTime,
    this.period,
  });

  /// Get day name from day number
  String get dayName {
    const days = ['', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    return days[dayOfWeek.clamp(1, 7)];
  }

  /// Short day name (Mon, Tue, etc.)
  String get dayNameShort {
    const days = ['', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[dayOfWeek.clamp(1, 7)];
  }

  /// Display string (e.g., "Mon 8:30-9:30")
  String get displayTime => '$dayNameShort $startTime-$endTime';

  factory ClassSchedule.fromJson(Map<String, dynamic> json) {
    return ClassSchedule(
      dayOfWeek: json['day_of_week'] as int,
      startTime: json['start_time'] as String,
      endTime: json['end_time'] as String,
      period: json['period'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'day_of_week': dayOfWeek,
      'start_time': startTime,
      'end_time': endTime,
      'period': period,
    };
  }
}
