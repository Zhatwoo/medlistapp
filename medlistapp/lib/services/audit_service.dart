import 'package:medlistapp/models/audit_log.dart';
import 'package:medlistapp/services/database_service.dart';

class AuditService {
  final DatabaseService _dbService = DatabaseService();

  // Log an action
  Future<void> logAction({
    required String actionType,
    required String entityType,
    int? entityId,
    String? userId,
    String? description,
    Map<String, dynamic>? metadata,
  }) async {
    final log = AuditLog(
      actionType: actionType,
      entityType: entityType,
      entityId: entityId,
      userId: userId,
      description: description,
      metadata: metadata,
    );

    await _dbService.insertAuditLog(log);
  }

  // Get audit logs with filters
  Future<List<AuditLog>> getAuditLogs({
    DateTime? startDate,
    DateTime? endDate,
    String? actionType,
  }) async {
    return await _dbService.getAuditLogs(
      startDate: startDate,
      endDate: endDate,
      actionType: actionType,
    );
  }

  // Convenience methods for common actions
  Future<void> logMedicationCreate(int medicationId, String medicationName) async {
    await logAction(
      actionType: 'create',
      entityType: 'medication',
      entityId: medicationId,
      description: 'Created medication: $medicationName',
    );
  }

  Future<void> logMedicationUpdate(int medicationId, String medicationName) async {
    await logAction(
      actionType: 'update',
      entityType: 'medication',
      entityId: medicationId,
      description: 'Updated medication: $medicationName',
    );
  }

  Future<void> logMedicationDelete(int medicationId, String medicationName) async {
    await logAction(
      actionType: 'delete',
      entityType: 'medication',
      entityId: medicationId,
      description: 'Deleted medication: $medicationName',
    );
  }

  Future<void> logStockAdjustment(int stockItemId, int oldQuantity, int newQuantity) async {
    await logAction(
      actionType: 'stock_adjust',
      entityType: 'stock_item',
      entityId: stockItemId,
      description: 'Stock adjusted from $oldQuantity to $newQuantity',
      metadata: {
        'old_quantity': oldQuantity,
        'new_quantity': newQuantity,
      },
    );
  }

  Future<void> logMimsAccess(String drugName, bool success) async {
    await logAction(
      actionType: 'mims_access',
      entityType: 'mims',
      description: 'MIMS access: $drugName (${success ? "success" : "failed"})',
      metadata: {
        'drug_name': drugName,
        'success': success,
      },
    );
  }

  Future<void> logBarcodeScan(String barcode, bool matched) async {
    await logAction(
      actionType: 'barcode_scan',
      entityType: 'barcode',
      description: 'Barcode scanned: $barcode (${matched ? "matched" : "not matched"})',
      metadata: {
        'barcode': barcode,
        'matched': matched,
      },
    );
  }
}

