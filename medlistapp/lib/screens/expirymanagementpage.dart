import 'package:flutter/material.dart';
import 'package:medlistapp/models/stockitem.dart';
import 'package:medlistapp/models/medication.dart';
import 'package:medlistapp/services/expiryservice.dart';
import 'package:medlistapp/services/medicationservice.dart';
import 'package:medlistapp/widgets/expiryalertcard.dart';
import 'package:medlistapp/widgets/filterchipwidget.dart';
import 'package:medlistapp/screens/medicationdetailpage.dart';
import 'package:medlistapp/utils/appcolors.dart';

class ExpiryManagementPage extends StatefulWidget {
  const ExpiryManagementPage({super.key});

  @override
  State<ExpiryManagementPage> createState() => _ExpiryManagementPageState();
}

class _ExpiryManagementPageState extends State<ExpiryManagementPage>
    with SingleTickerProviderStateMixin {
  final ExpiryService _expiryService = ExpiryService();
  final MedicationService _medicationService = MedicationService();

  late TabController _tabController;
  List<StockItem> _expiringItems = [];
  List<StockItem> _expiredItems = [];
  bool _isLoading = true;
  String _selectedFilter = '30';
  final List<String> _filters = ['7', '30', '90'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadExpiryData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadExpiryData() async {
    setState(() => _isLoading = true);
    try {
      final expiring = await _expiryService.getExpiringIn30Days();
      final expired = await _expiryService.getExpiredMedications();
      
      setState(() {
        _expiringItems = expiring;
        _expiredItems = expired;
        _isLoading = false;
      });
      _applyFilter();
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading expiry data: $e')),
        );
      }
    }
  }

  void _applyFilter() {
    final days = int.parse(_selectedFilter);
    _expiryService.getExpiringMedications(days).then((items) {
      setState(() => _expiringItems = items);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.aliceBlue,
      appBar: AppBar(
        title: const Text('Expiry Management'),
        backgroundColor: AppColors.skyBlue,
        foregroundColor: AppColors.pureWhite,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.pureWhite,
          unselectedLabelColor: AppColors.pureWhite.withOpacity(0.7),
          indicatorColor: AppColors.pureWhite,
          tabs: const [
            Tab(text: 'Expiring Soon'),
            Tab(text: 'Expired'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildExpiringTab(),
                _buildExpiredTab(),
              ],
            ),
    );
  }

  Widget _buildExpiringTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Filter by days',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              Row(
                children: _filters.map((filter) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChipWidget(
                      label: '$filter days',
                      isSelected: _selectedFilter == filter,
                      onTap: () {
                        setState(() => _selectedFilter = filter);
                        _applyFilter();
                      },
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
        Expanded(
          child: _expiringItems.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.check_circle_outline,
                        size: 64,
                        color: AppColors.mediumGray.withOpacity(0.5),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No medications expiring soon',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: AppColors.mediumGray,
                        ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadExpiryData,
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: _expiringItems.length,
                    itemBuilder: (context, index) {
                      final stockItem = _expiringItems[index];
                      return FutureBuilder<Medication?>(
                        future: _medicationService.getMedicationById(stockItem.medicationId),
                        builder: (context, snapshot) {
                          return ExpiryAlertCard(
                            stockItem: stockItem,
                            medication: snapshot.data,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => MedicationDetailPage(
                                    medicationId: stockItem.medicationId,
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
        ),
      ],
    );
  }

  Widget _buildExpiredTab() {
    return _expiredItems.isEmpty
        ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.check_circle_outline,
                  size: 64,
                  color: AppColors.mediumGray.withOpacity(0.5),
                ),
                const SizedBox(height: 16),
                Text(
                  'No expired medications',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.mediumGray,
                  ),
                ),
              ],
            ),
          )
        : RefreshIndicator(
            onRefresh: _loadExpiryData,
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _expiredItems.length,
              itemBuilder: (context, index) {
                final stockItem = _expiredItems[index];
                return FutureBuilder<Medication?>(
                  future: _medicationService.getMedicationById(stockItem.medicationId),
                  builder: (context, snapshot) {
                    return ExpiryAlertCard(
                      stockItem: stockItem,
                      medication: snapshot.data,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => MedicationDetailPage(
                              medicationId: stockItem.medicationId,
                            ),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          );
  }
}
