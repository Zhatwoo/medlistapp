import 'package:flutter/material.dart';
import 'package:medlistapp/models/medication.dart';
import 'package:medlistapp/models/mimsdrugdata.dart';
import 'package:medlistapp/models/stockitem.dart';
import 'package:medlistapp/services/medicationservice.dart';
import 'package:medlistapp/services/mimsservice.dart';
import 'package:medlistapp/services/stockservice.dart';
import 'package:medlistapp/utils/appcolors.dart';
import 'package:medlistapp/widgets/stockstatusindicator.dart';
import 'package:medlistapp/screens/addeditmedicationpage.dart';
import 'package:intl/intl.dart';

class MedicationDetailPage extends StatefulWidget {
  final int medicationId;

  const MedicationDetailPage({super.key, required this.medicationId});

  @override
  State<MedicationDetailPage> createState() => _MedicationDetailPageState();
}

class _MedicationDetailPageState extends State<MedicationDetailPage> {
  final MedicationService _medicationService = MedicationService();
  final StockService _stockService = StockService();
  final MimsService _mimsService = MimsService();
  
  Medication? _medication;
  List<StockItem> _stockItems = [];
  int _totalStock = 0;
  bool _isLoading = true;
  MimsDrugData? _mimsData;
  bool _mimsLoading = false;
  String? _mimsError;

  @override
  void initState() {
    super.initState();
    _loadMedicationDetails();
  }

