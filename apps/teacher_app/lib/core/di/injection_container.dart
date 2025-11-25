import 'package:get_it/get_it.dart';
import 'package:dio/dio.dart';
import 'package:hive/hive.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../config/app_config.dart';
import '../network/api_client.dart';
import '../services/auth_service.dart';
import '../services/token_storage_service.dart';
import '../../shared/data/services/cv_service.dart';
// TFLite version - use when TFLite is working on Windows
// import '../../shared/data/services/cv_service_enhanced.dart';
import '../../shared/data/services/cv_service_mock.dart';
import '../../shared/data/services/camera_service.dart';
import '../../shared/data/services/location_service.dart';
import '../../shared/data/services/offline_queue_service.dart';
import '../../features/students/data/repositories/student_repository.dart';
import '../../features/students/data/services/student_api_service.dart';
import '../../features/attendance/data/repositories/attendance_repository.dart';
import '../../features/attendance/data/services/attendance_api_service.dart';

final getIt = GetIt.instance;

Future<void> initializeDependencies() async {
  // External dependencies
  getIt.registerLazySingleton<Dio>(() {
    final dio = Dio();
    dio.options.baseUrl = AppConfig.apiBaseUrl;
    dio.options.connectTimeout = const Duration(seconds: 30);
    dio.options.receiveTimeout = const Duration(seconds: 30);
    return dio;
  });

  getIt.registerLazySingleton<WebSocketChannel>(() {
    return WebSocketChannel.connect(Uri.parse(AppConfig.wsUrl));
  });

  // Hive boxes - OPEN FIRST before registering
  final appSettingsBox = await Hive.openBox('app_settings');
  final offlineQueueBox = await Hive.openBox('offline_queue');
  final faceTemplatesBox = await Hive.openBox('face_templates');
  final attendanceRecordsBox = await Hive.openBox('attendance_records');
  final studentsBox = await Hive.openBox('students');
  
  getIt.registerLazySingleton<Box>(() => appSettingsBox, instanceName: 'app_settings');
  getIt.registerLazySingleton<Box>(() => offlineQueueBox, instanceName: 'offline_queue');
  getIt.registerLazySingleton<Box>(() => faceTemplatesBox, instanceName: 'face_templates');
  getIt.registerLazySingleton<Box>(() => attendanceRecordsBox, instanceName: 'attendance_records');
  getIt.registerLazySingleton<Box>(() => studentsBox, instanceName: 'students');

  // Network Services
  getIt.registerLazySingleton<ApiClient>(() => ApiClient());
  getIt.registerLazySingleton<TokenStorageService>(() => TokenStorageService());
  getIt.registerLazySingleton<AuthService>(() => AuthService(
        apiClient: getIt<ApiClient>(),
        tokenStorage: getIt<TokenStorageService>(),
      ));
  
  // API Services (Week 4 - Backend Integration)
  getIt.registerLazySingleton<StudentApiService>(() => StudentApiService(
        getIt<ApiClient>(),
      ));
  getIt.registerLazySingleton<AttendanceApiService>(() => AttendanceApiService(
        getIt<ApiClient>(),
      ));

  // Application Services
  getIt.registerLazySingleton<CVService>(() => CVService());
  getIt.registerLazySingleton<CVServiceMock>(() => CVServiceMock());
  getIt.registerLazySingleton<CameraService>(() => CameraService());
  getIt.registerLazySingleton<LocationService>(() => LocationService());
  getIt.registerLazySingleton<OfflineQueueService>(() => OfflineQueueService());
  
  // Repositories
  getIt.registerLazySingleton<StudentRepository>(() => StudentRepository());
  getIt.registerLazySingleton<AttendanceRepository>(() => AttendanceRepository());
}

