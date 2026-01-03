import 'package:flutter/material.dart';
import 'package:medlistapp/services/diagnosishelperservice.dart';
import 'package:medlistapp/models/medication.dart';
import 'package:medlistapp/utils/appcolors.dart';
import 'package:medlistapp/widgets/clinicaldisclaimerwidget.dart';
import 'package:medlistapp/screens/medicationdetailpage.dart';

class DiagnosisHelperPage extends StatefulWidget {
  const DiagnosisHelperPage({super.key});

  @override
  State<DiagnosisHelperPage> createState() => _DiagnosisHelperPageState();
}

class _DiagnosisHelperPageState extends State<DiagnosisHelperPage> {
  final DiagnosisHelperService _service = DiagnosisHelperService();
  final TextEditingController _symptomController = TextEditingController();
  final List<String> _symptoms = [];
  final List<String> _currentMedications = [];
  final List<String> _allergies = [];
  List<MedicationRecommendation> _recommendations = [];
  bool _isLoading = false;

  @override
  void dispose() {
    _symptomController.dispose();
    super.dispose();
  }


  Future<void> _getRecommendations() async {
    if (_symptoms.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter at least one symptom')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final recommendations = await _service.getRecommendations(
        symptoms: _symptoms,
        currentMedications: _currentMedications,
        allergies: _allergies,
      );
      setState(() {
        _recommendations = recommendations;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.aliceBlue,
      appBar: AppBar(
        title: const Text('Diagnosis Helper'),
        backgroundColor: AppColors.skyBlue,
        foregroundColor: AppColors.pureWhite,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Clinical Disclaimer
            const ClinicalDisclaimerWidget(padding: EdgeInsets.zero),
            const SizedBox(height: 16),
            // Symptoms input
            Text(
              'Symptoms',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _symptomController,
                    decoration: InputDecoration(
                      hintText: 'Enter symptom (e.g., headache, fever)',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onSubmitted: (value) {
                      if (value.isNotEmpty) {
                        setState(() => _symptoms.add(value));
                        _symptomController.clear();
                      }
                    },
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: () {
                    if (_symptomController.text.isNotEmpty) {
                      setState(() => _symptoms.add(_symptomController.text));
                      _symptomController.clear();
                    }
                  },
                ),
              ],
            ),
            if (_symptoms.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: _symptoms.map((symptom) {
                  return Chip(
                    label: Text(symptom),
                    onDeleted: () {
                      setState(() => _symptoms.remove(symptom));
                    },
                  );
                }).toList(),
              ),
            ],
            const SizedBox(height: 16),
            // Current Medications (if needed, can be enhanced later)
            if (_currentMedications.isNotEmpty) ...[
              Text(
                'Current Medications',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: _currentMedications.map((med) {
                  return Chip(
                    label: Text(med),
                    onDeleted: () {
                      setState(() => _currentMedications.remove(med));
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
            ],
            // Allergies (pre-populated from patient if selected)
            if (_allergies.isNotEmpty) ...[
              Text(
                'Allergies',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: _allergies.map((allergy) {
                  return Chip(
                    label: Text(allergy),
                    backgroundColor: AppColors.errorRedLight,
                    labelStyle: TextStyle(
                      color: AppColors.errorRed,
                      fontWeight: FontWeight.w600,
                    ),
                    deleteIcon: Icon(Icons.close, size: 18, color: AppColors.errorRed),
                    onDeleted: () {
                      setState(() => _allergies.remove(allergy));
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
            ],
            // Get recommendations button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.skyBlue,
                  foregroundColor: AppColors.pureWhite,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                onPressed: _isLoading ? null : _getRecommendations,
                child: _isLoading
                    ? const CircularProgressIndicator()
                    : const Text('Get Recommendations'),
              ),
            ),
            const SizedBox(height: 24),
            // Recommendations
            if (_recommendations.isNotEmpty) ...[
              Text(
                'Recommendations',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              ..._recommendations.map((rec) => _RecommendationCard(
                recommendation: rec,
                onTap: () {
                  if (rec.medication.id != null) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => MedicationDetailPage(
                          medicationId: rec.medication.id!,
                        ),
                      ),
                    );
                  }
                },
              )),
            ],
          ],
        ),
      ),
    );
  }
}

class _RecommendationCard extends StatelessWidget {
  final MedicationRecommendation recommendation;
  final VoidCallback onTap;

  const _RecommendationCard({
    required this.recommendation,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      recommendation.medication.tradeName,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getSafetyColor(recommendation.safetyScore).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${(recommendation.safetyScore * 100).toInt()}% Safe',
                      style: TextStyle(
                        color: _getSafetyColor(recommendation.safetyScore),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (recommendation.reasons.isNotEmpty) ...[
                Text(
                  'Reasons:',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                ...recommendation.reasons.map((reason) => Padding(
                  padding: const EdgeInsets.only(left: 8, top: 4),
                  child: Text('• $reason', style: Theme.of(context).textTheme.bodySmall),
                )),
              ],
              if (recommendation.warnings.isNotEmpty) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.warningOrange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.warning, size: 16, color: AppColors.warningOrange),
                          const SizedBox(width: 4),
                          Text(
                            'Warnings:',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppColors.warningOrange,
                            ),
                          ),
                        ],
                      ),
                      ...recommendation.warnings.map((warning) => Padding(
                        padding: const EdgeInsets.only(left: 20, top: 4),
                        child: Text('• $warning', style: Theme.of(context).textTheme.bodySmall),
                      )),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Color _getSafetyColor(double score) {
    if (score >= 0.8) return AppColors.successGreen;
    if (score >= 0.5) return AppColors.warningOrange;
    return AppColors.errorRed;
  }
}

