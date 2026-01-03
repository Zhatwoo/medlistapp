import 'package:flutter/material.dart';
import 'package:medlistapp/models/stockitem.dart';
import 'package:medlistapp/models/medication.dart';
import 'package:medlistapp/services/expiryservice.dart';
import 'package:medlistapp/services/medicationservice.dart';
import 'package:medlistapp/services/stockservice.dart';
import 'package:medlistapp/widgets/expiryalertcard.dart';
import 'package:medlistapp/screens/medicationdetailpage.dart';
import 'package:medlistapp/screens/barcodescannerpage.dart';
import 'package:medlistapp/utils/appcolors.dart';
import 'package:intl/intl.dart';

/// Quick Expiry Check Page (Section 5.4)
/// One-tap expiry check - Scan medication → instant expiry status
class QuickExpiryCheckPage extends StatefulWidget {
  const QuickExpiryCheckPage({super.key});

  @override
  State<QuickExpiryCheckPage> createState() => _QuickExpiryCheckPageState();
}

class _QuickExpiryCheckPageState extends State<QuickExpiryCheckPage> {
  final ExpiryService _expiryService = ExpiryService();
  final MedicationService _medicationService = MedicationService();
  final StockService _stockService = StockService();

  List<StockItem> _expiringItems = [];
  List<StockItem> _expiredItems = [];
  bool _isLoading = false;
  String _selectedTimeRange = '30';
  final List<String> _timeRanges = ['7', '30', '60', '90'];

  @override
  void initState() {
    super.initState();
    _performQuickCheck();
  }

  /// One-tap expiry check - instantly checks all medications
  Future<void> _performQuickCheck() async {
    setState(() => _isLoading = true);
    try {
      final days = int.parse(_selectedTimeRange);
      final expiring = await _expiryService.getExpiringMedications(days);
      final expired = await _expiryService.getExpiredMedications();

      setState(() {
        _expiringItems = expiring;
        _expiredItems = expired;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error checking expiry: $e')),
        );
      }
    }
  }

