import 'package:medlistapp/models/medication.dart';
import 'package:medlistapp/services/databaseservice.dart';

class MedicationService {
  final DatabaseService _dbService = DatabaseService();

  // Search medications
  Future<List<Medication>> searchMedications(String query) async {
    if (query.isEmpty) {
      return await _dbService.getAllMedications();
    }
    return await _dbService.searchMedications(query);
  }

  // Get all medications
  Future<List<Medication>> getAllMedications() async {
    return await _dbService.getAllMedications();
  }

  // Get medication by ID
  Future<Medication?> getMedicationById(int id) async {
    return await _dbService.getMedicationById(id);
  }

  // Filter medications by company
  Future<List<Medication>> getMedicationsByCompany(String company) async {
    final all = await _dbService.getAllMedications();
    return all.where((m) => m.company.toLowerCase().contains(company.toLowerCase())).toList();
  }

  // Filter medications by form
  Future<List<Medication>> getMedicationsByForm(String form) async {
    final all = await _dbService.getAllMedications();
    return all.where((m) => m.form.toLowerCase().contains(form.toLowerCase())).toList();
  }

  // Filter medications by active ingredient
  Future<List<Medication>> getMedicationsByActiveIngredient(String ingredient) async {
    final all = await _dbService.getAllMedications();
    return all.where((m) => m.activeIngredient.toLowerCase().contains(ingredient.toLowerCase())).toList();
  }

  // Get unique companies
  Future<List<String>> getUniqueCompanies() async {
    final all = await _dbService.getAllMedications();
    final companies = all.map((m) => m.company).toSet().toList();
    companies.sort();
    return companies;
  }

  // Get unique forms
  Future<List<String>> getUniqueForms() async {
    final all = await _dbService.getAllMedications();
    final forms = all.map((m) => m.form).toSet().toList();
    forms.sort();
    return forms;
  }

  // Add medication
  Future<int> addMedication(Medication medication) async {
    return await _dbService.insertMedication(medication);
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
}

