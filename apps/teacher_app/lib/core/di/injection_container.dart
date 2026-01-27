import 'package:get_it/get_it.dart';
import 'package:dio/dio.dart';
import 'package:hive/hive.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../config/app_config.dart';
import '../network/api_client.dart';
import '../services/auth_service.dart';
import '../services/token_storage_service.dart';
import '../../shared/data/services/cv_service.dart';
// Use mock service for Windows development
import '../../shared/data/services/cv_service_mock.dart';
// Uncomment below and comment above to use real TFLite service
// import '../../shared/data/services/cv_service_enhanced.dart';
import '../../shared/data/services/camera_service.dart';
import '../../shared/data/services/location_service.dart';
import '../../shared/data/services/offline_queue_service.dart';
import '../../features/students/data/repositories/student_repository.dart';
import '../../features/students/data/services/student_api_service.dart';
import '../../features/attendance/data/repositories/attendance_repository.dart';
import '../../features/attendance/data/services/attendance_api_service.dart';
import '../../features/classes/data/models/class_model.dart';
import '../../features/classes/data/services/class_api_service.dart';
import '../../features/classes/data/repositories/class_repository.dart';
import '../../features/reports/data/services/attendance_stats_service.dart';
import '../../features/reports/data/services/reports_api_service.dart';

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
  // Register Hive adapters for Class models
  if (!Hive.isAdapterRegistered(3)) {
    Hive.registerAdapter(ClassModelAdapter());
  }
  if (!Hive.isAdapterRegistered(4)) {
    Hive.registerAdapter(ClassScheduleAdapter());
  }
  
  final appSettingsBox = await Hive.openBox('app_settings');
  final offlineQueueBox = await Hive.openBox('offline_queue');
  final faceTemplatesBox = await Hive.openBox('face_templates');
  final attendanceRecordsBox = await Hive.openBox('attendance_records');
  final studentsBox = await Hive.openBox('students');
  final classesBox = await Hive.openBox<ClassModel>('classes');
  
  getIt.registerLazySingleton<Box>(() => appSettingsBox, instanceName: 'app_settings');
  getIt.registerLazySingleton<Box>(() => offlineQueueBox, instanceName: 'offline_queue');
  getIt.registerLazySingleton<Box>(() => faceTemplatesBox, instanceName: 'face_templates');
  getIt.registerLazySingleton<Box>(() => attendanceRecordsBox, instanceName: 'attendance_records');
  getIt.registerLazySingleton<Box>(() => studentsBox, instanceName: 'students');
  getIt.registerLazySingleton<Box<ClassModel>>(() => classesBox);

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
  getIt.registerLazySingleton<ClassApiService>(() => ClassApiService(
        getIt<ApiClient>(),
      ));
  getIt.registerLazySingleton<ReportsApiService>(() => ReportsApiService(
        getIt<ApiClient>(),
      ));

  // Application Services
  // Use mock for Windows development, switch to CVServiceEnhanced for mobile
  getIt.registerLazySingleton<ICVService>(() => CVServiceMock());
  // Uncomment below and comment above to use real TFLite service:
  // getIt.registerLazySingleton<ICVService>(() => CVServiceEnhanced());
  
  getIt.registerLazySingleton<CameraService>(() => CameraService());
  getIt.registerLazySingleton<LocationService>(() => LocationService());
  getIt.registerLazySingleton<OfflineQueueService>(() => OfflineQueueService());
  
  // Repositories
  getIt.registerLazySingleton<StudentRepository>(() => StudentRepository());
  getIt.registerLazySingleton<AttendanceRepository>(() => AttendanceRepository());
  getIt.registerLazySingleton<ClassRepository>(() => ClassRepository());
  
  // Statistics Services (Week 6 - Reports)
  getIt.registerLazySingleton<AttendanceStatsService>(
    () => AttendanceStatsService(
      reportsApiService: getIt<ReportsApiService>(),
    ),
  );
}

