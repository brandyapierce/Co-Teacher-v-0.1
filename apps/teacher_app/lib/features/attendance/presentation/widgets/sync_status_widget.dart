import 'package:flutter/material.dart';
import '../../../../shared/data/services/offline_queue_service.dart';

/// Widget displaying sync status with online/offline indicator and queue count
class SyncStatusWidget extends StatelessWidget {
  final OfflineQueueService queueService;
  final VoidCallback? onManualSync;

  const SyncStatusWidget({
    super.key,
    required this.queueService,
    this.onManualSync,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<bool>(
      stream: queueService.onlineStatusStream,
      initialData: queueService.isOnline,
      builder: (context, onlineSnapshot) {
        final isOnline = onlineSnapshot.data ?? false;

        return StreamBuilder<int>(
          stream: queueService.queueCountStream,
          initialData: 0,
          builder: (context, countSnapshot) {
            final pendingCount = countSnapshot.data ?? 0;

            return StreamBuilder<SyncProgress>(
              stream: queueService.syncProgressStream,
              builder: (context, syncSnapshot) {
                final syncProgress = syncSnapshot.data;
                final isSyncing = syncProgress?.status == SyncStatus.syncing;

                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Online/Offline Indicator
                    _buildStatusIndicator(isOnline, isSyncing),
                    const SizedBox(width: 8),

                    // Pending count badge (if any)
                    if (pendingCount > 0) ...[
                      Badge(
                        label: Text('$pendingCount'),
                        backgroundColor: isOnline ? Colors.orange : Colors.red,
                        child: Icon(
                          Icons.sync,
                          color: isSyncing ? Colors.blue : Colors.grey,
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],

                    // Manual sync button (only when online and not syncing)
                    if (isOnline && !isSyncing && pendingCount > 0)
                      IconButton(
                        icon: const Icon(Icons.sync, size: 20),
                        onPressed: onManualSync,
                        tooltip: 'Sync now',
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),

                    // Syncing indicator
                    if (isSyncing) ...[
                      const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      ),
                    ],
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildStatusIndicator(bool isOnline, bool isSyncing) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isOnline ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isOnline ? Colors.green : Colors.red,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isOnline ? Colors.green : Colors.red,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            isOnline ? 'Online' : 'Offline',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: isOnline ? Colors.green[800] : Colors.red[800],
            ),
          ),
        ],
      ),
    );
  }
}

/// Expanded sync status widget with more details
class SyncStatusPanel extends StatelessWidget {
  final OfflineQueueService queueService;
  final VoidCallback? onManualSync;

  const SyncStatusPanel({
    super.key,
    required this.queueService,
    this.onManualSync,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<bool>(
      stream: queueService.onlineStatusStream,
      initialData: queueService.isOnline,
      builder: (context, onlineSnapshot) {
        final isOnline = onlineSnapshot.data ?? false;

        return StreamBuilder<int>(
          stream: queueService.queueCountStream,
          initialData: 0,
          builder: (context, countSnapshot) {
            final pendingCount = countSnapshot.data ?? 0;

            return StreamBuilder<SyncProgress>(
              stream: queueService.syncProgressStream,
              builder: (context, syncSnapshot) {
                final syncProgress = syncSnapshot.data;

                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header Row
                      Row(
                        children: [
                          Icon(
                            isOnline ? Icons.cloud_done : Icons.cloud_off,
                            color: isOnline ? Colors.green : Colors.red,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            isOnline ? 'Connected' : 'Offline Mode',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          const Spacer(),
                          if (isOnline && pendingCount > 0 && 
                              syncProgress?.status != SyncStatus.syncing)
                            TextButton.icon(
                              onPressed: onManualSync,
                              icon: const Icon(Icons.sync, size: 18),
                              label: const Text('Sync Now'),
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Pending Items
                      if (pendingCount > 0) ...[
                        Row(
                          children: [
                            Icon(Icons.pending_actions, size: 20, color: Colors.orange),
                            const SizedBox(width: 8),
                            Text(
                              '$pendingCount item${pendingCount > 1 ? 's' : ''} waiting to sync',
                              style: TextStyle(color: Colors.grey[700]),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                      ],

                      // Sync Progress
                      if (syncProgress != null && 
                          syncProgress.status == SyncStatus.syncing) ...[
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Syncing ${syncProgress.synced} of ${syncProgress.total}...',
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            LinearProgressIndicator(
                              value: syncProgress.progress,
                              backgroundColor: Colors.grey[200],
                              valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
                            ),
                          ],
                        ),
                      ],

                      // Sync Complete/Error Status
                      if (syncProgress != null &&
                          syncProgress.status != SyncStatus.syncing &&
                          syncProgress.status != SyncStatus.idle) ...[
                        const SizedBox(height: 8),
                        _buildSyncResult(context, syncProgress),
                      ],

                      // Offline Message
                      if (!isOnline && pendingCount > 0) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.blue[50],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.info_outline, color: Colors.blue[700], size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Data will sync automatically when connection is restored',
                                  style: TextStyle(
                                    color: Colors.blue[900],
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildSyncResult(BuildContext context, SyncProgress progress) {
    if (progress.status == SyncStatus.completed && progress.failed == 0) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.green[50],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green[700], size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '${progress.synced} items synced successfully',
                style: TextStyle(
                  color: Colors.green[900],
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (progress.failed > 0) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.orange[50],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(Icons.warning, color: Colors.orange[700], size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '${progress.synced} synced, ${progress.failed} failed (will retry)',
                style: TextStyle(
                  color: Colors.orange[900],
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return const SizedBox.shrink();
  }
}

