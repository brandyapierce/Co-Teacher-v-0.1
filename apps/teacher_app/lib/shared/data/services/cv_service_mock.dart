import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'dart:math' as math;

import 'cv_service.dart';

/// Mock CV Service for testing UI flow without TFLite
/// This allows the app to compile and test the enrollment flow
/// Replace with cv_service_enhanced.dart when TFLite is working
class CVServiceMock implements ICVService {
  bool _isInitialized = false;
  late Box _faceTemplatesBox;
  
  final _random = math.Random();
  
  static const int embeddingDim = 128;
  static const double confidenceThreshold = 0.6;

  bool get isInitialized => _isInitialized;

  @override
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      _faceTemplatesBox = await Hive.openBox('face_templates_mock');
      _isInitialized = true;
      debugPrint('CVServiceMock initialized successfully');
    } catch (e) {
      debugPrint('Error initializing CVServiceMock: $e');
      rethrow;
    }
  }

  /// Mock face detection - returns a random face
  @override
  Future<List<Map<String, dynamic>>> detectFaces(Uint8List imageBytes) async {
    if (!_isInitialized) {
      await initialize();
    }

    // Simulate processing delay
    await Future.delayed(const Duration(milliseconds: 300));
    
    // Return a mock detected face (80% success rate)
    if (_random.nextDouble() > 0.2) {
      return [
        {
          'id': 0,
          'confidence': 0.85 + _random.nextDouble() * 0.15,
          'box': {
            'x': 40,
            'y': 30,
            'width': 80,
            'height': 100,
          }
        },
      ];
    }
    
    return [];
  }

  /// Mock embedding extraction
  @override
  Future<List<double>?> extractEmbedding(Uint8List imageBytes) async {
    if (!_isInitialized) {
      await initialize();
    }

    // Simulate processing delay
    await Future.delayed(const Duration(milliseconds: 200));
    
    // Generate a random 128D embedding
    List<double> embedding = List.generate(
      embeddingDim,
      (_) => _random.nextDouble() * 2 - 1
    );
    
    // Normalize
    double norm = math.sqrt(
      embedding.fold(0, (sum, val) => sum + val * val)
    );
    if (norm > 0) {
      embedding = embedding.map((val) => val / norm).toList();
    }
    
    return embedding;
  }

  /// Mock face matching
  @override
  Future<Map<String, dynamic>?> matchStudent(List<double> embedding) async {
    if (!_isInitialized) {
      await initialize();
    }

    // Simulate processing delay
    await Future.delayed(const Duration(milliseconds: 100));
    
    // 70% chance of finding a match if students are enrolled
    if (_faceTemplatesBox.isNotEmpty && _random.nextDouble() > 0.3) {
      final keys = _faceTemplatesBox.keys.toList();
      final randomKey = keys[_random.nextInt(keys.length)];
      
      return {
        'student_id': randomKey.toString(),
        'confidence': 0.75 + _random.nextDouble() * 0.25,
      };
    }
    
    return null;
  }

  /// Store face template
  @override
  Future<void> storeFaceTemplate(
    String studentId,
    List<double> embedding,
  ) async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      final existing = _faceTemplatesBox.get(studentId);
      
      if (existing != null && existing['embedding'] != null) {
        // Average with existing for robustness
        final storedEmbedding = List<double>.from(existing['embedding']);
        final averaged = <double>[];
        
        for (int i = 0; i < embedding.length; i++) {
          averaged.add((embedding[i] + storedEmbedding[i]) / 2);
        }
        
        // Normalize
        double norm = math.sqrt(
          averaged.fold(0, (sum, val) => sum + val * val)
        );
        if (norm > 0) {
          for (int i = 0; i < averaged.length; i++) {
            averaged[i] = averaged[i] / norm;
          }
        }
        
        embedding = averaged;
      }
      
      await _faceTemplatesBox.put(studentId, {
        'student_id': studentId,
        'embedding': embedding,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
        'is_mock': true,
      });
    } catch (e) {
      throw Exception('Failed to store face template: $e');
    }
  }

  @override
  Future<bool> hasFaceTemplate(String studentId) async {
    if (!_isInitialized) await initialize();
    return _faceTemplatesBox.containsKey(studentId);
  }

  @override
  Future<void> deleteFaceTemplate(String studentId) async {
    if (!_isInitialized) await initialize();
    
    try {
      await _faceTemplatesBox.delete(studentId);
    } catch (e) {
      throw Exception('Failed to delete face template: $e');
    }
  }

  @override
  Future<List<String>> getAllEnrolledStudents() async {
    if (!_isInitialized) await initialize();
    return _faceTemplatesBox.keys.map((key) => key.toString()).toList();
  }

  @override
  Future<Map<String, dynamic>?> getFaceTemplate(String studentId) async {
    if (!_isInitialized) await initialize();
    
    try {
      final template = _faceTemplatesBox.get(studentId);
      return template != null ? Map<String, dynamic>.from(template) : null;
    } catch (e) {
      print('Failed to get face template: $e');
      return null;
    }
  }

  @override
  void dispose() {
    if (_isInitialized) {
      _faceTemplatesBox.close();
    }
  }
}

