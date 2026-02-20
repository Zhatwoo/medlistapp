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
  String _selectedStockLevelFilter = 'All';
  final List<String> _formFilters = ['All', 'Tablet', 'Solution', 'Capsule', 'Injection'];
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

  /// Form filter matching for MOH data (e.g. "Solution for infusion", "Injection/Solution for").
  bool _matchesFormFilter(Medication m, String filter) {
    final form = m.form.toLowerCase();
    switch (filter) {
      case 'Tablet':
        return form.contains('tablet');
      case 'Solution':
        return form.contains('solution') && !form.contains('injection') && !form.contains('infusion');
      case 'Capsule':
        return form.contains('capsule');
      case 'Injection':
        return form.contains('injection') || form.contains('infusion') || form.contains('intravenous');
      default:
        return true;
    }
  }

  Future<void> _applyFilter() async {
    List<Medication> filtered = List.from(_medications);

    // 1. Apply search filter
    final query = _searchController.text.trim().toLowerCase();
    if (query.isNotEmpty) {
      filtered = filtered
          .where((m) =>
              m.tradeName.toLowerCase().contains(query) ||
              m.activeIngredient.toLowerCase().contains(query) ||
              m.company.toLowerCase().contains(query))
          .toList();
    }

    // 2. Apply form filter with MOH mapping
    if (_selectedFormFilter != 'All') {
      filtered = filtered.where((m) => _matchesFormFilter(m, _selectedFormFilter)).toList();
    }

    // 3. Apply stock level filter (batch)
    if (_selectedStockLevelFilter != 'All') {
      final ids = filtered.where((m) => m.id != null).map((m) => m.id!).toList();
      if (ids.isNotEmpty) {
        final summary = await _stockService.getStockSummaryForMedications(
          ids,
          lowStockThreshold: AppConstants.defaultLowStockThreshold,
        );
        filtered = filtered.where((med) {
          if (med.id == null) return false;
          final s = summary[med.id!];
          if (s == null) return _selectedStockLevelFilter == 'Out of Stock';
          switch (_selectedStockLevelFilter) {
            case 'In Stock':
              return s.total > 0 && !s.isLowStock && !s.isOverstocked;
            case 'Low Stock':
              return s.isLowStock && s.total > 0;
            case 'Out of Stock':
              return s.total == 0;
            case 'Overstocked':
              return s.isOverstocked;
            default:
              return true;
          }
        }).toList();
      }
    }

    if (mounted) setState(() => _filteredMedications = filtered);
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
                    onChanged: (_) => _applyFilter(),
                    onClear: () => _applyFilter(),
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
                            setState(() => _selectedStockLevelFilter = filter);
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
