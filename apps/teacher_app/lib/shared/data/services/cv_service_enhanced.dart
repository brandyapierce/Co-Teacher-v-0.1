import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import '../../utils/image_preprocessing.dart';

/// Enhanced CV Service with TFLite face detection and recognition
class CVServiceEnhanced {
  bool _isInitialized = false;
  late Box _faceTemplatesBox;
  
  // TFLite interpreters
  Interpreter? _faceDetectionInterpreter;
  Interpreter? _faceEmbeddingInterpreter;
  
  // Model paths
  static const String _faceDetectionModelPath = 'assets/models/face_detection_short_range.tflite';
  // Face landmarker for Phase 2
  // static const String _faceLandmarkerModelPath = 'assets/models/face_landmarker.task';
  
  // Detection thresholds
  static const double _detectionConfidenceThreshold = 0.7;
  static const double _matchingThreshold = 0.6;
  
  bool get isInitialized => _isInitialized;

  /// Initialize the CV service with models and storage
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Open Hive box for face templates
      _faceTemplatesBox = await Hive.openBox('face_templates');
      
      // Load TFLite models
      await _loadModels();
      
      _isInitialized = true;
      debugPrint('CVServiceEnhanced initialized successfully');
    } catch (e) {
      debugPrint('Error initializing CVServiceEnhanced: $e');
      rethrow;
    }
  }
  
  /// Load TFLite models
  Future<void> _loadModels() async {
    try {
      // Load face detection model
      _faceDetectionInterpreter = await Interpreter.fromAsset(
        _faceDetectionModelPath,
        options: InterpreterOptions()
          ..threads = 4
          ..useNnApiForAndroid = true,
      );
      
      debugPrint('Face detection model loaded');
      debugPrint('Input shape: ${_faceDetectionInterpreter!.getInputTensors()}');
      debugPrint('Output shape: ${_faceDetectionInterpreter!.getOutputTensors()}');
      
      // Note: Face embedding model (for Phase 2)
      // For now, we'll use a simplified approach with face landmarks
      // In Phase 2, we can add a dedicated embedding model (MobileFaceNet TFLite)
      
    } catch (e) {
      debugPrint('Error loading models: $e');
      rethrow;
    }
  }

  /// Detect faces in an image
  /// Returns list of face bounding boxes with confidence scores
  Future<List<DetectedFace>> detectFaces(Uint8List imageBytes) async {
    if (!_isInitialized) {
      await initialize();
    }

    if (_faceDetectionInterpreter == null) {
      throw Exception('Face detection model not loaded');
    }

    try {
      // Preprocess image for face detection (128x128, normalized)
      final input = await ImagePreprocessing.preprocessForFaceDetection(imageBytes);
      
      // Prepare output tensors
      // MediaPipe BlazeFace outputs:
      // - Bounding boxes: [1, N, 4] (x, y, width, height)
      // - Confidence scores: [1, N, 1]
      final outputBoxes = List.generate(1, 
        (_) => List.generate(896, // Number of anchors
          (_) => List.filled(4, 0.0),
        ),
      );
      
      final outputScores = List.generate(1,
        (_) => List.filled(896, 0.0),
      );
      
      // Run inference
      _faceDetectionInterpreter!.runForMultipleInputs(
        [input],
        {
          0: outputBoxes,
          1: outputScores,
        },
      );
      
      // Parse results and filter by confidence threshold
      final List<DetectedFace> detectedFaces = [];
      
      for (int i = 0; i < outputScores[0].length; i++) {
        final score = outputScores[0][i];
        
        if (score >= _detectionConfidenceThreshold) {
          final box = outputBoxes[0][i];
          
          // Convert from model coordinates to image coordinates
          final face = DetectedFace(
            boundingBox: Rect.fromLTWH(
              box[0] * 128, // x
              box[1] * 128, // y
              box[2] * 128, // width
              box[3] * 128, // height
            ),
            confidence: score,
          );
          
          detectedFaces.add(face);
        }
      }
      
      debugPrint('Detected ${detectedFaces.length} faces');
      return detectedFaces;
      
    } catch (e) {
      debugPrint('Error detecting faces: $e');
      return [];
    }
  }

  /// Extract face embedding from a detected face region
  /// For Phase 1: Returns a simple feature vector based on face region
  /// For Phase 2: Will use dedicated embedding model
  Future<List<double>> extractEmbedding(
    Uint8List imageBytes,
    Rect faceRect,
  ) async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      // For Phase 1: Generate a simple embedding based on face region
      // This is a placeholder that uses image statistics
      // In Phase 2, we'll replace this with MobileFaceNet TFLite model
      
      final preprocessed = await ImagePreprocessing.preprocessForEmbedding(
        imageBytes,
        faceRect,
      );
      
      // Create a simple 128D embedding from image statistics
      // This is just for PoC - Phase 2 will use proper face recognition model
      final embedding = _generateSimpleEmbedding(preprocessed);
      
      // L2 normalize the embedding
      return ImagePreprocessing.l2Normalize(embedding);
      
    } catch (e) {
      debugPrint('Error extracting embedding: $e');
      rethrow;
    }
  }
  
  /// Generate simple embedding (Phase 1 placeholder)
  List<double> _generateSimpleEmbedding(List<List<List<List<double>>>> image) {
    // For PoC, create a 128D vector from image statistics
    // This is NOT a proper face embedding but allows us to test the pipeline
    final embedding = List<double>.filled(128, 0.0);
    
    // Calculate simple statistics from different regions
    for (int i = 0; i < 128; i++) {
      int y = (i ~/ 16) * 14; // Sample 8x8 grid
      int x = (i % 16) * 7;
      
      if (y < 112 && x < 112) {
        double sum = 0.0;
        for (int c = 0; c < 3; c++) {
          sum += image[0][y][x][c];
        }
        embedding[i] = sum / 3.0;
      }
    }
    
    return embedding;
  }

  /// Match a face embedding against stored templates
  Future<FaceMatch?> matchStudent(List<double> embedding) async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      double bestSimilarity = 0.0;
      String? bestMatchId;
      
      // Compare against all stored templates
      for (var key in _faceTemplatesBox.keys) {
        final template = _faceTemplatesBox.get(key) as Map;
        final storedEmbedding = List<double>.from(template['embedding']);
        
        final similarity = ImagePreprocessing.cosineSimilarity(
          embedding,
          storedEmbedding,
        );
        
        if (similarity > bestSimilarity && similarity >= _matchingThreshold) {
          bestSimilarity = similarity;
          bestMatchId = key.toString();
        }
      }
      
      if (bestMatchId != null) {
        return FaceMatch(
          studentId: bestMatchId,
          confidence: bestSimilarity,
        );
      }
      
      return null;
      
    } catch (e) {
      debugPrint('Error matching student: $e');
      return null;
    }
  }

  /// Store encrypted face template for a student
  Future<void> storeFaceTemplate(
    String studentId,
    List<double> embedding, {
    int poseCount = 1,
  }) async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      // Encrypt the embedding
      final encryptedEmbedding = _encryptEmbedding(embedding, studentId);
      
      // Store in Hive
      await _faceTemplatesBox.put(studentId, {
        'student_id': studentId,
        'embedding': encryptedEmbedding,
        'pose_count': poseCount,
        'created_at': DateTime.now().toIso8601String(),
        'version': '1.0',
      });
      
      debugPrint('Stored face template for student: $studentId');
      
    } catch (e) {
      debugPrint('Error storing face template: $e');
      rethrow;
    }
  }
  
  /// Simple encryption for embeddings (AES-256 simulation with XOR)
  /// For production, use proper AES-256 encryption with flutter_secure_storage
  List<double> _encryptEmbedding(List<double> embedding, String key) {
    // Generate a simple key from student ID
    final keyBytes = utf8.encode(key);
    final keyHash = sha256.convert(keyBytes).bytes;
    
    // XOR encryption (placeholder - use proper AES in production)
    final encrypted = List<double>.from(embedding);
    for (int i = 0; i < encrypted.length; i++) {
      encrypted[i] = encrypted[i] + (keyHash[i % keyHash.length] / 255.0);
    }
    
    return encrypted;
  }

  /// Update face template with multiple poses (averaging)
  Future<void> updateFaceTemplate(
    String studentId,
    List<double> newEmbedding,
  ) async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      if (_faceTemplatesBox.containsKey(studentId)) {
        final existing = _faceTemplatesBox.get(studentId) as Map;
        final existingEmbedding = List<double>.from(existing['embedding']);
        final poseCount = existing['pose_count'] as int;
        
        // Average the embeddings
        final averaged = List<double>.generate(
          existingEmbedding.length,
          (i) => (existingEmbedding[i] * poseCount + newEmbedding[i]) / (poseCount + 1),
        );
        
        // Store updated template
        await storeFaceTemplate(
          studentId,
          averaged,
          poseCount: poseCount + 1,
        );
        
      } else {
        // First pose
        await storeFaceTemplate(studentId, newEmbedding, poseCount: 1);
      }
      
    } catch (e) {
      debugPrint('Error updating face template: $e');
      rethrow;
    }
  }

  /// Delete face template for a student
  Future<void> deleteFaceTemplate(String studentId) async {
    if (!_isInitialized) {
      await initialize();
    }
    
    await _faceTemplatesBox.delete(studentId);
  }

  /// Get all enrolled student IDs
  Future<List<String>> getEnrolledStudents() async {
    if (!_isInitialized) {
      await initialize();
    }
    
    return _faceTemplatesBox.keys.map((k) => k.toString()).toList();
  }

  /// Dispose resources
  Future<void> dispose() async {
    _faceDetectionInterpreter?.close();
    _faceEmbeddingInterpreter?.close();
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

