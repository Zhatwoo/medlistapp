import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:medlistapp/models/syncstatus.dart';
import 'package:medlistapp/services/mimsservice.dart';
import 'package:medlistapp/services/mimscacheservice.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SyncService {
  final MimsService _mimsService = MimsService();
  final MimsCacheService _cacheService = MimsCacheService();
  final Connectivity _connectivity = Connectivity();

  // Check if device is online
  Future<bool> isOnline() async {
    final result = await _connectivity.checkConnectivity();
    return result != ConnectivityResult.none;
  }

  // Get sync status
  Future<SyncStatusData> getSyncStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final lastSyncStr = prefs.getString('last_sync_time');
    final nextSyncStr = prefs.getString('next_sync_time');
    final syncFrequency = prefs.getInt('sync_frequency_hours') ?? 24;

    DateTime? lastSyncTime;
    DateTime? nextSyncTime;

    if (lastSyncStr != null) {
      lastSyncTime = DateTime.parse(lastSyncStr);
      nextSyncTime = lastSyncTime.add(Duration(hours: syncFrequency));
    }

    return SyncStatusData(
      status: SyncStatus.idle,
      lastSyncTime: lastSyncTime,
      nextSyncTime: nextSyncTime,
    );
  }

  // Perform sync
  Future<SyncResult> sync() async {
    try {
      // Check if online
      final online = await isOnline();
      if (!online) {
        return SyncResult(
          success: false,
          errorMessage: 'No internet connection',
        );
      }

      // Check if offline mode is enabled
      final prefs = await SharedPreferences.getInstance();
      final offlineMode = prefs.getBool('offline_mode') ?? false;
      if (offlineMode) {
        return SyncResult(
          success: false,
          errorMessage: 'Offline mode is enabled',
        );
      }

      // Sync MIMS cache
      int itemsSynced = 0;
      try {
        // This would sync MIMS data in a real implementation
        // For now, we'll just update the cache expiry
        await _cacheService.clearExpiredCache(30);
        itemsSynced = 1;
      } catch (e) {
        // Continue even if MIMS sync fails
      }

      // Update sync time
      final now = DateTime.now();
      await prefs.setString('last_sync_time', now.toIso8601String());

      return SyncResult(
        success: true,
        itemsSynced: itemsSynced,
        totalItems: itemsSynced,
      );
    } catch (e) {
      return SyncResult(
        success: false,
        errorMessage: e.toString(),
      );
    }
  }

  // Set sync frequency
  Future<void> setSyncFrequency(int hours) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('sync_frequency_hours', hours);
  }

  // Enable/disable offline mode
  Future<void> setOfflineMode(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('offline_mode', enabled);
  }

  // Check if offline mode is enabled
  Future<bool> isOfflineMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('offline_mode') ?? false;
  }
}

class SyncResult {
  final bool success;
  final String? errorMessage;
  final int? itemsSynced;
  final int? totalItems;

  SyncResult({
    required this.success,
    this.errorMessage,
    this.itemsSynced,
    this.totalItems,
  });
}

