import 'package:medlistapp/models/stock_item.dart';
import 'package:medlistapp/services/database_service.dart';

class StockService {
  final DatabaseService _dbService = DatabaseService();

  // Add stock item
  Future<int> addStockItem(StockItem stockItem) async {
    return await _dbService.insertStockItem(stockItem);
  }

  // Get all stock items
  Future<List<StockItem>> getAllStockItems() async {
    return await _dbService.getAllStockItems();
  }

  // Get stock items by medication ID
  Future<List<StockItem>> getStockItemsByMedicationId(int medicationId) async {
    return await _dbService.getStockItemsByMedicationId(medicationId);
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
    return await _dbService.getTotalStockQuantity(medicationId);
  }

  // Check if stock is low (below threshold)
  Future<bool> isStockLow(int medicationId, int threshold) async {
    final total = await getTotalStockQuantity(medicationId);
    return total < threshold;
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

  // Reconcile stock (update quantity)
  Future<int> reconcileStock(int stockItemId, int newQuantity) async {
    final stockItem = await getStockItemById(stockItemId);
    if (stockItem == null) return 0;
    
    final updated = stockItem.copyWith(quantity: newQuantity);
    return await updateStockItem(updated);
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
}

