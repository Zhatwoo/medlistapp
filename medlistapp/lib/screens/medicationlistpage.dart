import 'package:flutter/material.dart';
import 'package:medlistapp/models/medication.dart';
import 'package:medlistapp/widgets/medicationcard.dart';
import 'package:medlistapp/widgets/searchbarwidget.dart';
import 'package:medlistapp/widgets/filterchipwidget.dart';
import 'package:medlistapp/services/medicationservice.dart';
import 'package:medlistapp/services/stockservice.dart';
import 'package:medlistapp/screens/medicationdetailpage.dart';
import 'package:medlistapp/utils/appcolors.dart';

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
  String _selectedFilter = 'All';
  final List<String> _filters = ['All', 'Tablet', 'Solution', 'Capsule', 'Injection'];

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
      _applyFilter();
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading medications: $e')),
        );
      }
    }
  }

  void _applyFilter() {
    if (_selectedFilter == 'All') {
      setState(() => _filteredMedications = _medications);
    } else {
      setState(() {
        _filteredMedications = _medications
            .where((m) => m.form.toLowerCase().contains(_selectedFilter.toLowerCase()))
            .toList();
      });
    }
  }

  void _onSearchChanged(String query) {
    if (query.isEmpty) {
      setState(() => _filteredMedications = _medications);
    } else {
      setState(() {
        _filteredMedications = _medications
            .where((m) =>
                m.tradeName.toLowerCase().contains(query.toLowerCase()) ||
                m.activeIngredient.toLowerCase().contains(query.toLowerCase()) ||
                m.company.toLowerCase().contains(query.toLowerCase()))
            .toList();
      });
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
                // Filter Chips (inspired by design)
                SizedBox(
                  height: 44,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _filters.length,
                    itemBuilder: (context, index) {
                      final filter = _filters[index];
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChipWidget(
                          label: filter,
                          isSelected: _selectedFilter == filter,
                          onTap: () {
                            setState(() => _selectedFilter = filter);
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
