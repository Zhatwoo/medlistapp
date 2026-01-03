import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:medlistapp/models/medication.dart';
import 'package:medlistapp/services/authservice.dart';

class FirestoreMedicineService {
  static final FirestoreMedicineService _instance = FirestoreMedicineService._internal();
  factory FirestoreMedicineService() => _instance;
  FirestoreMedicineService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AuthService _authService = AuthService();

  // Get medicines collection reference for a company code
  CollectionReference _getMedicinesCollection(String companyCode) {
    return _firestore
        .collection('companies')
        .doc(companyCode.toUpperCase())
        .collection('medicines');
  }

  // Add a medicine to Firestore
  Future<String> addMedicine(Medication medication, String companyCode) async {
    try {
      final normalizedCode = companyCode.trim().toUpperCase();
      final medicinesRef = _getMedicinesCollection(normalizedCode);
      
      // Convert medication to map
      final medicationMap = medication.toMap();
      medicationMap.remove('id'); // Remove SQLite ID
      medicationMap['companyCode'] = normalizedCode;
      medicationMap['createdAt'] = FieldValue.serverTimestamp();
      medicationMap['updatedAt'] = FieldValue.serverTimestamp();
      
      // Add document and return its ID
      final docRef = await medicinesRef.add(medicationMap);
      return docRef.id;
    } catch (e) {
      throw Exception('Failed to add medicine to Firestore: $e');
    }
  }

  // Add multiple medicines in batch
  Future<void> addMedicinesBatch(
    List<Medication> medications,
    String companyCode,
  ) async {
    try {
      final normalizedCode = companyCode.trim().toUpperCase();
      final medicinesRef = _getMedicinesCollection(normalizedCode);
      
      // Firestore batch write limit is 500
      const batchSize = 500;
      
      for (int i = 0; i < medications.length; i += batchSize) {
        final batch = _firestore.batch();
        final batchMedications = medications.skip(i).take(batchSize).toList();
        
        for (final medication in batchMedications) {
          // Skip invalid medications
          if (medication.tradeName.isEmpty || medication.tradeName == 'Unknown') {
            continue;
          }
          
          final medicationMap = medication.toMap();
          medicationMap.remove('id');
          medicationMap['companyCode'] = normalizedCode;
          medicationMap['createdAt'] = FieldValue.serverTimestamp();
          medicationMap['updatedAt'] = FieldValue.serverTimestamp();
          
          final docRef = medicinesRef.doc();
          batch.set(docRef, medicationMap);
        }
        
        await batch.commit();
        
        // Small delay to prevent overwhelming Firestore
        if (i + batchSize < medications.length) {
          await Future.delayed(const Duration(milliseconds: 100));
        }
      }
    } catch (e) {
      throw Exception('Failed to add medicines batch to Firestore: $e');
    }
  }

  // Get all medicines for a company code
  Future<List<Medication>> getMedicines(String companyCode) async {
    try {
      final normalizedCode = companyCode.trim().toUpperCase();
      final medicinesRef = _getMedicinesCollection(normalizedCode);
      
      final snapshot = await medicinesRef.get();
      
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        // Don't set id for Firestore documents (they use document IDs, not integer IDs)
        // The Medication model's id field is optional and used for SQLite
        return Medication.fromMap(data);
      }).toList();
    } catch (e) {
      throw Exception('Failed to get medicines from Firestore: $e');
    }
  }

  // Search medicines for a company code
  Future<List<Medication>> searchMedicines(
    String query,
    String companyCode,
  ) async {
    try {
      final normalizedCode = companyCode.trim().toUpperCase();
      final queryLower = query.toLowerCase();
      
      // Firestore doesn't support full-text search efficiently
      // Get all medicines and filter in memory
      // For large datasets, consider using Algolia or similar
      final allMedicines = await getMedicines(normalizedCode);
      
      return allMedicines.where((med) {
        return med.tradeName.toLowerCase().contains(queryLower) ||
            med.activeIngredient.toLowerCase().contains(queryLower) ||
            med.company.toLowerCase().contains(queryLower) ||
            med.strength.toLowerCase().contains(queryLower);
      }).toList();
    } catch (e) {
      throw Exception('Failed to search medicines: $e');
    }
  }

  // Get medicine by ID
  Future<Medication?> getMedicineById(String medicineId, String companyCode) async {
    try {
      final normalizedCode = companyCode.trim().toUpperCase();
      final medicinesRef = _getMedicinesCollection(normalizedCode);
      
      final doc = await medicinesRef.doc(medicineId).get();
      
      if (!doc.exists) return null;
      
      final data = doc.data() as Map<String, dynamic>;
      // Don't set id for Firestore documents
      return Medication.fromMap(data);
    } catch (e) {
      throw Exception('Failed to get medicine from Firestore: $e');
    }
  }

  // Update medicine
  Future<void> updateMedicine(
    String medicineId,
    Medication medication,
    String companyCode,
  ) async {
    try {
      final normalizedCode = companyCode.trim().toUpperCase();
      final medicinesRef = _getMedicinesCollection(normalizedCode);
      
      final medicationMap = medication.toMap();
      medicationMap.remove('id');
      medicationMap['updatedAt'] = FieldValue.serverTimestamp();
      
      await medicinesRef.doc(medicineId).update(medicationMap);
    } catch (e) {
      throw Exception('Failed to update medicine in Firestore: $e');
    }
  }

  // Delete medicine
  Future<void> deleteMedicine(String medicineId, String companyCode) async {
    try {
      final normalizedCode = companyCode.trim().toUpperCase();
      final medicinesRef = _getMedicinesCollection(normalizedCode);
      
      await medicinesRef.doc(medicineId).delete();
    } catch (e) {
      throw Exception('Failed to delete medicine from Firestore: $e');
    }
  }

  // Delete all medicines for a company code
  Future<void> deleteAllMedicines(String companyCode) async {
    try {
      final normalizedCode = companyCode.trim().toUpperCase();
      final medicinesRef = _getMedicinesCollection(normalizedCode);
      
      // Get all documents
      final snapshot = await medicinesRef.get();
      
      // Delete in batches
      const batchSize = 500;
      for (int i = 0; i < snapshot.docs.length; i += batchSize) {
        final batch = _firestore.batch();
        final batchDocs = snapshot.docs.skip(i).take(batchSize);
        
        for (final doc in batchDocs) {
          batch.delete(doc.reference);
        }
        
        await batch.commit();
        
        if (i + batchSize < snapshot.docs.length) {
          await Future.delayed(const Duration(milliseconds: 100));
        }
      }
    } catch (e) {
      throw Exception('Failed to delete all medicines from Firestore: $e');
    }
  }

  // Get medicines count for a company code
  Future<int> getMedicinesCount(String companyCode) async {
    try {
      final normalizedCode = companyCode.trim().toUpperCase();
      final medicinesRef = _getMedicinesCollection(normalizedCode);
      
      final snapshot = await medicinesRef.count().get();
      return snapshot.count ?? 0;
    } catch (e) {
      // Fallback to getting all and counting
      final medicines = await getMedicines(companyCode);
      return medicines.length;
    }
  }

  // Stream medicines for real-time updates
  Stream<List<Medication>> streamMedicines(String companyCode) {
    try {
      final normalizedCode = companyCode.trim().toUpperCase();
      final medicinesRef = _getMedicinesCollection(normalizedCode);
      
      return medicinesRef.snapshots().map((snapshot) {
        return snapshot.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          // Don't set id for Firestore documents
          return Medication.fromMap(data);
        }).toList();
      });
    } catch (e) {
      throw Exception('Failed to stream medicines from Firestore: $e');
    }
  }
}

