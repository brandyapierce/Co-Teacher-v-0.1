import 'dart:async';
import 'package:hive/hive.dart';
import 'package:dio/dio.dart';

import '../../../core/config/app_config.dart';

enum QueueItemType {
  attendance,
  rotation,
  evidence,
  location,
}

enum QueueItemStatus {
  pending,
  processing,
  completed,
  failed,
}

class QueueItem {
  final String id;
  final QueueItemType type;
  final Map<String, dynamic> data;
  final DateTime createdAt;
  final int retryCount;
  final QueueItemStatus status;
  final String? error;

  QueueItem({
    required this.id,
    required this.type,
    required this.data,
    required this.createdAt,
    this.retryCount = 0,
    this.status = QueueItemStatus.pending,
    this.error,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'data': data,
      'created_at': createdAt.toIso8601String(),
      'retry_count': retryCount,
      'status': status.name,
      'error': error,
    };
  }

  factory QueueItem.fromJson(Map<String, dynamic> json) {
    return QueueItem(
      id: json['id'],
      type: QueueItemType.values.firstWhere((e) => e.name == json['type']),
      data: json['data'],
      createdAt: DateTime.parse(json['created_at']),
      retryCount: json['retry_count'] ?? 0,
      status: QueueItemStatus.values.firstWhere((e) => e.name == json['status']),
      error: json['error'],
    );
  }
}

class OfflineQueueService {
  late Box _queueBox;
  late Dio _dio;
  Timer? _syncTimer;
  bool _isOnline = false;
  final StreamController<bool> _onlineStatusController = 
      StreamController<bool>.broadcast();

  Stream<bool> get onlineStatusStream => _onlineStatusController.stream;
  bool get isOnline => _isOnline;

  Future<void> initialize() async {
    _queueBox = await Hive.openBox('offline_queue');
    
    _dio = Dio();
    _dio.options.baseUrl = AppConfig.apiBaseUrl;
    _dio.options.connectTimeout = const Duration(seconds: 30);
    _dio.options.receiveTimeout = const Duration(seconds: 30);
    
    _startPeriodicSync();
    await _checkOnlineStatus();
  }

  void _startPeriodicSync() {
    _syncTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => _syncQueue(),
    );
  }

  Future<void> _checkOnlineStatus() async {
    try {
      final response = await _dio.get('/health');
      _isOnline = response.statusCode == 200;
    } catch (e) {
      _isOnline = false;
    }
    
    _onlineStatusController.add(_isOnline);
  }

  Future<void> addToQueue(QueueItemType type, Map<String, dynamic> data) async {
    final item = QueueItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: type,
      data: data,
      createdAt: DateTime.now(),
    );
    
    await _queueBox.put(item.id, item.toJson());
    
    if (_isOnline) {
      await _syncQueue();
    }
  }

  Future<void> _syncQueue() async {
    await _checkOnlineStatus();
    
    if (!_isOnline) return;
    
    final pendingItems = await _getPendingItems();
    
    for (final item in pendingItems) {
      try {
        await _processQueueItem(item);
        await _markItemCompleted(item.id);
      } catch (e) {
        await _markItemFailed(item.id, e.toString());
      }
    }
  }

  Future<List<QueueItem>> _getPendingItems() async {
    final items = <QueueItem>[];
    
    for (final key in _queueBox.keys) {
      final itemData = _queueBox.get(key);
      if (itemData != null) {
        final item = QueueItem.fromJson(Map<String, dynamic>.from(itemData));
        if (item.status == QueueItemStatus.pending) {
          items.add(item);
        }
      }
    }
    
    return items;
  }

  Future<void> _processQueueItem(QueueItem item) async {
    switch (item.type) {
      case QueueItemType.attendance:
        await _dio.post('/api/v1/attendance/scan', data: item.data);
        break;
      case QueueItemType.rotation:
        await _dio.put('/api/v1/rotations/${item.data['id']}/status', data: item.data);
        break;
      case QueueItemType.evidence:
        await _dio.post('/api/v1/evidence/upload', data: item.data);
        break;
      case QueueItemType.location:
        // Location updates - can be skipped or sent to different endpoint
        break;
    }
  }

  Future<void> _markItemCompleted(String itemId) async {
    final itemData = _queueBox.get(itemId);
    if (itemData != null) {
      final item = QueueItem.fromJson(Map<String, dynamic>.from(itemData));
      final updatedItem = QueueItem(
        id: item.id,
        type: item.type,
        data: item.data,
        createdAt: item.createdAt,
        retryCount: item.retryCount,
        status: QueueItemStatus.completed,
      );
      
      await _queueBox.put(itemId, updatedItem.toJson());
    }
  }

  Future<void> _markItemFailed(String itemId, String error) async {
    final itemData = _queueBox.get(itemId);
    if (itemData != null) {
      final item = QueueItem.fromJson(Map<String, dynamic>.from(itemData));
      final updatedItem = QueueItem(
        id: item.id,
        type: item.type,
        data: item.data,
        createdAt: item.createdAt,
        retryCount: item.retryCount + 1,
        status: item.retryCount >= 3 
            ? QueueItemStatus.failed 
            : QueueItemStatus.pending,
        error: error,
      );
      
      await _queueBox.put(itemId, updatedItem.toJson());
    }
  }

  void dispose() {
    _syncTimer?.cancel();
    _onlineStatusController.close();
    _queueBox.close();
  }
}
