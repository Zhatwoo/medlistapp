import 'package:flutter/material.dart';
import 'package:medlistapp/widgets/dashboardstatcard.dart';
import 'package:medlistapp/widgets/searchbarwidget.dart';
import 'package:medlistapp/widgets/expiryalertcard.dart';
import 'package:medlistapp/widgets/categorygridwidget.dart';
import 'package:medlistapp/services/authservice.dart';
import 'package:medlistapp/services/medicationservice.dart';
import 'package:medlistapp/services/stockservice.dart';
import 'package:medlistapp/services/expiryservice.dart';
import 'package:medlistapp/services/verificationservice.dart';
import 'package:medlistapp/services/auditservice.dart';
import 'package:medlistapp/services/interactionservice.dart';
import 'package:medlistapp/models/medication.dart';
import 'package:medlistapp/models/stockitem.dart';
import 'package:medlistapp/models/verificationresult.dart';
import 'package:medlistapp/models/druginteraction.dart';
import 'package:medlistapp/screens/medicationlistpage.dart';
import 'package:medlistapp/screens/expirymanagementpage.dart';
import 'package:medlistapp/screens/stockreconciliationpage.dart';
import 'package:medlistapp/screens/categoriespage.dart';
import 'package:medlistapp/screens/medicationverificationpage.dart';
import 'package:medlistapp/screens/profilesettingspage.dart';
import 'package:medlistapp/screens/patientlistpage.dart';
import 'package:medlistapp/screens/diagnosishelperpage.dart';
import 'package:medlistapp/screens/reportspage.dart';
import 'package:medlistapp/screens/addeditmedicationpage.dart';
import 'package:medlistapp/models/userrole.dart';
import 'package:medlistapp/services/notificationservice.dart';
import 'package:medlistapp/utils/appcolors.dart';
import 'package:medlistapp/utils/constants.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Dashboard extends StatefulWidget {
  const Dashboard({super.key});

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  final AuthService _authService = AuthService();
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
  UserRole _role = UserRole.pharmacist;
  int _unreadNotifications = 0;
  final NotificationService _notificationService = NotificationService();

  String get _userDisplayName {
    final user = _authService.currentUser;
    if (user == null) return 'Guest';
    try {
      final name = (user as dynamic).displayName as String?;
      return (name != null && name.isNotEmpty) ? name : (user as dynamic).email ?? 'User';
    } catch (_) {
      return 'User';
    }
  }

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() => _isLoading = true);
    try {
      final role = await _authService.getUserRole();
      final unread = await _notificationService.getUnreadCount();
      if (mounted) {
        setState(() {
          _role = role;
          _unreadNotifications = unread;
        });
      }
      final medications = await _medicationService.getAllMedications();
      final stockItems = await _stockService.getAllStockItems();
      final prefs = await SharedPreferences.getInstance();
      final alertDays = prefs.getInt('expiry_alert_days') ?? AppConstants.defaultExpiryAlertDays;
      final expiringItems = await _expiryService.getExpiryAlerts(alertDays);
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

  Future<void> _refreshUnreadCount() async {
    final unread = await _notificationService.getUnreadCount();
    if (mounted) setState(() => _unreadNotifications = unread);
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
                              GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const ProfileSettingsPage(),
                                    ),
                                  );
                                },
                                child: Container(
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
                              ),
                              const SizedBox(width: 16),
                              GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const ProfileSettingsPage(),
                                    ),
                                  );
                                },
                                child: Column(
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
                                      _userDisplayName,
                                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                        color: AppColors.pureWhite,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 20,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          // Bell Icon
                          IconButton(
                            icon: Badge(
                              isLabelVisible: _unreadNotifications > 0,
                              label: Text(
                                _unreadNotifications > 99 ? '99+' : '$_unreadNotifications',
                                style: const TextStyle(fontSize: 10),
                              ),
                              child: const Icon(
                                Icons.notifications_outlined,
                                color: AppColors.pureWhite,
                                size: 24,
                              ),
                            ),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const ExpiryManagementPage(),
                                ),
                              ).then((_) => _refreshUnreadCount());
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
                                label: 'Scan Stock',
                                icon: Icons.qr_code_scanner_rounded,
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const AddEditMedicationPage(
                                        openScannerOnLoad: true,
                                      ),
                                    ),
                                  );
                                },
                              ),
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
                                label: 'Reports',
                                icon: Icons.summarize,
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const ReportsPage(),
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
                              if (_role == UserRole.doctor || _role == UserRole.admin)
                                CategoryItem(
                                  label: 'Patients',
                                  icon: Icons.people,
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => const PatientListPage(),
                                      ),
                                    );
                                  },
                                ),
                              CategoryItem(
                                label: 'Diagnosis',
                                icon: Icons.medical_services,
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const DiagnosisHelperPage(),
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
                                  builder: (context) => const ExpiryManagementPage(initialTab: 2),
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
