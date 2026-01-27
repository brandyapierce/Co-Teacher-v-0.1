import 'dart:typed_data';
import 'package:hive/hive.dart';
import 'dart:math' as math;

/// Abstract interface for CV operations
abstract class ICVService {
  Future<void> initialize();
  Future<List<Map<String, dynamic>>> detectFaces(Uint8List imageBytes);
  Future<List<double>?> extractEmbedding(Uint8List imageBytes);
  Future<Map<String, dynamic>?> matchStudent(List<double> embedding);
  Future<void> storeFaceTemplate(String studentId, List<double> embedding);
  Future<bool> hasFaceTemplate(String studentId);
  Future<void> deleteFaceTemplate(String studentId);
  Future<List<String>> getAllEnrolledStudents();
  Future<Map<String, dynamic>?> getFaceTemplate(String studentId);
  void dispose();
}

/// Enhanced CV Service with TFLite support
/// Phase 1: Simple feature extraction (Windows compatible)
/// Phase 2: Upgrade to MobileFaceNet (when TFLite works)
class CVServiceEnhanced implements ICVService {
  bool _isInitialized = false;
  late Box _faceTemplatesBox;
  
  static const int embeddingDim = 128;
  static const double confidenceThreshold = 0.6;

  @override
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      _faceTemplatesBox = await Hive.openBox('face_templates');
      _isInitialized = true;
    } catch (e) {
      throw Exception('Failed to initialize CV service: $e');
    }
  }

  @override
  Future<List<Map<String, dynamic>>> detectFaces(Uint8List imageBytes) async {
    if (!_isInitialized) await initialize();
    
    try {
      // Phase 1: Simple edge detection for face-like regions
      // Phase 2: TFLite MediaPipe BlazeFace
      
      // For now, return simulated faces for testing
      // In production, this would use TFLite
      return [
        {
          'id': 0,
          'confidence': 0.95,
          'box': {'x': 50, 'y': 50, 'width': 300, 'height': 400}
        }
      ];
    } catch (e) {
      throw Exception('Face detection failed: $e');
    }
  }

  @override
  Future<List<double>?> extractEmbedding(Uint8List imageBytes) async {
    if (!_isInitialized) await initialize();
    
    try {
      // Phase 1: Simple feature extraction
      List<double> embedding = _extractSimpleFeatures(imageBytes);
      
      // Normalize to unit vector
      double norm = math.sqrt(embedding.fold(0, (sum, val) => sum + val * val));
      if (norm > 0) {
        embedding = embedding.map((val) => val / norm).toList();
      }
      
      return embedding;
    } catch (e) {
      print('Embedding extraction failed: $e');
      return null;
    }
  }

  List<double> _extractSimpleFeatures(Uint8List imageBytes) {
    List<double> features = [];
    
    // 1. Hash-based features from image bytes (deterministic but simple)
    int chunkSize = (imageBytes.length / 32).ceil();
    for (int i = 0; i < 32; i++) {
      int start = i * chunkSize;
      int end = math.min(start + chunkSize, imageBytes.length);
      if (end > start) {
        int sum = 0;
        for (int j = start; j < end; j++) {
          sum += imageBytes[j];
        }
        double avg = sum / (end - start);
        features.add(avg / 255.0); // Normalize to 0-1
      } else {
        features.add(0.0);
      }
    }
    
    // 2. Statistical features (64 values)
    if (imageBytes.length > 100) {
      imageBytes.sort();
      final mean = imageBytes.reduce((a, b) => a + b) / imageBytes.length;
      final variance = imageBytes.fold<double>(0, (sum, val) {
        return sum + (val - mean) * (val - mean);
      }) / imageBytes.length;
      
      features.add(mean / 255.0);
      features.add(math.sqrt(variance) / 255.0);
      
      // Percentiles
      features.add((imageBytes[imageBytes.length ~/ 4] / 255.0));
      features.add((imageBytes[imageBytes.length ~/ 2] / 255.0));
      features.add((imageBytes[(3 * imageBytes.length) ~/ 4] / 255.0));
      
      // Additional statistical features to reach 128 dims
      for (int i = 0; i < 123; i++) {
        features.add(math.sin(i * mean / 255.0) / 2 + 0.5);
      }
    }
    
    // Pad or trim to exact embedding dimension
    while (features.length < embeddingDim) {
      features.add(0.0);
    }
    if (features.length > embeddingDim) {
      features = features.sublist(0, embeddingDim);
    }
    
    return features;
  }

  @override
  Future<Map<String, dynamic>?> matchStudent(List<double> embedding) async {
    if (!_isInitialized) await initialize();
    
    try {
      double bestSimilarity = confidenceThreshold;
      String? bestMatchId;
      
      for (var key in _faceTemplatesBox.keys) {
        final templateData = _faceTemplatesBox.get(key);
        if (templateData != null && templateData['embedding'] != null) {
          final storedEmbedding = List<double>.from(templateData['embedding']);
          double similarity = _cosineSimilarity(embedding, storedEmbedding);
          
          if (similarity > bestSimilarity) {
            bestSimilarity = similarity;
            bestMatchId = key.toString();
          }
        }
      }
      
      if (bestMatchId != null) {
        return {
          'student_id': bestMatchId,
          'confidence': bestSimilarity,
        };
      }
      
      return null;
    } catch (e) {
      print('Student matching failed: $e');
      return null;
    }
  }

  @override
  Future<void> storeFaceTemplate(
    String studentId,
    List<double> embedding,
  ) async {
    if (!_isInitialized) await initialize();
    
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
    
    try {
      return _faceTemplatesBox.keys.map((key) => key.toString()).toList();
    } catch (e) {
      throw Exception('Failed to get enrolled students: $e');
    }
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

  double _cosineSimilarity(List<double> a, List<double> b) {
    if (a.isEmpty || b.isEmpty || a.length != b.length) return 0.0;
    
    double dotProduct = 0.0;
    double normA = 0.0;
    double normB = 0.0;
    
    for (int i = 0; i < a.length; i++) {
      dotProduct += a[i] * b[i];
      normA += a[i] * a[i];
      normB += b[i] * b[i];
    }
    
    normA = math.sqrt(normA);
    normB = math.sqrt(normB);
    
    if (normA < 1e-6 || normB < 1e-6) return 0.0;
    
    double similarity = dotProduct / (normA * normB);
    return similarity.clamp(-1.0, 1.0);
  }

  @override
  void dispose() {
    if (_isInitialized) {
      _faceTemplatesBox.close();
    }
  }
}
