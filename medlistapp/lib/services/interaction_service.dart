import 'package:medlistapp/models/drug_interaction.dart';
import 'package:medlistapp/services/mims_service.dart';
import 'package:medlistapp/services/database_service.dart';

class InteractionService {
  final MimsService _mimsService = MimsService();
  final DatabaseService _dbService = DatabaseService();

  // Check interactions between a medication and a list of other medications
  Future<List<DrugInteraction>> checkInteractions(
    String medicationId,
    List<String> otherMedicationIds,
  ) async {
    final interactions = <DrugInteraction>[];

    try {
      // Check interactions via MIMS API
      final mimsInteractions = await _mimsService.getDrugInteractions(
        medicationId,
        otherMedicationIds,
      );

      // Parse MIMS interaction data
      if (mimsInteractions.isNotEmpty) {
        for (final entry in mimsInteractions.entries) {
          final otherMedId = entry.key;
          final interactionData = entry.value as Map<String, dynamic>;
          
          final severity = _parseSeverity(interactionData['severity'] as String? ?? 'mild');
          
          final interaction = DrugInteraction(
            medication1Id: medicationId,
            medication1Name: interactionData['medication1_name'] as String? ?? 'Unknown',
            medication2Id: otherMedId,
            medication2Name: interactionData['medication2_name'] as String? ?? 'Unknown',
            severity: severity,
            description: interactionData['description'] as String? ?? 'Interaction detected',
            recommendation: interactionData['recommendation'] as String?,
            alternativeMedications: interactionData['alternatives'] != null
                ? (interactionData['alternatives'] as List).join(', ')
                : null,
          );

          interactions.add(interaction);
          await _dbService.insertDrugInteraction(interaction);
        }
      }
    } catch (e) {
      // If MIMS fails, check local database
      final localInteractions = await _dbService.getDrugInteractions(medicationId);
      interactions.addAll(localInteractions);
    }

    return interactions;
  }

  // Check interactions for multiple medications (pairwise)
  Future<List<DrugInteraction>> checkMultipleInteractions(List<String> medicationIds) async {
    final allInteractions = <DrugInteraction>[];
    
    // Check all pairs
    for (int i = 0; i < medicationIds.length; i++) {
      for (int j = i + 1; j < medicationIds.length; j++) {
        final med1 = medicationIds[i];
        final med2 = medicationIds[j];
        
        final interactions = await checkInteractions(med1, [med2]);
        allInteractions.addAll(interactions);
      }
    }

    return allInteractions;
  }

  // Get interactions for a medication
  Future<List<DrugInteraction>> getInteractionsForMedication(String medicationId) async {
    return await _dbService.getDrugInteractions(medicationId);
  }

  // Parse severity string to enum
  InteractionSeverity _parseSeverity(String severity) {
    switch (severity.toLowerCase()) {
      case 'severe':
      case 'contraindicated':
        return InteractionSeverity.contraindicated;
      case 'moderate':
        return InteractionSeverity.moderate;
      case 'mild':
      default:
        return InteractionSeverity.mild;
    }
  }
}

