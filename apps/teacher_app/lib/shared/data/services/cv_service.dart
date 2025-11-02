import 'dart:typed_data';
import 'package:hive/hive.dart';

class CVService {
  bool _isInitialized = false;
  late Box _faceTemplatesBox;

  Future<void> initialize() async {
    if (_isInitialized) return;

    _faceTemplatesBox = await Hive.openBox('face_templates');
    _isInitialized = true;
  }

  Future<List<Map<String, dynamic>>> detectFaces(Uint8List imageBytes) async {
    if (!_isInitialized) {
      await initialize();
    }

    // Placeholder - MediaPipe integration coming in Week 2
    return [];
  }

  Future<String?> matchStudent(List<double> embedding) async {
    if (!_isInitialized) {
      await initialize();
    }

    // Placeholder - matching logic coming in Week 2
    return null;
  }

  Future<void> storeFaceTemplate(String studentId, List<double> embedding) async {
    if (!_isInitialized) {
      await initialize();
    }

    // Placeholder - storage logic coming in Week 2
    await _faceTemplatesBox.put(studentId, {
      'student_id': studentId,
      'embedding': embedding,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  void dispose() {
    _faceTemplatesBox.close();
  }
}
