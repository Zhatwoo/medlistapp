import 'package:medlistapp/models/stockitem.dart';
import 'package:medlistapp/models/expiryrecord.dart';
import 'package:medlistapp/services/databaseservice.dart';
import 'package:medlistapp/services/notificationservice.dart';
import 'package:medlistapp/services/medicationservice.dart';
import 'package:medlistapp/services/stockservice.dart';
import 'package:medlistapp/utils/constants.dart';

class ExpiryService {
  final DatabaseService _dbService = DatabaseService();
  final NotificationService _notificationService = NotificationService();
  final MedicationService _medicationService = MedicationService();
  final StockService _stockService = StockService();

  // Get expiring medications (within specified days, not yet expired)
  Future<List<StockItem>> getExpiringMedications([int days = 30]) async {
    final all = await _stockService.getAllStockItems();
    return all.where((item) => item.daysUntilExpiry >= 0 && item.daysUntilExpiry <= days).toList();
  }

  // Get expired medications
  Future<List<StockItem>> getExpiredMedications() async {
    final all = await _stockService.getAllStockItems();
    return all.where((item) => item.isExpired).toList();
  }

  /// Returns items needing expiry attention: expired + expiring within [days].
  /// Fetches stock items once and filters in memory.
  Future<List<StockItem>> getExpiryAlerts([int days = 30]) async {
    final all = await _stockService.getAllStockItems();
    final expired = all.where((i) => i.isExpired).toList();
    final expiring = all.where((i) => i.daysUntilExpiry >= 0 && i.daysUntilExpiry <= days).toList();
    return [...expired, ...expiring];
  }

  // Get expiring medications within alert threshold
  Future<List<StockItem>> getExpiringMedicationsByThreshold([int? threshold]) async {
    final alertDays = threshold ?? AppConstants.defaultExpiryAlertDays;
    return await getExpiringMedications(alertDays);
  }

  // Create expiry record
  Future<int> createExpiryRecord(ExpiryRecord record) async {
    return await _dbService.insertExpiryRecord(record);
  }

  // Get expiry records for a stock item
  Future<List<ExpiryRecord>> getExpiryRecordsByStockItemId(int stockItemId) async {
    return await _dbService.getExpiryRecordsByStockItemId(stockItemId);
  }

  // Check and create expiry records for all stock items
  Future<void> checkAllExpiryRecords() async {
    final allStockItems = await _dbService.getAllStockItems();
    
    for (final item in allStockItems) {
      final daysUntilExpiry = item.daysUntilExpiry;
      final isExpired = daysUntilExpiry < 0;
      
      // Check if record already exists
      final existingRecords = await getExpiryRecordsByStockItemId(item.id!);
      final recentRecord = existingRecords.isNotEmpty 
          ? existingRecords.first 
          : null;
      
      // Only create new record if needed
      if (recentRecord == null || 
          recentRecord.daysUntilExpiry != daysUntilExpiry ||
          recentRecord.isExpired != isExpired) {
        final record = ExpiryRecord(
          stockItemId: item.id!,
          daysUntilExpiry: daysUntilExpiry,
          isExpired: isExpired,
        );
        await createExpiryRecord(record);
      }
    }
  }

  // Get medications expiring in next 7 days
  Future<List<StockItem>> getExpiringIn7Days() async {
    return await getExpiringMedications(7);
  }

  // Get medications expiring in next 30 days
  Future<List<StockItem>> getExpiringIn30Days() async {
    return await getExpiringMedications(30);
  }

  // Get medications expiring in next 90 days
  Future<List<StockItem>> getExpiringIn90Days() async {
    return await getExpiringMedications(90);
  }

  // Mark alert as sent
  Future<void> markAlertAsSent(int recordId) async {
    final records = await _dbService.getAllExpiryRecords();
    final record = records.firstWhere((r) => r.id == recordId);
    final updated = record.copyWith(
      alertSent: true,
      alertSentAt: DateTime.now(),
    );
    await _dbService.updateExpiryRecord(updated);
  }

  // Check and notify about expiring medications
  Future<void> checkAndNotifyExpiry() async {
    try {
      final alertDays = AppConstants.defaultExpiryAlertDays;
      final expiringItems = await getExpiringMedications(alertDays);
      
      if (expiringItems.isEmpty) return;

      // Get unique medications
      final medicationIds = expiringItems.map((item) => item.medicationId).toSet();
      final expiringMedications = <String>[];
      
      for (final medicationId in medicationIds) {
        final medication = await _medicationService.getMedicationById(medicationId);
        if (medication != null) {
          final items = expiringItems.where((item) => item.medicationId == medicationId);
          final totalQuantity = items.fold(0, (sum, item) => sum + item.quantity);
          expiringMedications.add('${medication.tradeName} ($totalQuantity units)');
        }
      }

      if (expiringMedications.isEmpty) return;

      final count = expiringMedications.length;
      await _notificationService.showExpiryAlert(
        title: '⚠️ Medications Expiring Soon',
        body: count == 1
            ? '${expiringMedications.first} is expiring within $alertDays days'
            : '$count medications are expiring within $alertDays days',
        data: {
          'type': 'expiry',
          'count': count,
          'alertDays': alertDays,
        },
      );
    } catch (e) {
      // Log error but don't throw
      print('Error in checkAndNotifyExpiry: $e');
    }
  }
}

