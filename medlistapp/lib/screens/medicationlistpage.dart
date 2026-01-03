import 'package:flutter/material.dart';
import 'package:medlistapp/models/medication.dart';
import 'package:medlistapp/widgets/medicationcard.dart';
import 'package:medlistapp/widgets/searchbarwidget.dart';
import 'package:medlistapp/widgets/filterchipwidget.dart';
import 'package:medlistapp/services/medicationservice.dart';
import 'package:medlistapp/services/stockservice.dart';
import 'package:medlistapp/screens/medicationdetailpage.dart';
import 'package:medlistapp/utils/appcolors.dart';
import 'package:medlistapp/utils/constants.dart';

class MedicationListPage extends StatefulWidget {
  final String? searchQuery;

  const MedicationListPage({super.key, this.searchQuery});

  @override
  State<MedicationListPage> createState() => _MedicationListPageState();
}

class _MedicationListPageState extends State<MedicationListPage> {
  final MedicationService _medicationService = MedicationService();
  final StockService _stockService = StockService();
  final TextEditingController _searchController = TextEditingController();
  
  List<Medication> _medications = [];
  List<Medication> _filteredMedications = [];
  bool _isLoading = true;
  String _selectedFormFilter = 'All';
  String? _selectedStorageFilter;
  String? _selectedStockLevelFilter;
  final List<String> _formFilters = ['All', 'Tablet', 'Solution', 'Capsule', 'Injection'];
  final List<String> _storageFilters = ['All', 'Room Temperature', 'Refrigerated', 'Frozen', 'Cool & Dry'];
  final List<String> _stockLevelFilters = ['All', 'In Stock', 'Low Stock', 'Out of Stock', 'Overstocked'];

  @override
  void initState() {
    super.initState();
    if (widget.searchQuery != null) {
      _searchController.text = widget.searchQuery!;
    }
    _loadMedications();
  }

  Future<void> _loadMedications() async {
    setState(() => _isLoading = true);
    try {
      final medications = widget.searchQuery != null
          ? await _medicationService.searchMedications(widget.searchQuery!)
          : await _medicationService.getAllMedications();
      
      setState(() {
        _medications = medications;
        _filteredMedications = medications;
        _isLoading = false;
      });
      await _applyFilter();
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading medications: $e')),
        );
      }
    }
  }

  Future<void> _applyFilter() async {
    List<Medication> filtered = List.from(_medications);

    // Apply form filter
    if (_selectedFormFilter != 'All') {
      filtered = filtered
          .where((m) => m.form.toLowerCase().contains(_selectedFormFilter.toLowerCase()))
          .toList();
    }

    // Apply storage condition filter
    if (_selectedStorageFilter != null && _selectedStorageFilter != 'All') {
      filtered = filtered
          .where((m) => m.storageCondition != null &&
              m.storageCondition!.toLowerCase().contains(_selectedStorageFilter!.toLowerCase()))
          .toList();
    }

    // Apply stock level filter
    if (_selectedStockLevelFilter != null && _selectedStockLevelFilter != 'All') {
      final stockFiltered = <Medication>[];
      for (final med in filtered) {
        if (med.id == null) continue;
        final totalStock = await _stockService.getTotalStockQuantity(med.id!);
        final isLowStock = await _stockService.isStockLow(med.id!, AppConstants.defaultLowStockThreshold);
        final isOverstocked = await _stockService.isOverstocked(med.id!);

        bool matches = false;
        switch (_selectedStockLevelFilter) {
          case 'In Stock':
            matches = totalStock > 0 && !isLowStock && !isOverstocked;
            break;
          case 'Low Stock':
            matches = isLowStock && totalStock > 0;
            break;
          case 'Out of Stock':
            matches = totalStock == 0;
            break;
          case 'Overstocked':
            matches = isOverstocked;
            break;
        }
        if (matches) stockFiltered.add(med);
      }
      filtered = stockFiltered;
    }

    setState(() => _filteredMedications = filtered);
  }

  void _onSearchChanged(String query) {
    if (query.isEmpty) {
      _applyFilter();
    } else {
      setState(() {
        _filteredMedications = _medications
            .where((m) =>
                m.tradeName.toLowerCase().contains(query.toLowerCase()) ||
                m.activeIngredient.toLowerCase().contains(query.toLowerCase()) ||
                m.company.toLowerCase().contains(query.toLowerCase()))
            .toList();
      });
      _applyFilter();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.aliceBlue,
      appBar: AppBar(
        title: const Text('All Medications'),
        backgroundColor: AppColors.skyBlue,
        foregroundColor: AppColors.pureWhite,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Search Bar
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                  child: SearchBarWidget(
                    controller: _searchController,
                    hintText: 'Search medications...',
                    onChanged: _onSearchChanged,
                  ),
                ),
                // Filter Chips - Form
                SizedBox(
                  height: 44,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _formFilters.length,
                    itemBuilder: (context, index) {
                      final filter = _formFilters[index];
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChipWidget(
                          label: filter,
                          isSelected: _selectedFormFilter == filter,
                          onTap: () {
                            setState(() => _selectedFormFilter = filter);
                            _applyFilter();
                          },
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 8),
                // Filter Chips - Storage Condition
                SizedBox(
                  height: 44,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _storageFilters.length,
                    itemBuilder: (context, index) {
                      final filter = _storageFilters[index];
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChipWidget(
                          label: filter,
                          isSelected: _selectedStorageFilter == filter,
                          onTap: () {
                            setState(() {
                              _selectedStorageFilter = filter == 'All' ? null : filter;
                            });
                            _applyFilter();
                          },
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 8),
                // Filter Chips - Stock Level
                SizedBox(
                  height: 44,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _stockLevelFilters.length,
                    itemBuilder: (context, index) {
                      final filter = _stockLevelFilters[index];
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChipWidget(
                          label: filter,
                          isSelected: _selectedStockLevelFilter == filter,
                          onTap: () {
                            setState(() {
                              _selectedStockLevelFilter = filter == 'All' ? null : filter;
                            });
                            _applyFilter();
                          },
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 8),
                // Results Count
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      Text(
                        '${_filteredMedications.length} medications found',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.mediumGray,
                        ),
                      ),
                    ],
                  ),
                ),
                // Medication List
                Expanded(
                  child: _filteredMedications.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.medication_outlined,
                                size: 64,
                                color: AppColors.mediumGray.withOpacity(0.5),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No medications found',
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: AppColors.mediumGray,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Try adjusting your search or filters',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: AppColors.mediumGray,
                                ),
                              ),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _loadMedications,
                          child: ListView.builder(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            itemCount: _filteredMedications.length,
                            itemBuilder: (context, index) {
                              final medication = _filteredMedications[index];
                              return FutureBuilder<int>(
                                future: _stockService.getTotalStockQuantity(medication.id!),
                                builder: (context, snapshot) {
                                  return MedicationCard(
                                    medication: medication,
                                    stockQuantity: snapshot.data,
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => MedicationDetailPage(
                                            medicationId: medication.id!,
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
            ),
    );
  }
}