  Future<void> _loadMedicationDetails() async {
    setState(() => _isLoading = true);
    try {
      final medication = await _medicationService.getMedicationById(widget.medicationId);
      final stockItems = await _stockService.getStockItemsByMedicationId(widget.medicationId);
      final totalStock = await _stockService.getTotalStockQuantity(widget.medicationId);
      
      setState(() {
        _medication = medication;
        _stockItems = stockItems;
        _totalStock = totalStock;
        _isLoading = false;
      });
      _loadMimsData();
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading medication: $e')),
        );
      }
    }
  }

  Future<void> _loadMimsData() async {
    if (_medication == null) return;
    setState(() {
      _mimsLoading = true;
      _mimsError = null;
    });
    try {
      final results = await _mimsService.searchDrug(_medication!.tradeName);
      if (results.isNotEmpty) {
        if (mounted) setState(() => _mimsData = results.first);
      } else {
        if (mounted) setState(() => _mimsError = 'No MIMS data found for this medication.');
      }
    } catch (e) {
      if (mounted) setState(() => _mimsError = 'Unable to load MIMS data.');
    } finally {
      if (mounted) setState(() => _mimsLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppColors.aliceBlue,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_medication == null) {
      return Scaffold(
        backgroundColor: AppColors.aliceBlue,
        appBar: AppBar(
          title: const Text('Medication Details'),
          backgroundColor: AppColors.skyBlue,
          foregroundColor: AppColors.pureWhite,
        ),
        body: const Center(child: Text('Medication not found')),
      );
    }

    final priceFormat = NumberFormat.currency(symbol: 'AED ', decimalDigits: 2);
    final dateFormat = DateFormat('MMM dd, yyyy');

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: AppColors.aliceBlue,
        appBar: AppBar(
          backgroundColor: AppColors.skyBlue,
          foregroundColor: AppColors.pureWhite,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: Column(
          children: [
            // Header Section (inspired by doctor profile)
            Container(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
              decoration: const BoxDecoration(
                color: AppColors.skyBlue,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(24),
                  bottomRight: Radius.circular(24),
                ),
              ),
              child: Column(
                children: [
                  // Medication Icon/Avatar
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.3),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.medication,
                      color: Colors.white,
                      size: 50,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Medication Name
                  Text(
                    _medication!.tradeName,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  // Form (like specialty)
                  Text(
                    _medication!.form,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Statistics Cards (inspired by "550+ Patients", etc.)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _StatCard(
                        value: '$_totalStock',
                        label: 'Total Stock',
                        icon: Icons.inventory,
                      ),
                      _StatCard(
                        value: '${_stockItems.length}',
                        label: 'Batches',
                        icon: Icons.layers,
                      ),
                      _StatCard(
                        value: '${_stockItems.where((s) => s.isExpiringSoon(30)).length}',
                        label: 'Expiring',
                        icon: Icons.warning,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Tab Bar
            Container(
              color: AppColors.pureWhite,
              child: TabBar(
                labelColor: AppColors.skyBlue,
                unselectedLabelColor: AppColors.mediumGray,
                indicatorColor: AppColors.skyBlue,
                tabs: const [
                  Tab(text: 'Info'),
                  Tab(text: 'Stock'),
                  Tab(text: 'Medical'),
                ],
              ),
            ),
            // Tab Content
            Expanded(
              child: TabBarView(
                children: [
                  _buildInfoTab(priceFormat),
                  _buildStockTab(dateFormat),
                  _buildMedicalTab(),
                ],
              ),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          backgroundColor: AppColors.skyBlue,
          foregroundColor: AppColors.pureWhite,
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => AddEditMedicationPage(
                  medication: _medication,
                ),
              ),
            ).then((_) => _loadMedicationDetails());
          },
          icon: const Icon(Icons.add),
          label: const Text('Add Stock'),
        ),
      ),
    );
  }

  Widget _StatCard({required String value, required String label, required IconData icon}) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: Colors.white, size: 24),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.9),
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoTab(NumberFormat priceFormat) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          _medication!.tradeName,
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                      ),
                      StockStatusIndicator(quantity: _totalStock),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _InfoRow('Form', _medication!.form),
                  _InfoRow('Pack Size', _medication!.packSize),
                  _InfoRow('Active Ingredient', _medication!.activeIngredient),
                  _InfoRow('Strength', _medication!.strength),
                  _InfoRow('Company', _medication!.company),
                  _InfoRow('Source', _medication!.source),
                  _InfoRow('Agent', _medication!.agent),
                  _InfoRow('Dispensing Mode', _medication!.dispensingMode),
                  _InfoRow('Storage Condition', _medication!.storageCondition ?? 'N/A'),
                  _InfoRow('Controlled Drug', _medication!.isControlledDrug ? 'Yes' : 'No'),
                  _InfoRow('Therapeutic Category', _medication!.therapeuticCategory ?? 'N/A'),
                  if (_medication!.isControlledDrug) ...[
                    const SizedBox(height: 8),
                    Chip(
                      label: const Text(
                        'Controlled Drug',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                      backgroundColor: Colors.orange,
                      avatar: const Icon(Icons.warning, color: Colors.white, size: 18),
                    ),
                  ],
                  const Divider(height: 32),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Column(
                        children: [
                          Text(
                            'Pharmacy Price',
                            style: Theme.of(context).textTheme.labelMedium,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            priceFormat.format(_medication!.pharmacyPrice),
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: AppColors.skyBlue,
                            ),
                          ),
                        ],
                      ),
                      Column(
                        children: [
                          Text(
                            'Public Price',
                            style: Theme.of(context).textTheme.labelMedium,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            priceFormat.format(_medication!.publicPrice),
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStockTab(DateFormat dateFormat) {
    return _stockItems.isEmpty
        ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.inventory_2_outlined,
                  size: 64,
                  color: AppColors.mediumGray.withOpacity(0.5),
                ),
                const SizedBox(height: 16),
                Text(
                  'No stock items',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.mediumGray,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Tap the + button to add stock',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.mediumGray,
                  ),
                ),
              ],
            ),
          )
        : ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _stockItems.length,
            itemBuilder: (context, index) {
              final stockItem = _stockItems[index];
              final isExpired = stockItem.isExpired;
              final isExpiringSoon = stockItem.isExpiringSoon(30);
              
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                color: isExpired
                    ? Colors.red.withOpacity(0.1)
                    : isExpiringSoon
                        ? Colors.orange.withOpacity(0.1)
                        : null,
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  title: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Quantity: ${stockItem.quantity}',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                      if (stockItem.expectedQuantity != null) ...[
                        const SizedBox(width: 8),
                        Text(
                          '(Expected: ${stockItem.expectedQuantity})',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: stockItem.isOverstocked
                                ? Colors.orange
                                : stockItem.isUnderstocked
                                    ? Colors.red
                                    : Colors.green,
                          ),
                        ),
                      ],
                    ],
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 8),
                      Text('Expiry: ${dateFormat.format(stockItem.expiryDate)}'),
                      if (stockItem.manufacturingDate != null)
                        Text('Manufactured: ${dateFormat.format(stockItem.manufacturingDate!)}'),
                      if (stockItem.batchNumber != null)
                        Text('Batch: ${stockItem.batchNumber}'),
                      if (stockItem.location != null)
                        Text('Location: ${stockItem.location}'),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 4,
                        children: [
                          if (isExpired)
                            Chip(
                              label: const Text('Expired', style: TextStyle(color: Colors.white, fontSize: 11)),
                              backgroundColor: Colors.red,
                              padding: EdgeInsets.zero,
                              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            )
                          else if (isExpiringSoon)
                            Chip(
                              label: Text('${stockItem.daysUntilExpiry} days left', style: const TextStyle(color: Colors.white, fontSize: 11)),
                              backgroundColor: Colors.orange,
                              padding: EdgeInsets.zero,
                              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                          if (stockItem.isOverstocked)
                            Chip(
                              label: const Text('Overstocked', style: TextStyle(color: Colors.white, fontSize: 11)),
                              backgroundColor: Colors.orange,
                              padding: EdgeInsets.zero,
                              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                          if (stockItem.variance != null && stockItem.variance! < 0)
                            Chip(
                              label: Text('Under: ${stockItem.variance!.abs()}', style: const TextStyle(color: Colors.white, fontSize: 11)),
                              backgroundColor: Colors.red,
                              padding: EdgeInsets.zero,
                              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                          if (stockItem.variance != null && stockItem.variance! > 0 && !stockItem.isOverstocked)
                            Chip(
                              label: Text('Over: +${stockItem.variance}', style: const TextStyle(color: Colors.white, fontSize: 11)),
                              backgroundColor: Colors.green,
                              padding: EdgeInsets.zero,
                              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                        ],
                      ),
                    ],
                  ),
                  trailing: null,
                ),
              );
            },
          );
  }

  Widget _buildMedicalTab() {
    if (_mimsLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(48),
          child: CircularProgressIndicator(),
        ),
      );
    }
    if (_mimsError != null && _mimsData == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.info_outline, size: 48, color: AppColors.mediumGray),
              const SizedBox(height: 16),
              Text(_mimsError!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: _loadMimsData,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }
    final d = _mimsData;
    if (d == null) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Text('No MIMS data available.'),
        ),
      );
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(d.drugName, style: Theme.of(context).textTheme.titleLarge),
                  if (d.genericName != null && d.genericName!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(d.genericName!, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.mediumGray)),
                  ],
                  if (d.therapeuticClass != null && d.therapeuticClass!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Chip(label: Text(d.therapeuticClass!, style: const TextStyle(fontSize: 12)), backgroundColor: AppColors.softBlue),
                  ],
                ],
              ),
            ),
          ),
          if (d.indications != null && d.indications!.isNotEmpty)
            _buildMimsSection('Indications', d.indications!, Icons.check_circle_outline, AppColors.successGreen),
          if (d.contraindications != null && d.contraindications!.isNotEmpty)
            _buildMimsSection('Contraindications', d.contraindications!, Icons.block, AppColors.errorRed),
          if (d.dosage != null && d.dosage!.isNotEmpty)
            _buildMimsTextSection('Dosage', d.dosage!, Icons.medication_outlined),
          if (d.precautions != null && d.precautions!.isNotEmpty)
            _buildMimsTextSection('Warnings / Precautions', d.precautions!, Icons.warning_amber),
          if (d.sideEffects != null && d.sideEffects!.isNotEmpty)
            _buildMimsSection('Side Effects', d.sideEffects!, Icons.report_problem_outlined, AppColors.warningOrange),
          if (d.interactions != null && d.interactions!.isNotEmpty)
            _buildMimsTextSection(
              'Interactions',
              d.interactions!.entries.map((e) => '${e.key}: ${e.value}').join('\n'),
              Icons.compare_arrows,
            ),
          if (d.administration != null && d.administration!.isNotEmpty)
            _buildMimsTextSection('Administration', d.administration!, Icons.local_hospital),
          if (d.storage != null && d.storage!.isNotEmpty)
            _buildMimsTextSection('Storage', d.storage!, Icons.inventory_2),
          const SizedBox(height: 16),
          Center(
            child: Text(
              'Source: MIMS',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.mediumGray,
                    fontStyle: FontStyle.italic,
                  ),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildMimsSection(String title, List<String> items, IconData icon, Color color) {
    return Card(
      margin: const EdgeInsets.only(top: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 8),
                Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 12),
            ...items.map((item) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('• ', style: TextStyle(fontWeight: FontWeight.bold)),
                  Expanded(child: Text(item, style: Theme.of(context).textTheme.bodyMedium)),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildMimsTextSection(String title, String text, IconData icon) {
    return Card(
      margin: const EdgeInsets.only(top: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: AppColors.skyBlue, size: 20),
                const SizedBox(width: 8),
                Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 12),
            Text(text, style: Theme.of(context).textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }

  Widget _InfoRow(String label, String value) {
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
