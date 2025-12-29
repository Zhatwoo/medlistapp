import 'package:flutter/material.dart';
import 'package:medlistapp/services/medication_service.dart';
import 'package:medlistapp/services/mims_service.dart';
import 'package:medlistapp/screens/medication_list_page.dart';
import 'package:medlistapp/utils/app_colors.dart';

class CategoriesPage extends StatefulWidget {
  const CategoriesPage({super.key});

  @override
  State<CategoriesPage> createState() => _CategoriesPageState();
}

class _CategoriesPageState extends State<CategoriesPage> {
  final MedicationService _medicationService = MedicationService();
  final MimsService _mimsService = MimsService();

  List<String> _companies = [];
  List<String> _forms = [];
  List<String> _therapeuticClasses = [];
  Map<String, String> _categoryMappings = {}; // Custom category mappings
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    setState(() => _isLoading = true);
    try {
      final companies = await _medicationService.getUniqueCompanies();
      final forms = await _medicationService.getUniqueForms();
      
      // Load therapeutic classes from MIMS cache
      final mimsData = await _mimsService.searchDrug(''); // Empty search to get cached data
      final therapeuticClasses = mimsData
          .where((drug) => drug.therapeuticClass != null)
          .map((drug) => drug.therapeuticClass!)
          .toSet()
          .toList();
      therapeuticClasses.sort();

      setState(() {
        _companies = companies.take(20).toList(); // Limit to first 20
        _forms = forms;
        _therapeuticClasses = therapeuticClasses;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading categories: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.aliceBlue,
      appBar: AppBar(
        title: const Text('Categories'),
        backgroundColor: AppColors.skyBlue,
        foregroundColor: AppColors.pureWhite,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : DefaultTabController(
              length: 3,
              child: Column(
                children: [
                  TabBar(
                    labelColor: AppColors.skyBlue,
                    unselectedLabelColor: AppColors.mediumGray,
                    indicatorColor: AppColors.skyBlue,
                    tabs: const [
                      Tab(text: 'By Form'),
                      Tab(text: 'By Company'),
                      Tab(text: 'Therapeutic Class'),
                    ],
                  ),
                  Expanded(
                    child: TabBarView(
                      children: [
                        _buildFormsTab(),
                        _buildCompaniesTab(),
                        _buildTherapeuticClassesTab(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildFormsTab() {
    return _forms.isEmpty
        ? Center(
            child: Text(
              'No forms available',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppColors.mediumGray,
              ),
            ),
          )
        : ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _forms.length,
            itemBuilder: (context, index) {
              final form = _forms[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: ListTile(
                  leading: const Icon(Icons.medication, color: AppColors.skyBlue),
                  title: Text(form),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => MedicationListPage(),
                      ),
                    );
                  },
                ),
              );
            },
          );
  }

  Widget _buildCompaniesTab() {
    return _companies.isEmpty
        ? Center(
            child: Text(
              'No companies available',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppColors.mediumGray,
              ),
            ),
          )
        : ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _companies.length,
            itemBuilder: (context, index) {
              final company = _companies[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: ListTile(
                  leading: const Icon(Icons.business, color: AppColors.skyBlue),
                  title: Text(company),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => MedicationListPage(),
                      ),
                    );
                  },
                ),
              );
            },
          );
  }

  Widget _buildTherapeuticClassesTab() {
    return _therapeuticClasses.isEmpty
        ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.category_outlined,
                  size: 64,
                  color: AppColors.mediumGray.withOpacity(0.5),
                ),
                const SizedBox(height: 16),
                Text(
                  'No therapeutic classes available',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.mediumGray,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'MIMS data will populate therapeutic classes',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.mediumGray,
                  ),
                ),
              ],
            ),
          )
        : ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _therapeuticClasses.length,
            itemBuilder: (context, index) {
              final therapeuticClass = _therapeuticClasses[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: ListTile(
                  leading: const Icon(Icons.medical_services, color: AppColors.skyBlue),
                  title: Text(therapeuticClass),
                  subtitle: const Text('MIMS Classification'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => MedicationListPage(),
                      ),
                    );
                  },
                ),
              );
            },
          );
  }
}