  /// Scan medication and show instant expiry status
  Future<void> _scanAndCheck() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const BarcodeScannerPage(),
      ),
    );

    if (result != null && result is String) {
      // Search for medication by barcode/name
      try {
        final medications = await _medicationService.searchMedications(result);
        if (medications.isNotEmpty) {
          final medication = medications.first;
          if (medication.id != null) {
            final stockItems = await _stockService.getStockItemsByMedicationId(medication.id!);
            if (stockItems.isNotEmpty) {
              _showInstantExpiryStatus(medication, stockItems);
            } else {
              _showNoStockDialog(medication);
            }
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e')),
          );
        }
      }
    }
  }

  void _showInstantExpiryStatus(Medication medication, List<StockItem> stockItems) {
    final expiredItems = stockItems.where((item) => item.isExpired).toList();
    final expiringItems = stockItems.where((item) => item.isExpiringSoon(30)).toList();
    final safeItems = stockItems
        .where((item) => !item.isExpired && !item.isExpiringSoon(30))
        .toList();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(medication.tradeName),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (expiredItems.isNotEmpty) ...[
                  const Text(
                    '❌ EXPIRED',
                    style: TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...expiredItems.map((item) => Text(
                        'Batch: ${item.batchNumber ?? 'N/A'} - Expired: ${DateFormat('MMM dd, yyyy').format(item.expiryDate)}',
                        style: const TextStyle(color: Colors.red),
                      )),
                  const SizedBox(height: 16),
                ],
                if (expiringItems.isNotEmpty) ...[
                  const Text(
                    '⚠️ EXPIRING SOON',
                    style: TextStyle(
                      color: Colors.orange,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...expiringItems.map((item) => Text(
                        'Batch: ${item.batchNumber ?? 'N/A'} - Expires: ${DateFormat('MMM dd, yyyy').format(item.expiryDate)} (${item.daysUntilExpiry} days)',
                        style: const TextStyle(color: Colors.orange),
                      )),
                  const SizedBox(height: 16),
                ],
                if (safeItems.isNotEmpty) ...[
                  const Text(
                    '✅ SAFE',
                    style: TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...safeItems.map((item) => Text(
                        'Batch: ${item.batchNumber ?? 'N/A'} - Expires: ${DateFormat('MMM dd, yyyy').format(item.expiryDate)}',
                        style: const TextStyle(color: Colors.green),
                      )),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                if (medication.id != null) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => MedicationDetailPage(medicationId: medication.id!),
                    ),
                  );
                }
              },
              child: const Text('View Details'),
            ),
          ],
        );
      },
    );
  }

  void _showNoStockDialog(Medication medication) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(medication.tradeName),
        content: const Text('No stock items found for this medication.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
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
        title: const Text('Quick Expiry Check'),
        backgroundColor: AppColors.skyBlue,
        foregroundColor: AppColors.pureWhite,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_scanner),
            tooltip: 'Scan Medication',
            onPressed: _scanAndCheck,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: _performQuickCheck,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Time Range Filter
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const Text('Expiring within: '),
                      ..._timeRanges.map((range) => Padding(
                            padding: const EdgeInsets.only(left: 8),
                            child: ChoiceChip(
                              label: Text('$range days'),
                              selected: _selectedTimeRange == range,
                              onSelected: (selected) {
                                if (selected) {
                                  setState(() => _selectedTimeRange = range);
                                  _performQuickCheck();
                                }
                              },
                            ),
                          )),
                    ],
                  ),
                ),
                // Summary Cards
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: Card(
                          color: Colors.red.withOpacity(0.1),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              children: [
                                const Icon(Icons.error, color: Colors.red, size: 32),
                                const SizedBox(height: 8),
                                Text(
                                  '${_expiredItems.length}',
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.red,
                                  ),
                                ),
                                const Text('Expired'),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Card(
                          color: Colors.orange.withOpacity(0.1),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              children: [
                                const Icon(Icons.warning, color: Colors.orange, size: 32),
                                const SizedBox(height: 8),
                                Text(
                                  '${_expiringItems.length}',
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.orange,
                                  ),
                                ),
                                Text('Expiring in $_selectedTimeRange days'),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // Expired Items
                if (_expiredItems.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        const Icon(Icons.error, color: Colors.red),
                        const SizedBox(width: 8),
                        Text(
                          'Expired Items (${_expiredItems.length})',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Colors.red,
                              ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    flex: 1,
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _expiredItems.length,
                      itemBuilder: (context, index) {
                        return FutureBuilder<Medication?>(
                          future: _medicationService.getMedicationById(_expiredItems[index].medicationId),
                          builder: (context, snapshot) {
                            if (!snapshot.hasData) {
                              return const SizedBox.shrink();
                            }
                            return ExpiryAlertCard(
                              stockItem: _expiredItems[index],
                              medication: snapshot.data!,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => MedicationDetailPage(
                                      medicationId: snapshot.data!.id!,
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
                // Expiring Items
                if (_expiringItems.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        const Icon(Icons.warning, color: Colors.orange),
                        const SizedBox(width: 8),
                        Text(
                          'Expiring Soon (${_expiringItems.length})',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Colors.orange,
                              ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    flex: _expiredItems.isEmpty ? 1 : 1,
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _expiringItems.length,
                      itemBuilder: (context, index) {
                        return FutureBuilder<Medication?>(
                          future: _medicationService.getMedicationById(_expiringItems[index].medicationId),
                          builder: (context, snapshot) {
                            if (!snapshot.hasData) {
                              return const SizedBox.shrink();
                            }
                            return ExpiryAlertCard(
                              stockItem: _expiringItems[index],
                              medication: snapshot.data!,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => MedicationDetailPage(
                                      medicationId: snapshot.data!.id!,
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
                // No items found
                if (_expiredItems.isEmpty && _expiringItems.isEmpty)
                  Expanded(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.check_circle,
                            size: 64,
                            color: AppColors.successGreen,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'All medications are safe!',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'No expired or expiring items found',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: AppColors.mediumGray,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
    );
  }
}

