import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConfig {
  static String get apiBaseUrl => dotenv.env['API_BASE_URL'] ?? 'http://localhost:8000';
  static String get wsUrl => dotenv.env['WS_URL'] ?? 'ws://localhost:8000/ws';
  static String get appVersion => dotenv.env['APP_VERSION'] ?? '1.0.0';
  static bool get isDebug => dotenv.env['DEBUG'] == 'true';
  
  // CV Configuration
  static double get faceDetectionConfidence => double.tryParse(dotenv.env['FACE_DETECTION_CONFIDENCE'] ?? '0.7') ?? 0.7;
  static double get faceRecognitionThreshold => double.tryParse(dotenv.env['FACE_RECOGNITION_THRESHOLD'] ?? '0.6') ?? 0.6;
  static int get maxFaceTemplates => int.tryParse(dotenv.env['MAX_FACE_TEMPLATES'] ?? '5') ?? 5;
  
  // Location Configuration
  static double get geofenceRadius => double.tryParse(dotenv.env['GEOFENCE_RADIUS'] ?? '100.0') ?? 100.0;
  static int get locationUpdateInterval => int.tryParse(dotenv.env['LOCATION_UPDATE_INTERVAL'] ?? '30') ?? 30;
  
  // Attendance Configuration
  static int get attendanceScanTimeout => int.tryParse(dotenv.env['ATTENDANCE_SCAN_TIMEOUT'] ?? '120') ?? 120;
  static double get attendanceConfidenceThreshold => double.tryParse(dotenv.env['ATTENDANCE_CONFIDENCE_THRESHOLD'] ?? '0.8') ?? 0.8;
}

