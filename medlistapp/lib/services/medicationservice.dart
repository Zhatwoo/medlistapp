import 'package:medlistapp/models/medication.dart';
import 'package:medlistapp/services/databaseservice.dart';
import 'package:medlistapp/services/authservice.dart';
import 'package:medlistapp/services/firestoremedicineservice.dart';

class MedicationService {
  final DatabaseService _dbService = DatabaseService();
  final AuthService _authService = AuthService();
  final FirestoreMedicineService _firestoreService = FirestoreMedicineService();

  // Get current user's company code
  Future<String?> _getCompanyCode() async {
    return await _authService.getCurrentUserCompanyCode();
  }

  // Search medications (Firestore first, SQLite fallback)
  Future<List<Medication>> searchMedications(String query) async {
    final companyCode = await _getCompanyCode();
    if (companyCode == null || companyCode.isEmpty) {
      // No company code, fallback to SQLite
      if (query.isEmpty) {
        return await _dbService.getAllMedications();
      }
      return await _dbService.searchMedications(query);
    }

    try {
      // Try Firestore first
      if (query.isEmpty) {
        return await _firestoreService.getMedicines(companyCode);
      } else {
        return await _firestoreService.searchMedicines(query, companyCode);
      }
    } catch (e) {
      print('Firestore search failed, falling back to SQLite: $e');
      // Fallback to SQLite
      if (query.isEmpty) {
        return await _dbService.getAllMedications(companyCode: companyCode);
      }
      return await _dbService.searchMedications(query, companyCode: companyCode);
    }
  }

  // Get all medications (Firestore first, SQLite fallback)
  Future<List<Medication>> getAllMedications() async {
    final companyCode = await _getCompanyCode();
    if (companyCode == null || companyCode.isEmpty) {
      // No company code, fallback to SQLite
      return await _dbService.getAllMedications();
    }

    try {
      // Try Firestore first
      return await _firestoreService.getMedicines(companyCode);
    } catch (e) {
      print('Firestore get all failed, falling back to SQLite: $e');
      // Fallback to SQLite
      return await _dbService.getAllMedications(companyCode: companyCode);
    }
  }

  // Get medication by ID
  Future<Medication?> getMedicationById(int id) async {
    return await _dbService.getMedicationById(id);
  }

  // Filter medications by company
  Future<List<Medication>> getMedicationsByCompany(String company) async {
    final all = await getAllMedications();
    return all.where((m) => m.company.toLowerCase().contains(company.toLowerCase())).toList();
  }

  // Filter medications by form
  Future<List<Medication>> getMedicationsByForm(String form) async {
    final all = await getAllMedications();
    return all.where((m) => m.form.toLowerCase().contains(form.toLowerCase())).toList();
  }

  // Filter medications by active ingredient
  Future<List<Medication>> getMedicationsByActiveIngredient(String ingredient) async {
    final all = await getAllMedications();
    return all.where((m) => m.activeIngredient.toLowerCase().contains(ingredient.toLowerCase())).toList();
  }

  // Get unique companies
  Future<List<String>> getUniqueCompanies() async {
    final all = await getAllMedications();
    final companies = all.map((m) => m.company).toSet().toList();
    companies.sort();
    return companies;
  }

  // Get unique forms
  Future<List<String>> getUniqueForms() async {
    final all = await getAllMedications();
    final forms = all.map((m) => m.form).toSet().toList();
    forms.sort();
    return forms;
  }

  // Add medication
  Future<int> addMedication(Medication medication) async {
    // Ensure medication has company code
    final companyCode = await _getCompanyCode();
    final medicationWithCode = medication.copyWith(companyCode: companyCode);
    return await _dbService.insertMedication(medicationWithCode);
  }

  // Update medication
  Future<int> updateMedication(Medication medication) async {
    return await _dbService.updateMedication(medication);
  }

  // Delete medication
  Future<int> deleteMedication(int id) async {
    return await _dbService.deleteMedication(id);
  }

  // Verify medication identity
  Future<bool> verifyMedicationIdentity(String tradeName, String? activeIngredient) async {
    final results = await searchMedications(tradeName);
    if (results.isEmpty) return false;
    
    if (activeIngredient != null) {
      return results.any((m) => 
        m.tradeName.toLowerCase() == tradeName.toLowerCase() &&
        m.activeIngredient.toLowerCase().contains(activeIngredient.toLowerCase())
      );
    }
    
    return results.any((m) => m.tradeName.toLowerCase() == tradeName.toLowerCase());
  }

  // Sync medicines from Firestore to SQLite for offline support
  // This is called automatically when user logs in with an existing company code
  Future<SyncResult> syncMedicinesFromFirestore() async {
    try {
      final companyCode = await _getCompanyCode();
      if (companyCode == null || companyCode.isEmpty) {
        return SyncResult(
          success: false,
          message: 'No company code found. Please set your company code first.',
          syncedCount: 0,
        );
      }

      print('Starting sync for company code: $companyCode');
      
      // Get medicines from Firestore
      final firestoreMedicines = await _firestoreService.getMedicines(companyCode);
      
      if (firestoreMedicines.isEmpty) {
        return SyncResult(
          success: true,
          message: 'No medicines found in Firestore for your company.',
          syncedCount: 0,
        );
      }

      print('Found ${firestoreMedicines.length} medicines in Firestore, syncing to SQLite...');

      // Clear existing medicines for this company code in SQLite
      final existingMeds = await _dbService.getAllMedications(companyCode: companyCode);
      for (final med in existingMeds) {
        if (med.id != null) {
          await _dbService.deleteMedication(med.id!);
        }
      }

      // Insert medicines from Firestore to SQLite
      int syncedCount = 0;
      int skippedCount = 0;
      const batchSize = 100;

      for (int i = 0; i < firestoreMedicines.length; i += batchSize) {
        final batch = firestoreMedicines.skip(i).take(batchSize).toList();
        
        for (final medication in batch) {
          try {
            // Ensure medication has company code
            final medicationWithCode = medication.copyWith(companyCode: companyCode);
            await _dbService.insertMedication(medicationWithCode);
            syncedCount++;
          } catch (e) {
            print('Error syncing medication ${medication.tradeName}: $e');
            skippedCount++;
          }
        }

        // Small delay to prevent blocking
        if (i + batchSize < firestoreMedicines.length) {
          await Future.delayed(const Duration(milliseconds: 50));
        }
      }

      print('Sync complete. Synced: $syncedCount, Skipped: $skippedCount');

      return SyncResult(
        success: true,
        message: 'Successfully synced $syncedCount medicines from your company.',
        syncedCount: syncedCount,
        skippedCount: skippedCount,
      );
    } catch (e) {
      print('Error syncing medicines: $e');
      return SyncResult(
        success: false,
        message: 'Failed to sync medicines: $e',
        syncedCount: 0,
      );
    }
  }
}

// Sync result class
class SyncResult {
  final bool success;
  final String message;
  final int syncedCount;
  final int skippedCount;

  SyncResult({
    required this.success,
    required this.message,
    required this.syncedCount,
    this.skippedCount = 0,
  });
}

