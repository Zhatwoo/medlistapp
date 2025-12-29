import 'package:flutter/material.dart';
import 'package:medlistapp/models/medication.dart';
import 'package:medlistapp/models/stock_item.dart';
import 'package:medlistapp/services/medication_service.dart';
import 'package:medlistapp/services/stock_service.dart';
import 'package:medlistapp/utils/app_colors.dart';
import 'package:medlistapp/widgets/stock_status_indicator.dart';
import 'package:medlistapp/screens/add_edit_medication_page.dart';
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
  
  Medication? _medication;
  List<StockItem> _stockItems = [];
  int _totalStock = 0;
  bool _isLoading = true;

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
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading medication: $e')),
        );
      }
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
                  title: Text(
                    'Quantity: ${stockItem.quantity}',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 8),
                      Text('Expiry: ${dateFormat.format(stockItem.expiryDate)}'),
                      if (stockItem.batchNumber != null)
                        Text('Batch: ${stockItem.batchNumber}'),
                      if (stockItem.location != null)
                        Text('Location: ${stockItem.location}'),
                    ],
                  ),
                  trailing: isExpired
                      ? Chip(
                          label: const Text('Expired', style: TextStyle(color: Colors.white)),
                          backgroundColor: Colors.red,
                        )
                      : isExpiringSoon
                          ? Chip(
                              label: Text('${stockItem.daysUntilExpiry} days left'),
                              backgroundColor: Colors.orange,
                            )
                          : null,
                ),
              );
            },
          );
  }

  Widget _buildMedicalTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Medical Information',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              Text(
                'Indications',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                'Information from MIMS will be displayed here when integrated.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 24),
              Text(
                'Contraindications',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                'Information from MIMS will be displayed here when integrated.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 24),
              Text(
                'Dosage',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                'Information from MIMS will be displayed here when integrated.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
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
