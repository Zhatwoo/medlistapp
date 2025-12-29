import 'package:flutter/material.dart';
import 'package:medlistapp/models/stock_item.dart';
import 'package:medlistapp/models/medication.dart';
import 'package:medlistapp/services/stock_service.dart';
import 'package:medlistapp/services/medication_service.dart';
import 'package:medlistapp/screens/add_edit_medication_page.dart';
import 'package:medlistapp/screens/medication_detail_page.dart';
import 'package:medlistapp/utils/app_colors.dart';
import 'package:intl/intl.dart';

class StockReconciliationPage extends StatefulWidget {
  const StockReconciliationPage({super.key});

  @override
  State<StockReconciliationPage> createState() => _StockReconciliationPageState();
}

class _StockReconciliationPageState extends State<StockReconciliationPage> {
  final StockService _stockService = StockService();
  final MedicationService _medicationService = MedicationService();

  List<StockItem> _stockItems = [];
  Map<int, Medication> _medications = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStockItems();
  }

  Future<void> _loadStockItems() async {
    setState(() => _isLoading = true);
    try {
      final items = await _stockService.getAllStockItems();
      final medications = <int, Medication>{};

      for (final item in items) {
        final medication = await _medicationService.getMedicationById(item.medicationId);
        if (medication != null) {
          medications[item.medicationId] = medication;
        }
      }

      setState(() {
        _stockItems = items;
        _medications = medications;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading stock: $e')),
        );
      }
    }
  }

  Future<void> _updateQuantity(StockItem stockItem, int newQuantity) async {
    try {
      final updated = stockItem.copyWith(quantity: newQuantity);
      await _stockService.updateStockItem(updated);
      await _loadStockItems();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Stock updated successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating stock: $e')),
        );
      }
    }
  }

  Future<void> _showQuantityDialog(StockItem stockItem) async {
    final controller = TextEditingController(text: stockItem.quantity.toString());
    
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text('Update Quantity'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: 'New Quantity',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.skyBlue,
              foregroundColor: AppColors.pureWhite,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () {
              final newQuantity = int.tryParse(controller.text);
              if (newQuantity != null && newQuantity >= 0) {
                _updateQuantity(stockItem, newQuantity);
                Navigator.pop(context);
              }
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.aliceBlue,
      appBar: AppBar(
        title: const Text('Stock Reconciliation'),
        backgroundColor: AppColors.skyBlue,
        foregroundColor: AppColors.pureWhite,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _stockItems.isEmpty
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
              : RefreshIndicator(
                  onRefresh: _loadStockItems,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _stockItems.length,
                    itemBuilder: (context, index) {
                      final stockItem = _stockItems[index];
                      final medication = _medications[stockItem.medicationId];
                      final dateFormat = DateFormat('MMM dd, yyyy');
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
                          leading: Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: AppColors.softBlue,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.inventory,
                              color: AppColors.skyBlue,
                            ),
                          ),
                          title: Text(
                            medication?.tradeName ?? 'Unknown',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Text('Quantity: ${stockItem.quantity}'),
                              Text('Expiry: ${dateFormat.format(stockItem.expiryDate)}'),
                              if (stockItem.batchNumber != null)
                                Text('Batch: ${stockItem.batchNumber}'),
                              if (isExpired || isExpiringSoon)
                                Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Chip(
                                    label: Text(
                                      isExpired
                                          ? 'Expired'
                                          : '${stockItem.daysUntilExpiry} days left',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                      ),
                                    ),
                                    backgroundColor: isExpired ? Colors.red : Colors.orange,
                                    padding: EdgeInsets.zero,
                                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  ),
                                ),
                            ],
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.edit),
                            color: AppColors.skyBlue,
                            onPressed: () => _showQuantityDialog(stockItem),
                          ),
                          onTap: () {
                            if (medication != null) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => MedicationDetailPage(
                                    medicationId: medication.id!,
                                  ),
                                ),
                              );
                            }
                          },
                        ),
                      );
                    },
                  ),
                ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.skyBlue,
        foregroundColor: AppColors.pureWhite,
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AddEditMedicationPage(),
            ),
          ).then((_) => _loadStockItems());
        },
        icon: const Icon(Icons.add),
        label: const Text('Add Stock'),
      ),
    );
  }
}
