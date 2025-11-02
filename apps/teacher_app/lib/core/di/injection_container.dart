import 'package:get_it/get_it.dart';
import 'package:dio/dio.dart';
import 'package:hive/hive.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../config/app_config.dart';
import '../../shared/data/services/cv_service.dart';
import '../../shared/data/services/location_service.dart';
import '../../shared/data/services/offline_queue_service.dart';

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
  
  getIt.registerLazySingleton<Box>(() => appSettingsBox, instanceName: 'app_settings');
  getIt.registerLazySingleton<Box>(() => offlineQueueBox, instanceName: 'offline_queue');
  getIt.registerLazySingleton<Box>(() => faceTemplatesBox, instanceName: 'face_templates');

  // Services
  getIt.registerLazySingleton<CVService>(() => CVService());
  getIt.registerLazySingleton<LocationService>(() => LocationService());
  getIt.registerLazySingleton<OfflineQueueService>(() => OfflineQueueService());
}

