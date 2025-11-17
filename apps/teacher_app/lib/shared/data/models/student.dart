import 'package:equatable/equatable.dart';

/// Student model representing a student in the system
/// 
/// EDUCATIONAL NOTE - Data Models:
/// ------------------------------
/// A model is a data class that represents an entity in your app.
/// Think of it like a "blueprint" or "template" for student data.
/// 
/// WHY USE MODELS?
/// 1. Type safety (compiler catches errors)
/// 2. Autocomplete in IDE (easier to write code)
/// 3. Consistent data structure across app
/// 4. Easy to serialize/deserialize (JSON ↔ Object)
/// 
/// EXAMPLE:
/// ```dart
/// // Without model (error-prone):
/// Map<String, dynamic> student = {
///   'name': 'John',
///   'age': 10,
/// };
/// print(student['nane']);  // Typo! No error until runtime ❌
/// 
/// // With model (type-safe):
/// Student student = Student(name: 'John', age: 10);
/// print(student.name);  // Autocomplete! Compiler checks spelling ✅
/// ```

class Student extends Equatable {
  /// Unique identifier for the student
  final String id;
  
  /// Student's first name
  final String firstName;
  
  /// Student's last name
  final String lastName;
  
  /// Student's email (optional)
  final String? email;
  
  /// Student's grade level (e.g., "3rd Grade", "PreK")
  final String? grade;
  
  /// Class/section the student belongs to
  final String? classId;
  
  /// Profile photo URL (optional)
  final String? photoUrl;
  
  /// Whether face enrollment is complete
  final bool isFaceEnrolled;
  
  /// Date when student was created in system
  final DateTime? createdAt;
  
  /// Date when student record was last updated
  final DateTime? updatedAt;

  const Student({
    required this.id,
    required this.firstName,
    required this.lastName,
    this.email,
    this.grade,
    this.classId,
    this.photoUrl,
    this.isFaceEnrolled = false,
    this.createdAt,
    this.updatedAt,
  });

  /// Convenience getter for full name
  /// 
  /// EDUCATIONAL NOTE - Getters:
  /// Getters are computed properties. They don't store data,
  /// they calculate it on-the-fly when accessed.
  /// 
  /// Example: student.fullName instead of concatenating manually
  String get fullName => '$firstName $lastName';

  /// Convenience getter for initials
  /// 
  /// Example: "John Doe" → "JD"
  String get initials {
    final firstInitial = firstName.isNotEmpty ? firstName[0] : '';
    final lastInitial = lastName.isNotEmpty ? lastName[0] : '';
    return '$firstInitial$lastInitial'.toUpperCase();
  }

  /// Create Student from JSON (API response)
  /// 
  /// EDUCATIONAL NOTE - fromJson:
  /// This is called "deserialization" - converting JSON to an object.
  /// 
  /// WHY NEEDED?
  /// APIs send data as JSON (text). We need to convert it to a Student object.
  /// 
  /// FLOW:
  /// API → JSON String → Map<String, dynamic> → Student Object
  /// 
  /// Example JSON from API:
  /// ```json
  /// {
  ///   "id": "123",
  ///   "first_name": "John",
  ///   "last_name": "Doe",
  ///   "email": "john@school.com"
  /// }
  /// ```
  factory Student.fromJson(Map<String, dynamic> json) {
    return Student(
      id: json['id'] as String,
      firstName: json['first_name'] as String,
      lastName: json['last_name'] as String,
      email: json['email'] as String?,
      grade: json['grade'] as String?,
      classId: json['class_id'] as String?,
      photoUrl: json['photo_url'] as String?,
      isFaceEnrolled: json['is_face_enrolled'] as bool? ?? false,
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  /// Convert Student to JSON (for API requests)
  /// 
  /// EDUCATIONAL NOTE - toJson:
  /// This is called "serialization" - converting an object to JSON.
  /// 
  /// WHY NEEDED?
  /// When we send data to the API, it needs to be in JSON format.
  /// 
  /// FLOW:
  /// Student Object → Map<String, dynamic> → JSON String → API
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'first_name': firstName,
      'last_name': lastName,
      'email': email,
      'grade': grade,
      'class_id': classId,
      'photo_url': photoUrl,
      'is_face_enrolled': isFaceEnrolled,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  /// Create a copy with some fields changed
  /// 
  /// EDUCATIONAL NOTE - copyWith:
  /// Remember, objects are immutable. To "change" them, we create a new one.
  /// 
  /// Example:
  /// ```dart
  /// final student = Student(id: '1', firstName: 'John', lastName: 'Doe');
  /// final enrolled = student.copyWith(isFaceEnrolled: true);
  /// // student is unchanged, enrolled is a new object with face enrolled
  /// ```
  Student copyWith({
    String? id,
    String? firstName,
    String? lastName,
    String? email,
    String? grade,
    String? classId,
    String? photoUrl,
    bool? isFaceEnrolled,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Student(
      id: id ?? this.id,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
      grade: grade ?? this.grade,
      classId: classId ?? this.classId,
      photoUrl: photoUrl ?? this.photoUrl,
      isFaceEnrolled: isFaceEnrolled ?? this.isFaceEnrolled,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Equatable comparison
  /// 
  /// This allows us to compare students easily:
  /// student1 == student2  // Compares all fields
  @override
  List<Object?> get props => [
        id,
        firstName,
        lastName,
        email,
        grade,
        classId,
        photoUrl,
        isFaceEnrolled,
        createdAt,
        updatedAt,
      ];

  /// String representation (for debugging)
  /// 
  /// Example: print(student) → "Student(John Doe, Grade: 3rd)"
  @override
  String toString() {
    return 'Student($fullName, Grade: ${grade ?? 'N/A'}, Enrolled: $isFaceEnrolled)';
  }
}

