import 'package:medlistapp/models/barcode_data.dart';
import 'package:medlistapp/models/medication.dart';
import 'package:medlistapp/services/medication_service.dart';
import 'package:medlistapp/services/database_service.dart';
import 'package:medlistapp/services/audit_service.dart';

class BarcodeScannerService {
  final MedicationService _medicationService = MedicationService();
  final DatabaseService _dbService = DatabaseService();
  final AuditService _auditService = AuditService();

  // Match barcode to medication
  Future<BarcodeMatchResult> matchBarcode(String barcode, String? format) async {
    // Step 1: Check if barcode was scanned before
    final previousScan = await _dbService.getBarcodeData(barcode);
    if (previousScan != null && previousScan.matched && previousScan.medicationId != null) {
      final medication = await _medicationService.getMedicationById(previousScan.medicationId!);
      if (medication != null) {
        await _auditService.logBarcodeScan(barcode, true);
        return BarcodeMatchResult(
          matched: true,
          medication: medication,
          barcode: barcode,
        );
      }
    }

    // Step 2: Try to match barcode with medication identifiers
    // In a real implementation, this would query a barcode database
    // For now, we'll search medications and try to match
    final allMedications = await _medicationService.getAllMedications();
    
    // Try matching by various identifiers
    Medication? matchedMedication;
    for (final medication in allMedications) {
      // In real implementation, medications would have barcode field
      // For now, we'll use a simple heuristic
      if (medication.tradeName.replaceAll(' ', '').toLowerCase() == barcode.toLowerCase()) {
        matchedMedication = medication;
        break;
      }
    }

    // Step 3: Store barcode scan result
    final barcodeData = BarcodeData(
      barcode: barcode,
      format: format,
      medicationId: matchedMedication?.id,
      medicationName: matchedMedication?.tradeName,
      matched: matchedMedication != null,
    );
    await _dbService.insertBarcodeData(barcodeData);

    // Step 4: Log audit
    await _auditService.logBarcodeScan(barcode, matchedMedication != null);

    if (matchedMedication != null) {
      return BarcodeMatchResult(
        matched: true,
        medication: matchedMedication,
        barcode: barcode,
      );
    } else {
      return BarcodeMatchResult(
        matched: false,
        barcode: barcode,
      );
    }
  }

  // Get barcode scan history
  Future<List<BarcodeData>> getScanHistory({int? limit}) async {
    final db = await _dbService.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'barcode_data',
      orderBy: 'scanned_at DESC',
      limit: limit,
    );
    return List.generate(maps.length, (i) => BarcodeData.fromMap(maps[i]));
  }
}

class BarcodeMatchResult {
  final bool matched;
  final Medication? medication;
  final String barcode;

  BarcodeMatchResult({
    required this.matched,
    this.medication,
    required this.barcode,
  });
}

