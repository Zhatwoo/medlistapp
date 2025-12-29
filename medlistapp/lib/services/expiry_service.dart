import 'package:medlistapp/models/stock_item.dart';
import 'package:medlistapp/models/expiry_record.dart';
import 'package:medlistapp/services/database_service.dart';
import 'package:medlistapp/utils/constants.dart';

class ExpiryService {
  final DatabaseService _dbService = DatabaseService();

  // Get expiring medications (within specified days)
  Future<List<StockItem>> getExpiringMedications([int days = 30]) async {
    final all = await _dbService.getAllStockItems();
    final now = DateTime.now();
    
    return all.where((item) {
      final daysUntilExpiry = item.expiryDate.difference(now).inDays;
      return daysUntilExpiry >= 0 && daysUntilExpiry <= days;
    }).toList();
  }

  // Get expired medications
  Future<List<StockItem>> getExpiredMedications() async {
    final all = await _dbService.getAllStockItems();
    final now = DateTime.now();
    
    return all.where((item) {
      return item.expiryDate.isBefore(now);
    }).toList();
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
    final now = DateTime.now();
    
    for (final item in allStockItems) {
      final daysUntilExpiry = item.expiryDate.difference(now).inDays;
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
    // Note: We would need an update method in DatabaseService for this
    // For now, we'll handle it in the next iteration
  }
}

