import 'package:medlistapp/models/medication.dart';
import 'package:medlistapp/models/mims_drug_data.dart';
import 'package:medlistapp/services/medication_service.dart';
import 'package:medlistapp/services/mims_service.dart';
import 'package:medlistapp/services/interaction_service.dart';

class MedicationRecommendation {
  final Medication medication;
  final MimsDrugData? mimsData;
  final double safetyScore; // 0-1, higher is safer
  final List<String> reasons;
  final List<String> warnings;

  MedicationRecommendation({
    required this.medication,
    this.mimsData,
    required this.safetyScore,
    required this.reasons,
    required this.warnings,
  });
}

class DiagnosisHelperService {
  final MedicationService _medicationService = MedicationService();
  final MimsService _mimsService = MimsService();
  final InteractionService _interactionService = InteractionService();

  // Map symptoms to possible indications
  Map<String, List<String>> _symptomToIndicationMap = {
    'headache': ['pain', 'migraine', 'tension'],
    'fever': ['infection', 'inflammation', 'pyrexia'],
    'cough': ['respiratory', 'bronchitis', 'asthma'],
    'pain': ['analgesic', 'anti-inflammatory'],
    'infection': ['antibiotic', 'antimicrobial'],
    'inflammation': ['anti-inflammatory', 'steroid'],
  };

  // Get medication recommendations based on symptoms
  Future<List<MedicationRecommendation>> getRecommendations({
    required List<String> symptoms,
    List<String>? currentMedications,
    List<String>? allergies,
    List<String>? contraindications,
  }) async {
    final recommendations = <MedicationRecommendation>[];

    // Step 1: Map symptoms to indications
    final indications = _mapSymptomsToIndications(symptoms);

    // Step 2: Search medications by indications
    final allMedications = await _medicationService.getAllMedications();

    // Step 3: Filter and rank medications
    for (final medication in allMedications) {
      // Get MIMS data if available
      MimsDrugData? mimsData;
      try {
        final mimsResults = await _mimsService.searchDrug(medication.tradeName);
        if (mimsResults.isNotEmpty) {
          mimsData = mimsResults.first;
        }
      } catch (e) {
        // MIMS data not available, continue
      }

      // Check if medication matches indications
      bool matchesIndication = false;
      if (mimsData != null && mimsData.indications != null) {
        for (final indication in indications) {
          for (final medIndication in mimsData.indications!) {
            if (medIndication.toLowerCase().contains(indication.toLowerCase())) {
              matchesIndication = true;
              break;
            }
          }
          if (matchesIndication) break;
        }
      }

      if (!matchesIndication) continue;

      // Check contraindications
      final contraindicationWarnings = <String>[];
      if (mimsData != null && mimsData.contraindications != null) {
        for (final contraindication in mimsData.contraindications!) {
          if (contraindications != null) {
            for (final userContraindication in contraindications) {
              if (contraindication.toLowerCase().contains(userContraindication.toLowerCase())) {
                contraindicationWarnings.add('Contraindicated: $contraindication');
              }
            }
          }
        }
      }

      // Check allergies
      final allergyWarnings = <String>[];
      if (allergies != null && mimsData != null) {
        final activeIngredient = medication.activeIngredient.toLowerCase();
        for (final allergy in allergies) {
          if (activeIngredient.contains(allergy.toLowerCase())) {
            allergyWarnings.add('Allergy warning: Contains $allergy');
          }
        }
      }

      // Check interactions
      final interactionWarnings = <String>[];
      if (currentMedications != null && currentMedications.isNotEmpty && medication.id != null) {
        final interactions = await _interactionService.checkInteractions(
          medication.id.toString(),
          currentMedications,
        );
        for (final interaction in interactions) {
          if (interaction.severity == InteractionSeverity.severe ||
              interaction.severity == InteractionSeverity.contraindicated) {
            interactionWarnings.add('Severe interaction: ${interaction.description}');
          }
        }
      }

      // Calculate safety score
      double safetyScore = 1.0;
      if (contraindicationWarnings.isNotEmpty) safetyScore -= 0.5;
      if (allergyWarnings.isNotEmpty) safetyScore -= 0.5;
      if (interactionWarnings.isNotEmpty) safetyScore -= 0.3;
      if (safetyScore < 0) safetyScore = 0;

      // Skip if contraindicated or allergic
      if (contraindicationWarnings.isNotEmpty || allergyWarnings.isNotEmpty) {
        continue;
      }

      // Build reasons
      final reasons = <String>[];
      if (mimsData != null && mimsData.indications != null) {
        reasons.addAll(mimsData.indications!.take(3));
      }
      reasons.add('Available in inventory');

      // Build warnings
      final warnings = <String>[];
      warnings.addAll(interactionWarnings);
      if (mimsData?.precautions != null) {
        warnings.add('Precautions: ${mimsData!.precautions}');
      }

      recommendations.add(MedicationRecommendation(
        medication: medication,
        mimsData: mimsData,
        safetyScore: safetyScore,
        reasons: reasons,
        warnings: warnings,
      ));
    }

    // Sort by safety score (highest first)
    recommendations.sort((a, b) => b.safetyScore.compareTo(a.safetyScore));

    return recommendations;
  }

  // Map symptoms to possible indications
  List<String> _mapSymptomsToIndications(List<String> symptoms) {
    final indications = <String>[];
    for (final symptom in symptoms) {
      final symptomLower = symptom.toLowerCase();
      if (_symptomToIndicationMap.containsKey(symptomLower)) {
        indications.addAll(_symptomToIndicationMap[symptomLower]!);
      } else {
        // Try partial match
        for (final entry in _symptomToIndicationMap.entries) {
          if (symptomLower.contains(entry.key) || entry.key.contains(symptomLower)) {
            indications.addAll(entry.value);
          }
        }
      }
    }
    return indications.toSet().toList(); // Remove duplicates
  }
}

