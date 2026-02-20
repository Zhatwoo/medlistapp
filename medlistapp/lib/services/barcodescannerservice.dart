import 'package:medlistapp/models/barcodedata.dart';
import 'package:medlistapp/models/medication.dart';
import 'package:medlistapp/services/gs1parserservice.dart';
import 'package:medlistapp/services/medicationservice.dart';
import 'package:medlistapp/services/databaseservice.dart';
import 'package:medlistapp/services/auditservice.dart';

class BarcodeScannerService {
  final MedicationService _medicationService = MedicationService();
  final DatabaseService _dbService = DatabaseService();
  final AuditService _auditService = AuditService();
  final GS1ParserService _gs1Parser = GS1ParserService();

  /// Parse a raw barcode string as GS1 DataMatrix.
  /// Returns null if the string is not valid GS1.
  GS1Data? parseGS1(String barcode) => _gs1Parser.parse(barcode);

  /// Match barcode to medication, with GS1 GTIN lookup as priority.
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
          gs1Data: _gs1Parser.parse(barcode),
        );
      }
    }

    // Step 2: Try GS1 parsing → GTIN lookup
    Medication? matchedMedication;
    final gs1 = _gs1Parser.parse(barcode);

    if (gs1 != null && gs1.gtin != null) {
      matchedMedication = await _dbService.getMedicationByGtin(gs1.gtin!);
    }

    // Step 3: Fallback - try matching by trade name heuristic
    if (matchedMedication == null) {
      final allMedications = await _medicationService.getAllMedications();
      for (final medication in allMedications) {
        if (medication.tradeName.replaceAll(' ', '').toLowerCase() ==
            barcode.toLowerCase()) {
          matchedMedication = medication;
          break;
        }
      }
    }

    // Step 4: Store barcode scan result
    final barcodeData = BarcodeData(
      barcode: barcode,
      format: format,
      medicationId: matchedMedication?.id,
      medicationName: matchedMedication?.tradeName,
      matched: matchedMedication != null,
    );
    await _dbService.insertBarcodeData(barcodeData);

    // Step 5: If matched by GS1 and medication has no GTIN stored yet, save it
    if (matchedMedication != null &&
        gs1 != null &&
        gs1.gtin != null &&
        matchedMedication.gtin == null) {
      await _dbService.updateMedicationGtin(matchedMedication.id!, gs1.gtin!);
    }

    // Step 6: Log audit
    await _auditService.logBarcodeScan(barcode, matchedMedication != null);

    return BarcodeMatchResult(
      matched: matchedMedication != null,
      medication: matchedMedication,
      barcode: barcode,
      gs1Data: gs1,
    );
  }

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
  final GS1Data? gs1Data;

  BarcodeMatchResult({
    required this.matched,
    this.medication,
    required this.barcode,
    this.gs1Data,
  });
}
