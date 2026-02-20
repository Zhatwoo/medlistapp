import 'package:medlistapp/models/stockitem.dart';
import 'package:medlistapp/models/stockadjustment.dart';
import 'package:medlistapp/models/stockadjustmentreason.dart';
import 'package:medlistapp/services/databaseservice.dart';
import 'package:medlistapp/services/notificationservice.dart';
import 'package:medlistapp/services/medicationservice.dart';
import 'package:medlistapp/services/authservice.dart';
import 'package:medlistapp/utils/constants.dart';

class StockService {
  final DatabaseService _dbService = DatabaseService();
  final MedicationService _medicationService = MedicationService();
  final NotificationService _notificationService = NotificationService();
  final AuthService _authService = AuthService();

  // Get current user's company code
  Future<String?> _getCompanyCode() async {
    return await _authService.getCurrentUserCompanyCode();
  }

  // Add stock item
  Future<int> addStockItem(StockItem stockItem) async {
    // Ensure stock item has company code
    final companyCode = await _getCompanyCode();
    // Get company code from medication
    final medication = await _medicationService.getMedicationById(stockItem.medicationId);
    final medCompanyCode = medication?.companyCode ?? companyCode;
    final stockItemWithCode = stockItem.copyWith(companyCode: medCompanyCode);
    return await _dbService.insertStockItem(stockItemWithCode);
  }

  // Get all stock items
  Future<List<StockItem>> getAllStockItems() async {
    final companyCode = await _getCompanyCode();
    return await _dbService.getAllStockItems(companyCode: companyCode);
  }

  // Get stock items by medication ID
  Future<List<StockItem>> getStockItemsByMedicationId(int medicationId) async {
    final companyCode = await _getCompanyCode();
    return await _dbService.getStockItemsByMedicationId(medicationId, companyCode: companyCode);
  }

  // Get stock item by ID
  Future<StockItem?> getStockItemById(int id) async {
    return await _dbService.getStockItemById(id);
  }

  // Update stock item
  Future<int> updateStockItem(StockItem stockItem) async {
    final updated = stockItem.copyWith(updatedAt: DateTime.now());
    return await _dbService.updateStockItem(updated);
  }

  // Delete stock item
  Future<int> deleteStockItem(int id) async {
    return await _dbService.deleteStockItem(id);
  }

  // Get total stock quantity for a medication
  Future<int> getTotalStockQuantity(int medicationId) async {
    final companyCode = await _getCompanyCode();
    return await _dbService.getTotalStockQuantity(medicationId, companyCode: companyCode);
  }

  // Check if stock is low (below threshold)
  Future<bool> isStockLow(int medicationId, int threshold) async {
    final total = await getTotalStockQuantity(medicationId);
    return total < threshold;
  }

  /// Batch get stock summary for filtering: total qty, isLow, isOverstocked per medication.
  Future<Map<int, ({int total, bool isLowStock, bool isOverstocked})>> getStockSummaryForMedications(
    List<int> medicationIds, {
    int? lowStockThreshold,
    double? overstockThreshold,
  }) async {
    if (medicationIds.isEmpty) return {};
    final lowThresh = lowStockThreshold ?? AppConstants.defaultLowStockThreshold;
    final overThresh = overstockThreshold ?? AppConstants.defaultOverstockThreshold;

    final totals = await _dbService.getStockTotalsForMedicationIds(medicationIds);
    final stockItems = await _dbService.getStockItemsByMedicationIds(medicationIds);

    final overstockedIds = <int>{};
    for (final item in stockItems) {
      if (item.expectedQuantity != null && item.expectedQuantity! > 0) {
        final ratio = item.quantity / item.expectedQuantity!;
        if (ratio > overThresh) {
          overstockedIds.add(item.medicationId);
        }
      }
    }

    final result = <int, ({int total, bool isLowStock, bool isOverstocked})>{};
    for (final id in medicationIds) {
      final total = totals[id] ?? 0;
      result[id] = (
        total: total,
        isLowStock: total > 0 && total < lowThresh,
        isOverstocked: overstockedIds.contains(id),
      );
    }
    return result;
  }

  // Get low stock items
  Future<List<StockItem>> getLowStockItems(int threshold) async {
    final all = await getAllStockItems();
    final lowStockItems = <StockItem>[];
    
    for (final item in all) {
      final total = await getTotalStockQuantity(item.medicationId);
      if (total < threshold) {
        lowStockItems.add(item);
      }
    }
    
    return lowStockItems;
  }

  // Reconcile stock (update quantity) - deprecated, use adjustStock instead
  Future<int> reconcileStock(int stockItemId, int newQuantity, {StockAdjustmentReason? reason, String? notes}) async {
    if (reason != null) {
      return await adjustStock(stockItemId, newQuantity, reason, notes: notes);
    }
    final stockItem = await getStockItemById(stockItemId);
    if (stockItem == null) return 0;
    
    final updated = stockItem.copyWith(quantity: newQuantity);
    return await updateStockItem(updated);
  }

