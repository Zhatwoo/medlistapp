enum SyncStatus {
  idle,
  syncing,
  success,
  error,
}

class SyncStatusData {
  final SyncStatus status;
  final DateTime? lastSyncTime;
  final DateTime? nextSyncTime;
  final String? errorMessage;
  final int? itemsSynced;
  final int? totalItems;

  SyncStatusData({
    required this.status,
    this.lastSyncTime,
    this.nextSyncTime,
    this.errorMessage,
    this.itemsSynced,
    this.totalItems,
  });

  Map<String, dynamic> toMap() {
    return {
      'status': status.name,
      'last_sync_time': lastSyncTime?.toIso8601String(),
      'next_sync_time': nextSyncTime?.toIso8601String(),
      'error_message': errorMessage,
      'items_synced': itemsSynced,
      'total_items': totalItems,
    };
  }

  factory SyncStatusData.fromMap(Map<String, dynamic> map) {
    return SyncStatusData(
      status: SyncStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => SyncStatus.idle,
      ),
      lastSyncTime: map['last_sync_time'] != null ? DateTime.parse(map['last_sync_time']) : null,
      nextSyncTime: map['next_sync_time'] != null ? DateTime.parse(map['next_sync_time']) : null,
      errorMessage: map['error_message'],
      itemsSynced: map['items_synced'],
      totalItems: map['total_items'],
    );
  }
}

