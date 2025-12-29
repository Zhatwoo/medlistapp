import 'package:flutter/material.dart';
import 'package:medlistapp/services/interaction_service.dart';
import 'package:medlistapp/services/medication_service.dart';
import 'package:medlistapp/models/drug_interaction.dart';
import 'package:medlistapp/models/medication.dart';
import 'package:medlistapp/utils/app_colors.dart';

class DrugInteractionCheckerPage extends StatefulWidget {
  const DrugInteractionCheckerPage({super.key});

  @override
  State<DrugInteractionCheckerPage> createState() => _DrugInteractionCheckerPageState();
}

class _DrugInteractionCheckerPageState extends State<DrugInteractionCheckerPage> {
  final InteractionService _interactionService = InteractionService();
  final MedicationService _medicationService = MedicationService();
  final TextEditingController _searchController = TextEditingController();
  
  List<Medication> _selectedMedications = [];
  List<DrugInteraction> _interactions = [];
  bool _isChecking = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _checkInteractions() async {
    if (_selectedMedications.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least 2 medications')),
      );
      return;
    }

    setState(() => _isChecking = true);
    try {
      final medicationIds = _selectedMedications
          .where((m) => m.id != null)
          .map((m) => m.id.toString())
          .toList();

      final interactions = await _interactionService.checkMultipleInteractions(medicationIds);
      
      setState(() {
        _interactions = interactions;
        _isChecking = false;
      });
    } catch (e) {
      setState(() => _isChecking = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error checking interactions: $e')),
        );
      }
    }
  }

  Future<void> _searchAndAddMedication(String query) async {
    if (query.isEmpty) return;

    final results = await _medicationService.searchMedications(query);
    if (results.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Medication not found')),
      );
      return;
    }

    if (results.length == 1) {
      if (!_selectedMedications.contains(results.first)) {
        setState(() => _selectedMedications.add(results.first));
        _searchController.clear();
      }
    } else {
      // Show selection dialog
      _showMedicationSelectionDialog(results);
    }
  }

  void _showMedicationSelectionDialog(List<Medication> medications) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Medication'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: medications.length,
            itemBuilder: (context, index) {
              final med = medications[index];
              return ListTile(
                title: Text(med.tradeName),
                subtitle: Text(med.form),
                onTap: () {
                  if (!_selectedMedications.contains(med)) {
                    setState(() => _selectedMedications.add(med));
                  }
                  Navigator.pop(context);
                  _searchController.clear();
                },
              );
            },
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.aliceBlue,
      appBar: AppBar(
        title: const Text('Drug Interaction Checker'),
        backgroundColor: AppColors.skyBlue,
        foregroundColor: AppColors.pureWhite,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Add medication
            Text(
              'Medications',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search medication to add',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onSubmitted: _searchAndAddMedication,
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: () => _searchAndAddMedication(_searchController.text),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Selected medications
            if (_selectedMedications.isNotEmpty) ...[
              Wrap(
                spacing: 8,
                children: _selectedMedications.map((med) {
                  return Chip(
                    label: Text(med.tradeName),
                    onDeleted: () {
                      setState(() => _selectedMedications.remove(med));
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.skyBlue,
                    foregroundColor: AppColors.pureWhite,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  onPressed: _isChecking ? null : _checkInteractions,
                  child: _isChecking
                      ? const CircularProgressIndicator()
                      : const Text('Check Interactions'),
                ),
              ),
            ],
            const SizedBox(height: 24),
            // Interactions
            if (_interactions.isNotEmpty) ...[
              Text(
                'Interactions Found',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              ..._interactions.map((interaction) => _InteractionCard(interaction: interaction)),
            ] else if (_selectedMedications.length >= 2 && !_isChecking) ...[
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    children: [
                      Icon(
                        Icons.check_circle,
                        size: 64,
                        color: AppColors.successGreen,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No interactions found',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _InteractionCard extends StatelessWidget {
  final DrugInteraction interaction;

  const _InteractionCard({required this.interaction});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: _getSeverityColor(interaction.severity).withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.warning,
                  color: _getSeverityColor(interaction.severity),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${interaction.medication1Name} + ${interaction.medication2Name}',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getSeverityColor(interaction.severity),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    interaction.severity.name.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(interaction.description),
            if (interaction.recommendation != null) ...[
              const SizedBox(height: 8),
              Text(
                'Recommendation: ${interaction.recommendation}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
            if (interaction.alternativeMedications != null) ...[
              const SizedBox(height: 8),
              Text(
                'Alternatives: ${interaction.alternativeMedications}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _getSeverityColor(InteractionSeverity severity) {
    switch (severity) {
      case InteractionSeverity.contraindicated:
        return AppColors.errorRed;
      case InteractionSeverity.severe:
        return AppColors.errorRed;
      case InteractionSeverity.moderate:
        return AppColors.warningOrange;
      case InteractionSeverity.mild:
        return AppColors.lowStockYellow;
    }
  }
}