  // Adjust stock with reason and notes
  Future<int> adjustStock(int stockItemId, int newQuantity, StockAdjustmentReason reason, {String? notes}) async {
    final stockItem = await getStockItemById(stockItemId);
    if (stockItem == null) return 0;
    
    final oldQuantity = stockItem.quantity;
    
    // Update stock item
    final updated = stockItem.copyWith(quantity: newQuantity);
    final result = await updateStockItem(updated);
    
    // Record adjustment history
    final adjustment = StockAdjustment(
      stockItemId: stockItemId,
      oldQuantity: oldQuantity,
      newQuantity: newQuantity,
      reason: reason,
      notes: notes,
    );
    await _dbService.insertStockAdjustment(adjustment);
    
    return result;
  }

  // Get stock variance (actual - expected) for a medication
  Future<int?> getStockVariance(int medicationId) async {
    final stockItems = await getStockItemsByMedicationId(medicationId);
    if (stockItems.isEmpty) return null;
    
    int totalActual = 0;
    int? totalExpected;
    
    for (final item in stockItems) {
      totalActual += item.quantity;
      if (item.expectedQuantity != null) {
        totalExpected = (totalExpected ?? 0) + item.expectedQuantity!;
      }
    }
    
    if (totalExpected == null) return null;
    return totalActual - totalExpected;
  }

  // Check if medication is overstocked
  Future<bool> isOverstocked(int medicationId, {double? threshold}) async {
    final thresholdValue = threshold ?? AppConstants.defaultOverstockThreshold;
    final stockItems = await getStockItemsByMedicationId(medicationId);
    
    for (final item in stockItems) {
      if (item.expectedQuantity != null && item.expectedQuantity! > 0) {
        final ratio = item.quantity / item.expectedQuantity!;
        if (ratio > thresholdValue) {
          return true;
        }
      }
    }
    
    return false;
  }

  // Get overstocked items
  Future<List<StockItem>> getOverstockItems({double? threshold}) async {
    final thresholdValue = threshold ?? AppConstants.defaultOverstockThreshold;
    final allItems = await getAllStockItems();
    final overstockItems = <StockItem>[];
    
    for (final item in allItems) {
      if (item.expectedQuantity != null && item.expectedQuantity! > 0) {
        final ratio = item.quantity / item.expectedQuantity!;
        if (ratio > thresholdValue) {
          overstockItems.add(item);
        }
      }
    }
    
    return overstockItems;
  }

  // Get stock adjustment history for a stock item
  Future<List<StockAdjustment>> getStockAdjustmentHistory(int stockItemId) async {
    return await _dbService.getStockAdjustmentsByStockItemId(stockItemId);
  }

  // Add quantity to existing stock
  Future<int> addStockQuantity(int stockItemId, int quantityToAdd) async {
    final stockItem = await getStockItemById(stockItemId);
    if (stockItem == null) return 0;
    
    final newQuantity = stockItem.quantity + quantityToAdd;
    final updated = stockItem.copyWith(quantity: newQuantity);
    return await updateStockItem(updated);
  }

  // Subtract quantity from existing stock
  Future<int> subtractStockQuantity(int stockItemId, int quantityToSubtract) async {
    final stockItem = await getStockItemById(stockItemId);
    if (stockItem == null) return 0;
    
    final newQuantity = (stockItem.quantity - quantityToSubtract).clamp(0, double.infinity).toInt();
    final updated = stockItem.copyWith(quantity: newQuantity);
    return await updateStockItem(updated);
  }

  // Check and notify about low stock
  Future<void> checkAndNotifyLowStock() async {
    try {
      final threshold = AppConstants.defaultLowStockThreshold;
      final lowStockItems = await getLowStockItems(threshold);
      
      if (lowStockItems.isEmpty) return;

      // Get unique medications
      final medicationIds = lowStockItems.map((item) => item.medicationId).toSet();
      final lowStockMedications = <String>[];
      
      for (final medicationId in medicationIds) {
        final medication = await _medicationService.getMedicationById(medicationId);
        if (medication != null) {
          final items = lowStockItems.where((item) => item.medicationId == medicationId);
          final minQuantity = items.map((item) => item.quantity).reduce((a, b) => a < b ? a : b);
          lowStockMedications.add('${medication.tradeName} ($minQuantity left)');
        }
      }

      if (lowStockMedications.isEmpty) return;

      final count = lowStockMedications.length;
      await _notificationService.showLowStockAlert(
        title: '📦 Low Stock Alert',
        body: count == 1
            ? '${lowStockMedications.first} is running low'
            : '$count items are running low on stock (below $threshold)',
        data: {
          'type': 'lowStock',
          'count': count,
          'threshold': threshold,
        },
      );
    } catch (e) {
      // Log error but don't throw
      print('Error in checkAndNotifyLowStock: $e');
    }
  }
}

