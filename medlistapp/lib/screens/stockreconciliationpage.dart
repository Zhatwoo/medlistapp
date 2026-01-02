import 'package:flutter/material.dart';
import 'package:medlistapp/models/stockitem.dart';
import 'package:medlistapp/models/medication.dart';
import 'package:medlistapp/models/stockadjustmentreason.dart';
import 'package:medlistapp/services/stockservice.dart';
import 'package:medlistapp/services/medicationservice.dart';
import 'package:medlistapp/screens/addeditmedicationpage.dart';
import 'package:medlistapp/screens/medicationdetailpage.dart';
import 'package:medlistapp/utils/appcolors.dart';
import 'package:medlistapp/utils/constants.dart';
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

  Future<void> _updateQuantity(StockItem stockItem, int newQuantity, StockAdjustmentReason? reason, String? notes) async {
    try {
      if (reason != null) {
        await _stockService.adjustStock(stockItem.id!, newQuantity, reason, notes: notes);
      } else {
        final updated = stockItem.copyWith(quantity: newQuantity);
        await _stockService.updateStockItem(updated);
      }
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
    final quantityController = TextEditingController(text: stockItem.quantity.toString());
    final notesController = TextEditingController();
    StockAdjustmentReason? selectedReason;
    final dateFormat = DateFormat('MMM dd, yyyy');
    
    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text('Update Stock Quantity'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Expected quantity display
                if (stockItem.expectedQuantity != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.softBlue,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Expected: ${stockItem.expectedQuantity}',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        Text(
                          'Actual: ${stockItem.quantity}',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Variance indicator
                  if (stockItem.variance != null) ...[
                    Chip(
                      label: Text(
                        stockItem.variance! > 0
                            ? '+${stockItem.variance} (Over)'
                            : stockItem.variance! < 0
                                ? '${stockItem.variance} (Under)'
                                : '0 (Exact)',
                        style: const TextStyle(color: Colors.white, fontSize: 12),
                      ),
                      backgroundColor: stockItem.variance! > 0
                          ? Colors.green
                          : stockItem.variance! < 0
                              ? Colors.red
                              : Colors.blue,
                    ),
                    const SizedBox(height: 12),
                  ],
                ],
                // New quantity input
                TextField(
                  controller: quantityController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'New Quantity',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Reason selection
                Text(
                  'Reason for Adjustment',
                  style: Theme.of(context).textTheme.labelMedium,
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<StockAdjustmentReason>(
                  value: selectedReason,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    hintText: 'Select reason (optional)',
                  ),
                  items: StockAdjustmentReason.values.map((reason) {
                    return DropdownMenuItem(
                      value: reason,
                      child: Text(reason.displayName),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setDialogState(() {
                      selectedReason = value;
                    });
                  },
                ),
                const SizedBox(height: 16),
                // Notes field
                TextField(
                  controller: notesController,
                  decoration: InputDecoration(
                    labelText: 'Notes (optional)',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  maxLines: 2,
                ),
              ],
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
                final newQuantity = int.tryParse(quantityController.text);
                if (newQuantity != null && newQuantity >= 0) {
                  _updateQuantity(
                    stockItem,
                    newQuantity,
                    selectedReason,
                    notesController.text.isEmpty ? null : notesController.text,
                  );
                  Navigator.pop(context);
                }
              },
              child: const Text('Update'),
            ),
          ],
        ),
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
                              Row(
                                children: [
                                  Text('Quantity: ${stockItem.quantity}'),
                                  if (stockItem.expectedQuantity != null) ...[
                                    const SizedBox(width: 8),
                                    Text(
                                      '(Expected: ${stockItem.expectedQuantity})',
                                      style: TextStyle(
                                        fontSize: 12,
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
                              Text('Expiry: ${dateFormat.format(stockItem.expiryDate)}'),
                              if (stockItem.manufacturingDate != null)
                                Text('Manufactured: ${dateFormat.format(stockItem.manufacturingDate!)}'),
                              if (stockItem.batchNumber != null)
                                Text('Batch: ${stockItem.batchNumber}'),
                              const SizedBox(height: 4),
                              Wrap(
                                spacing: 4,
                                children: [
                                  if (isExpired || isExpiringSoon)
                                    Chip(
                                      label: Text(
                                        isExpired
                                            ? 'Expired'
                                            : '${stockItem.daysUntilExpiry} days left',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 11,
                                        ),
                                      ),
                                      backgroundColor: isExpired ? Colors.red : Colors.orange,
                                      padding: EdgeInsets.zero,
                                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                    ),
                                  if (stockItem.isOverstocked)
                                    Chip(
                                      label: const Text(
                                        'Overstocked',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 11,
                                        ),
                                      ),
                                      backgroundColor: Colors.orange,
                                      padding: EdgeInsets.zero,
                                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                    ),
                                  if (stockItem.variance != null && stockItem.variance! < 0)
                                    Chip(
                                      label: Text(
                                        'Under: ${stockItem.variance!.abs()}',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 11,
                                        ),
                                      ),
                                      backgroundColor: Colors.red,
                                      padding: EdgeInsets.zero,
                                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                    ),
                                  if (stockItem.variance != null && stockItem.variance! > 0 && !stockItem.isOverstocked)
                                    Chip(
                                      label: Text(
                                        'Over: +${stockItem.variance}',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 11,
                                        ),
                                      ),
                                      backgroundColor: Colors.green,
                                      padding: EdgeInsets.zero,
                                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                    ),
                                ],
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
