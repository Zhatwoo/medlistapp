import 'package:flutter/material.dart';
import 'package:medlistapp/models/medication.dart';
import 'package:medlistapp/models/verification_result.dart';
import 'package:medlistapp/services/medication_service.dart';
import 'package:medlistapp/services/verification_service.dart';
import 'package:medlistapp/utils/app_colors.dart';
import 'package:medlistapp/widgets/search_bar_widget.dart';
import 'package:medlistapp/screens/medication_detail_page.dart';
import 'package:medlistapp/screens/barcode_scanner_page.dart';

class MedicationVerificationPage extends StatefulWidget {
  const MedicationVerificationPage({super.key});

  @override
  State<MedicationVerificationPage> createState() => _MedicationVerificationPageState();
}

class _MedicationVerificationPageState extends State<MedicationVerificationPage> {
  final MedicationService _medicationService = MedicationService();
  final VerificationService _verificationService = VerificationService();
  final TextEditingController _searchController = TextEditingController();
  
  List<Medication> _searchResults = [];
  Medication? _selectedMedication;
  VerificationResult? _verificationResult;
  bool _isSearching = false;
  bool _isVerifying = false;
  bool _isVerified = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _searchMedication(String query) async {
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
        _selectedMedication = null;
        _isVerified = false;
      });
      return;
    }

    setState(() => _isSearching = true);
    try {
      final results = await _medicationService.searchMedications(query);
      setState(() {
        _searchResults = results;
        _isSearching = false;
      });
    } catch (e) {
      setState(() => _isSearching = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error searching: $e')),
        );
      }
    }
  }

  Future<void> _verifyMedication(Medication medication) async {
    setState(() {
      _selectedMedication = medication;
      _isVerifying = true;
    });

    try {
      final result = await _verificationService.verifyMedication(
        tradeName: medication.tradeName,
      );
      
      setState(() {
        _verificationResult = result;
        _isVerifying = false;
      });
    } catch (e) {
      setState(() => _isVerifying = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error verifying: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.aliceBlue,
      appBar: AppBar(
        title: const Text('Medication Verification'),
        backgroundColor: AppColors.skyBlue,
        foregroundColor: AppColors.pureWhite,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_scanner),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const BarcodeScannerPage(),
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: SearchBarWidget(
              controller: _searchController,
              hintText: 'Search by trade name, ingredient, or company...',
              onChanged: _searchMedication,
            ),
          ),
          if (_isSearching)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_selectedMedication != null && _verificationResult != null)
            Expanded(
              child: _buildVerificationResult(),
            )
          else if (_isVerifying)
            const Expanded(
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_searchResults.isNotEmpty)
            Expanded(
              child: _buildSearchResults(),
            )
          else if (_searchController.text.isNotEmpty && !_isSearching)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.search_off,
                      size: 64,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No medications found',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ],
                ),
              ),
            )
          else
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.verified_user_outlined,
                      size: 64,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Search for a medication to verify',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Enter trade name, active ingredient, or company name',
                      style: Theme.of(context).textTheme.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSearchResults() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final medication = _searchResults[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            title: Text(medication.tradeName),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(medication.form),
                Text(medication.activeIngredient),
                Text(medication.company),
              ],
            ),
            trailing: ElevatedButton(
              onPressed: () => _verifyMedication(medication),
              child: const Text('Verify'),
            ),
          ),
        );
      },
    );
  }

  Widget _buildVerificationResult() {
    if (_selectedMedication == null || _verificationResult == null) return const SizedBox();

    final result = _verificationResult!;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Verification Status
          Card(
            color: result.isVerified
                ? AppColors.successGreen.withOpacity(0.1)
                : AppColors.errorRed.withOpacity(0.1),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(
                    result.isVerified ? Icons.verified : Icons.error,
                    color: result.isVerified ? AppColors.successGreen : AppColors.errorRed,
                    size: 32,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          result.isVerified ? 'Medication Verified' : 'Verification Failed',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: result.isVerified ? AppColors.successGreen : AppColors.errorRed,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          result.isVerified
                              ? 'Identity confirmed in MOH database'
                              : 'Medication not found in database',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Warnings
          if (result.warnings != null && result.warnings!.isNotEmpty) ...[
            const SizedBox(height: 16),
            Card(
              color: AppColors.warningOrange.withOpacity(0.1),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.warning, color: AppColors.warningOrange),
                        const SizedBox(width: 8),
                        Text(
                          'Warnings',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: AppColors.warningOrange,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ...result.warnings!.map((warning) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text('• $warning', style: Theme.of(context).textTheme.bodyMedium),
                    )),
                  ],
                ),
              ),
            ),
          ],
          // Contraindications
          if (result.contraindications != null && result.contraindications!.isNotEmpty) ...[
            const SizedBox(height: 16),
            Card(
              color: AppColors.errorRed.withOpacity(0.1),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.error, color: AppColors.errorRed),
                        const SizedBox(width: 8),
                        Text(
                          'Contraindications',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: AppColors.errorRed,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ...result.contraindications!.map((contraindication) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text('• $contraindication', style: Theme.of(context).textTheme.bodyMedium),
                    )),
                  ],
                ),
              ),
            ),
          ],
          // Interactions
          if (result.interactions != null && result.interactions!.isNotEmpty) ...[
            const SizedBox(height: 16),
            Card(
              color: AppColors.warningOrange.withOpacity(0.1),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.merge_type, color: AppColors.warningOrange),
                        const SizedBox(width: 8),
                        Text(
                          'Drug Interactions',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: AppColors.warningOrange,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ...result.interactions!.map((interaction) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text('• $interaction', style: Theme.of(context).textTheme.bodyMedium),
                    )),
                  ],
                ),
              ),
            ),
          ],
          // Medication Details
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Medication Details',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const Divider(height: 24),
                  _DetailRow('Trade Name', _selectedMedication!.tradeName),
                  _DetailRow('Form', _selectedMedication!.form),
                  _DetailRow('Pack Size', _selectedMedication!.packSize),
                  _DetailRow('Active Ingredient', _selectedMedication!.activeIngredient),
                  _DetailRow('Strength', _selectedMedication!.strength),
                  _DetailRow('Company', _selectedMedication!.company),
                  if (result.indications != null && result.indications!.isNotEmpty) ...[
                    const Divider(height: 24),
                    Text(
                      'Indications',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    ...result.indications!.map((indication) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text('• $indication', style: Theme.of(context).textTheme.bodyMedium),
                    )),
                  ],
                ],
              ),
            ),
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
              onPressed: () {
                if (_selectedMedication!.id != null) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => MedicationDetailPage(
                        medicationId: _selectedMedication!.id!,
                      ),
                    ),
                  );
                }
              },
              child: const Text('View Full Details'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _DetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}

