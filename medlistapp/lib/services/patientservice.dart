import 'package:medlistapp/models/patient.dart';
import 'package:medlistapp/services/databaseservice.dart';

class PatientService {
  final DatabaseService _dbService = DatabaseService();

  // Get all patients
  Future<List<Patient>> getAllPatients() async {
    return await _dbService.getAllPatients();
  }

  // Get patient by ID
  Future<Patient?> getPatientById(int id) async {
    return await _dbService.getPatientById(id);
  }

  // Search patients
  Future<List<Patient>> searchPatients(String query) async {
    if (query.isEmpty) {
      return await _dbService.getAllPatients();
    }
    return await _dbService.searchPatients(query);
  }

  // Add patient
  Future<int> addPatient(Patient patient) async {
    return await _dbService.insertPatient(patient);
  }

  // Update patient
  Future<int> updatePatient(Patient patient) async {
    return await _dbService.updatePatient(patient);
  }

  // Delete patient
  Future<int> deletePatient(int id) async {
    return await _dbService.deletePatient(id);
  }
}

