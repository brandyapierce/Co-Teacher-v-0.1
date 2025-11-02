import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'dart:math' as math;

/// Mock CV Service for testing UI flow without TFLite
/// This allows the app to compile and test the enrollment flow
/// Replace with cv_service_enhanced.dart when TFLite is working
class CVServiceMock {
  bool _isInitialized = false;
  late Box _faceTemplatesBox;
  
  final _random = math.Random();
  
  bool get isInitialized => _isInitialized;

  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      _faceTemplatesBox = await Hive.openBox('face_templates');
      _isInitialized = true;
      debugPrint('CVServiceMock initialized successfully');
    } catch (e) {
      debugPrint('Error initializing CVServiceMock: $e');
      rethrow;
    }
  }

  /// Mock face detection - returns a random face
  Future<List<DetectedFace>> detectFaces(Uint8List imageBytes) async {
    if (!_isInitialized) {
      await initialize();
    }

    // Simulate processing delay
    await Future.delayed(const Duration(milliseconds: 300));
    
    // Return a mock detected face (80% success rate)
    if (_random.nextDouble() > 0.2) {
      return [
        DetectedFace(
          boundingBox: Rect.fromLTWH(40, 30, 80, 100),
          confidence: 0.85 + _random.nextDouble() * 0.15,
        ),
      ];
    }
    
    return [];
  }

  /// Mock embedding extraction
  Future<List<double>> extractEmbedding(
    Uint8List imageBytes,
    Rect faceRect,
  ) async {
    if (!_isInitialized) {
      await initialize();
    }

    // Simulate processing delay
    await Future.delayed(const Duration(milliseconds: 200));
    
    // Generate a random 128D embedding
    return List.generate(128, (_) => _random.nextDouble() * 2 - 1);
  }

  /// Mock face matching
  Future<FaceMatch?> matchStudent(List<double> embedding) async {
    if (!_isInitialized) {
      await initialize();
    }

    // Simulate processing delay
    await Future.delayed(const Duration(milliseconds: 100));
    
    // 70% chance of finding a match if students are enrolled
    if (_faceTemplatesBox.isNotEmpty && _random.nextDouble() > 0.3) {
      final keys = _faceTemplatesBox.keys.toList();
      final randomKey = keys[_random.nextInt(keys.length)];
      
      return FaceMatch(
        studentId: randomKey.toString(),
        confidence: 0.75 + _random.nextDouble() * 0.25,
      );
    }
    
    return null;
  }

  /// Store face template
  Future<void> storeFaceTemplate(
    String studentId,
    List<double> embedding, {
    int poseCount = 1,
  }) async {
    if (!_isInitialized) {
      await initialize();
    }

    await _faceTemplatesBox.put(studentId, {
      'student_id': studentId,
      'embedding': embedding,
      'pose_count': poseCount,
      'created_at': DateTime.now().toIso8601String(),
      'version': '1.0-mock',
    });
    
    debugPrint('Stored mock face template for student: $studentId');
  }

  /// Update face template with multiple poses
  Future<void> updateFaceTemplate(
    String studentId,
    List<double> newEmbedding,
  ) async {
    if (!_isInitialized) {
      await initialize();
    }

    if (_faceTemplatesBox.containsKey(studentId)) {
      final existing = _faceTemplatesBox.get(studentId) as Map;
      final poseCount = existing['pose_count'] as int;
      
      await storeFaceTemplate(
        studentId,
        newEmbedding,
        poseCount: poseCount + 1,
      );
    } else {
      await storeFaceTemplate(studentId, newEmbedding, poseCount: 1);
    }
  }

  /// Delete face template
  Future<void> deleteFaceTemplate(String studentId) async {
    if (!_isInitialized) {
      await initialize();
    }
    
    await _faceTemplatesBox.delete(studentId);
  }

  /// Get enrolled students
  Future<List<String>> getEnrolledStudents() async {
    if (!_isInitialized) {
      await initialize();
    }
    
    return _faceTemplatesBox.keys.map((k) => k.toString()).toList();
  }

  /// Dispose resources
  Future<void> dispose() async {
    await _faceTemplatesBox.close();
    _isInitialized = false;
  }
}

/// Data class for detected face
class DetectedFace {
  final Rect boundingBox;
  final double confidence;
  
  DetectedFace({
    required this.boundingBox,
    required this.confidence,
  });
}

/// Data class for face match result
class FaceMatch {
  final String studentId;
  final double confidence;
  
  FaceMatch({
    required this.studentId,
    required this.confidence,
  });
}

