import 'package:medlistapp/models/medication.dart';
import 'package:medlistapp/models/verificationresult.dart';
import 'package:medlistapp/models/verificationhistory.dart';
import 'package:medlistapp/models/mimsdrugdata.dart';
import 'package:medlistapp/services/medicationservice.dart';
import 'package:medlistapp/services/mimsservice.dart';
import 'package:medlistapp/services/interactionservice.dart';
import 'package:medlistapp/services/databaseservice.dart';
import 'package:medlistapp/services/auditservice.dart';
import 'package:medlistapp/services/barcodescannerservice.dart';

class VerificationService {
  final MedicationService _medicationService = MedicationService();
  final MimsService _mimsService = MimsService();
  final InteractionService _interactionService = InteractionService();
  final DatabaseService _dbService = DatabaseService();
  final AuditService _auditService = AuditService();

  // Verify medication by trade name, generic name, or barcode
  Future<VerificationResult> verifyMedication({
    String? tradeName,
    String? genericName,
    String? barcode,
    List<String>? currentMedications, // For interaction checking
  }) async {
    Medication? medication;
    MimsDrugData? mimsData;
    List<String> contraindications = [];
    List<String> warnings = [];
    List<String> interactions = [];
    bool identityVerified = false;

    // Step 1: Identity verification against MOH database
    if (tradeName != null && tradeName.isNotEmpty) {
      final results = await _medicationService.searchMedications(tradeName);
      if (results.isNotEmpty) {
        medication = results.first;
        identityVerified = true;
      }
    } else if (barcode != null && barcode.isNotEmpty) {
      // Use BarcodeScannerService to match barcode
      final barcodeScannerService = BarcodeScannerService();
      final barcodeResult = await barcodeScannerService.matchBarcode(barcode, null);
      if (barcodeResult.matched && barcodeResult.medication != null) {
        medication = barcodeResult.medication;
        identityVerified = true;
      }
    }

    if (medication == null) {
      return VerificationResult(
        isVerified: false,
        tradeName: tradeName ?? 'Unknown',
        verificationMethod: barcode != null ? 'barcode' : 'search',
        barcode: barcode,
        warnings: ['Medication not found in MOH database'],
      );
    }

    // Step 2: Fetch MIMS data
    try {
      final mimsResults = await _mimsService.searchDrug(medication.tradeName);
      if (mimsResults.isNotEmpty) {
        mimsData = mimsResults.first;
      }
    } catch (e) {
      // MIMS fetch failed, continue with MOH data only
    }

    // Step 3: Check contraindications
    if (mimsData != null && mimsData.contraindications != null) {
      contraindications = mimsData.contraindications!;
    }

    // Step 4: Check drug interactions if current medications provided
    if (currentMedications != null && currentMedications.isNotEmpty && medication.id != null) {
      final interactionResults = await _interactionService.checkInteractions(
        medication.id.toString(),
        currentMedications,
      );
      interactions = interactionResults.map((i) => i.description).toList();
    }

    // Step 5: Generate warnings
    if (contraindications.isNotEmpty) {
      warnings.add('Contraindications found: ${contraindications.join(", ")}');
    }
    if (interactions.isNotEmpty) {
      warnings.add('Drug interactions detected: ${interactions.length} interaction(s)');
    }

    // Step 6: Create verification result
    final result = VerificationResult(
      isVerified: identityVerified,
      medicationId: medication.id,
      tradeName: medication.tradeName,
      indications: mimsData?.indications,
      contraindications: contraindications.isNotEmpty ? contraindications : null,
      warnings: warnings.isNotEmpty ? warnings : null,
      interactions: interactions.isNotEmpty ? interactions : null,
      verificationMethod: barcode != null ? 'barcode' : 'search',
      barcode: barcode,
      mimsData: mimsData != null ? {
        'therapeutic_class': mimsData.therapeuticClass,
        'dosage': mimsData.dosage,
        'precautions': mimsData.precautions,
      } : null,
    );

    // Step 7: Store verification result and history
    await _dbService.insertVerificationResult(result);
    await _dbService.insertVerificationHistory(VerificationHistory(
      medicationId: medication.id,
      medicationName: medication.tradeName,
      identityVerified: identityVerified,
      contraindicationFound: contraindications.isNotEmpty,
      interactionFound: interactions.isNotEmpty,
      verificationMethod: barcode != null ? 'barcode' : 'search',
      barcode: barcode,
    ));

    // Step 8: Log audit
    await _auditService.logAction(
      actionType: 'verify',
      entityType: 'medication',
      entityId: medication.id,
      description: 'Verified medication: ${medication.tradeName}',
      metadata: {
        'method': barcode != null ? 'barcode' : 'search',
        'contraindications_found': contraindications.isNotEmpty,
        'interactions_found': interactions.isNotEmpty,
      },
    );

    return result;
  }

  // Get verification history
  Future<List<VerificationHistory>> getVerificationHistory({int? medicationId, int? limit}) async {
    return await _dbService.getVerificationHistory(medicationId: medicationId, limit: limit);
  }

  // Get recent verifications
  Future<List<VerificationResult>> getRecentVerifications({int limit = 10}) async {
    final all = await _dbService.getVerificationResults();
    return all.take(limit).toList();
  }
}

