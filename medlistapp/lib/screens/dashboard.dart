import 'package:flutter/material.dart';
import 'package:medlistapp/widgets/dashboard_stat_card.dart';
import 'package:medlistapp/widgets/search_bar_widget.dart';
import 'package:medlistapp/widgets/expiry_alert_card.dart';
import 'package:medlistapp/widgets/category_grid_widget.dart';
import 'package:medlistapp/services/medication_service.dart';
import 'package:medlistapp/services/stock_service.dart';
import 'package:medlistapp/services/expiry_service.dart';
import 'package:medlistapp/services/verification_service.dart';
import 'package:medlistapp/services/audit_service.dart';
import 'package:medlistapp/services/interaction_service.dart';
import 'package:medlistapp/models/medication.dart';
import 'package:medlistapp/models/stock_item.dart';
import 'package:medlistapp/models/verification_result.dart';
import 'package:medlistapp/models/drug_interaction.dart';
import 'package:medlistapp/screens/medication_list_page.dart';
import 'package:medlistapp/screens/expiry_management_page.dart';
import 'package:medlistapp/screens/stock_reconciliation_page.dart';
import 'package:medlistapp/screens/categories_page.dart';
import 'package:medlistapp/screens/medication_verification_page.dart';
import 'package:medlistapp/utils/app_colors.dart';

class Dashboard extends StatefulWidget {
  const Dashboard({super.key});

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  final MedicationService _medicationService = MedicationService();
  final StockService _stockService = StockService();
  final ExpiryService _expiryService = ExpiryService();
  final VerificationService _verificationService = VerificationService();
  final AuditService _auditService = AuditService();
  final InteractionService _interactionService = InteractionService();
  final TextEditingController _searchController = TextEditingController();

  int _totalMedications = 0;
  int _totalStockItems = 0;
  int _expiringSoon = 0;
  int _lowStock = 0;
  int _recentVerifications = 0;
  int _mimsAccessCount = 0;
  int _interactionAlerts = 0;
  List<StockItem> _expiringItems = [];
  List<VerificationResult> _recentVerificationLogs = [];
  List<DrugInteraction> _recentInteractions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() => _isLoading = true);
    try {
      final medications = await _medicationService.getAllMedications();
      final stockItems = await _stockService.getAllStockItems();
      final expiringItems = await _expiryService.getExpiringIn30Days();
      final lowStockItems = await _stockService.getLowStockItems(10);
      final recentVerifications = await _verificationService.getRecentVerifications(limit: 5);
      final mimsLogs = await _auditService.getAuditLogs(actionType: 'mims_access');
      final recentInteractions = await _interactionService.getInteractionsForMedication('1'); // Sample

      setState(() {
        _totalMedications = medications.length;
        _totalStockItems = stockItems.length;
        _expiringSoon = expiringItems.length;
        _lowStock = lowStockItems.length;
        _expiringItems = expiringItems.take(5).toList();
        _recentVerifications = recentVerifications.length;
        _mimsAccessCount = mimsLogs.length;
        _recentVerificationLogs = recentVerifications;
        _interactionAlerts = recentInteractions.where((i) => 
          i.severity == InteractionSeverity.severe || 
          i.severity == InteractionSeverity.contraindicated
        ).length;
        _recentInteractions = recentInteractions.take(3).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading data: $e')),
        );
      }
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
      backgroundColor: AppColors.lightGray,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadDashboardData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header Section - Matching Image Design
                    Container(
                      padding: EdgeInsets.fromLTRB(
                        20, 
                        MediaQuery.of(context).padding.top + 20, 
                        20, 
                        30
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.skyBlue,
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(32),
                          bottomRight: Radius.circular(32),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              // White Avatar Circle
                              Container(
                                width: 60,
                                height: 60,
                                decoration: const BoxDecoration(
                                  color: AppColors.pureWhite,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.person,
                                  color: AppColors.skyBlue,
                                  size: 32,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Welcome Back...',
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: AppColors.pureWhite,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Your Name',
                                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                      color: AppColors.pureWhite,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 20,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          // Bell Icon
                          IconButton(
                            icon: const Icon(
                              Icons.notifications_outlined,
                              color: AppColors.pureWhite,
                              size: 24,
                            ),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const ExpiryManagementPage(),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    // Search Bar - Matching Image Design
                    SizedBox(height: MediaQuery.of(context).size.height * 0.02),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                      child: SearchBarWidget(
                        controller: _searchController,
                        hintText: 'Search....',
                        onChanged: (value) {
                          if (value.isNotEmpty) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => MedicationListPage(searchQuery: value),
                              ),
                            );
                          }
                        },
                      ),
                    ),
                    // Category Section - Matching Image Design
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(height: MediaQuery.of(context).size.height * 0.02),
                          Text(
                            'Category',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: AppColors.deepNavy,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                          const SizedBox(height: 2),
                          CategoryGridWidget(
                            categories: [
                              CategoryItem(
                                label: 'Tablet',
                                icon: Icons.medication,
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const MedicationListPage(),
                                    ),
                                  );
                                },
                              ),
                              CategoryItem(
                                label: 'Solution',
                                icon: Icons.water_drop,
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const MedicationListPage(),
                                    ),
                                  );
                                },
                              ),
                              CategoryItem(
                                label: 'Capsule',
                                icon: Icons.circle,
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const MedicationListPage(),
                                    ),
                                  );
                                },
                              ),
                              CategoryItem(
                                label: 'Injection',
                                icon: Icons.medical_services,
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const MedicationListPage(),
                                    ),
                                  );
                                },
                              ),
                              CategoryItem(
                                label: 'Verify',
                                icon: Icons.verified,
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const MedicationVerificationPage(),
                                    ),
                                  );
                                },
                              ),
                              CategoryItem(
                                label: 'Expiry',
                                icon: Icons.calendar_today,
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const ExpiryManagementPage(),
                                    ),
                                  );
                                },
                              ),
                              CategoryItem(
                                label: 'Stocks',
                                icon: Icons.inventory,
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const StockReconciliationPage(),
                                    ),
                                  );
                                },
                              ),
                              CategoryItem(
                                label: 'All',
                                icon: Icons.category,
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const CategoriesPage(),
                                    ),
                                  );
                                },
                              ),
                            ],
                            crossAxisCount: 4,
                          ),
                        ],
                      ),
                    ),
                    // Content Cards - Redesigned Compact Layout
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                      child: Column(
                        children: [
                          _buildCompactCard(
                            context,
                            title: 'Total Medications',
                            value: _totalMedications.toString(),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const MedicationListPage(),
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 10),
                          _buildCompactCard(
                            context,
                            title: 'Expiring Soon',
                            value: _expiringSoon.toString(),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const ExpiryManagementPage(),
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 10),
                          _buildCompactCard(
                            context,
                            title: 'Low Stock',
                            value: _lowStock.toString(),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const StockReconciliationPage(),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildCompactCard(
    BuildContext context, {
    required String title,
    required String value,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.skyBlue,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: AppColors.pureWhite.withOpacity(0.9),
                        fontWeight: FontWeight.w500,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      value,
                      style: Theme.of(context).textTheme.displaySmall?.copyWith(
                        color: AppColors.pureWhite,
                        fontWeight: FontWeight.bold,
                        fontSize: 28,
                        height: 1.0,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.pureWhite,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'View All',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.skyBlue,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
