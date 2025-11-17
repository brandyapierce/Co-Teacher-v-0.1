import 'dart:async';
import 'dart:math';
import 'package:hive/hive.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:get_it/get_it.dart';

import '../../../core/network/api_client.dart';

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

/// Service for managing offline data sync queue
/// 
/// EDUCATIONAL NOTE - Offline-First Architecture:
/// This service implements an "offline queue" pattern:
/// 1. All data changes are saved locally first (fast, always works)
/// 2. Changes are queued for sync to the backend
/// 3. When online, the queue automatically syncs to the server
/// 4. Failed syncs retry with exponential backoff
/// 
/// This gives users a seamless experience even with poor connectivity.
class OfflineQueueService {
  late Box _queueBox;
  late ApiClient _apiClient;
  Timer? _syncTimer;
  bool _isOnline = false;
  StreamSubscription? _connectivitySubscription;
  final StreamController<bool> _onlineStatusController = 
      StreamController<bool>.broadcast();
  final StreamController<int> _queueCountController = 
      StreamController<int>.broadcast();
  final StreamController<SyncProgress> _syncProgressController = 
      StreamController<SyncProgress>.broadcast();

  Stream<bool> get onlineStatusStream => _onlineStatusController.stream;
  Stream<int> get queueCountStream => _queueCountController.stream;
  Stream<SyncProgress> get syncProgressStream => _syncProgressController.stream;
  bool get isOnline => _isOnline;

  Future<void> initialize() async {
    _queueBox = await Hive.openBox('offline_queue');
    
    // Use the shared ApiClient for all API calls
    // This ensures JWT tokens are added automatically via interceptors
    _apiClient = GetIt.instance<ApiClient>();
    
    // Listen to connectivity changes
    _connectivitySubscription = Connectivity()
        .onConnectivityChanged
        .listen((ConnectivityResult result) {
      final wasOnline = _isOnline;
      _isOnline = result != ConnectivityResult.none;
      _onlineStatusController.add(_isOnline);
      
      // Trigger sync if we just came online
      if (!wasOnline && _isOnline) {
        _syncQueue();
      }
    });
    
    _startPeriodicSync();
    await _checkOnlineStatus();
    await _updateQueueCount();
  }

  void _startPeriodicSync() {
    _syncTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => _syncQueue(),
    );
  }

  /// Checks if device is online and API is reachable
  /// 
  /// Two-step check:
  /// 1. Network connectivity (wifi/cellular/none)
  /// 2. API health check (is backend server responding?)
  Future<void> _checkOnlineStatus() async {
    // First check network connectivity
    final connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult == ConnectivityResult.none) {
      _isOnline = false;
      _onlineStatusController.add(_isOnline);
      return;
    }
    
    // Then verify API is reachable
    try {
      final response = await _apiClient.healthCheck();
      _isOnline = response.statusCode == 200;
    } catch (e) {
      _isOnline = false;
    }
    
    _onlineStatusController.add(_isOnline);
  }
  
  Future<void> _updateQueueCount() async {
    final pendingItems = await _getPendingItems();
    _queueCountController.add(pendingItems.length);
  }

  Future<void> addToQueue(QueueItemType type, Map<String, dynamic> data) async {
    final item = QueueItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: type,
      data: data,
      createdAt: DateTime.now(),
    );
    
    await _queueBox.put(item.id, item.toJson());
    await _updateQueueCount();
    
    if (_isOnline) {
      await _syncQueue();
    }
  }
  
  /// Get count of pending items in queue
  Future<int> getPendingCount() async {
    final pendingItems = await _getPendingItems();
    return pendingItems.length;
  }
  
  /// Manually trigger sync
  Future<void> manualSync() async {
    await _syncQueue();
  }

  Future<void> _syncQueue() async {
    await _checkOnlineStatus();
    
    if (!_isOnline) return;
    
    final pendingItems = await _getPendingItems();
    
    if (pendingItems.isEmpty) return;
    
    _syncProgressController.add(SyncProgress(
      total: pendingItems.length,
      synced: 0,
      status: SyncStatus.syncing,
    ));
    
    int syncedCount = 0;
    int failedCount = 0;
    
    for (final item in pendingItems) {
      try {
        // Exponential backoff: wait longer for items with more retries
        if (item.retryCount > 0) {
          final delaySeconds = pow(2, item.retryCount).toInt();
          await Future.delayed(Duration(seconds: min(delaySeconds, 60)));
        }
        
        await _processQueueItem(item);
        await _markItemCompleted(item.id);
        syncedCount++;
        
        _syncProgressController.add(SyncProgress(
          total: pendingItems.length,
          synced: syncedCount,
          status: SyncStatus.syncing,
        ));
      } catch (e) {
        await _markItemFailed(item.id, e.toString());
        failedCount++;
      }
    }
    
    await _updateQueueCount();
    
    _syncProgressController.add(SyncProgress(
      total: pendingItems.length,
      synced: syncedCount,
      failed: failedCount,
      status: failedCount > 0 ? SyncStatus.error : SyncStatus.completed,
    ));
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

  /// Process a single queue item by sending it to the appropriate API endpoint
  /// 
  /// EDUCATIONAL NOTE - Type-based routing:
  /// Each queue item type goes to a different API endpoint.
  /// This allows us to queue different kinds of operations and sync them all.
  Future<void> _processQueueItem(QueueItem item) async {
    switch (item.type) {
      case QueueItemType.attendance:
        // Send attendance record to backend
        await _apiClient.createAttendance(item.data);
        break;
      case QueueItemType.rotation:
        // Update rotation status (for duty roster feature)
        await _apiClient.dio.put(
          '/api/v1/rotations/${item.data['id']}/status',
          data: item.data,
        );
        break;
      case QueueItemType.evidence:
        // Upload evidence document
        await _apiClient.dio.post('/api/v1/evidence/upload', data: item.data);
        break;
      case QueueItemType.location:
        // Location updates - can be skipped or sent to different endpoint
        // Not implemented yet
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
    _connectivitySubscription?.cancel();
    _onlineStatusController.close();
    _queueCountController.close();
    _syncProgressController.close();
    _queueBox.close();
  }
}

/// Sync progress data
class SyncProgress {
  final int total;
  final int synced;
  final int failed;
  final SyncStatus status;
  final DateTime timestamp;

  SyncProgress({
    required this.total,
    required this.synced,
    this.failed = 0,
    required this.status,
  }) : timestamp = DateTime.now();

  int get pending => total - synced - failed;
  double get progress => total > 0 ? synced / total : 0.0;
}

/// Sync status enumeration
enum SyncStatus {
  idle,
  syncing,
  completed,
  error,
}
