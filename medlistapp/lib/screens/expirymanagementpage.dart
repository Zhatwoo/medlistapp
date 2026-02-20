import 'package:flutter/material.dart';
import 'package:medlistapp/models/stockitem.dart';
import 'package:medlistapp/models/medication.dart';
import 'package:medlistapp/services/expiryservice.dart';
import 'package:medlistapp/services/medicationservice.dart';
import 'package:medlistapp/services/notificationservice.dart';
import 'package:medlistapp/services/stockservice.dart';
import 'package:medlistapp/widgets/expiryalertcard.dart';
import 'package:medlistapp/widgets/filterchipwidget.dart';
import 'package:medlistapp/screens/medicationdetailpage.dart';
import 'package:medlistapp/utils/appcolors.dart';
import 'package:medlistapp/utils/constants.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ExpiryManagementPage extends StatefulWidget {
  /// Initial tab: 0=Expiring Soon, 1=Expired, 2=Low Stock, 3=Out of Stock
  final int initialTab;

  const ExpiryManagementPage({super.key, this.initialTab = 0});

  @override
  State<ExpiryManagementPage> createState() => _ExpiryManagementPageState();
}

class _ExpiryManagementPageState extends State<ExpiryManagementPage>
    with SingleTickerProviderStateMixin {
  final ExpiryService _expiryService = ExpiryService();
  final MedicationService _medicationService = MedicationService();
  final StockService _stockService = StockService();
  final NotificationService _notificationService = NotificationService();

  static const _tabCategories = ['expiring', 'expired', 'lowStock', 'outOfStock'];

  late TabController _tabController;
  List<StockItem> _expiringItems = [];
  List<StockItem> _expiredItems = [];
  List<StockItem> _lowStockItems = [];
  List<StockItem> _outOfStockItems = [];
  bool _isLoading = true;
  String _selectedFilter = '30';
  final List<String> _filters = ['7', '30', '90'];
  final Map<String, int> _unreadCounts = {};

  @override
  void initState() {
    super.initState();
    final tab = widget.initialTab.clamp(0, 3);
    _tabController = TabController(length: 4, vsync: this, initialIndex: tab);
    _tabController.addListener(_onTabChanged);
    _loadSettingsAndData();
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) return;
    final category = _tabCategories[_tabController.index];
    if ((_unreadCounts[category] ?? 0) > 0) {
      _notificationService.markAsReadByCategory(category).then((_) {
        _loadUnreadCounts();
      });
    }
  }

  Future<void> _loadUnreadCounts() async {
    final counts = <String, int>{};
    for (final cat in _tabCategories) {
      counts[cat] = await _notificationService.getUnreadCountByCategory(cat);
    }
    if (mounted) setState(() => _unreadCounts.addAll(counts));
  }

  Future<void> _loadSettingsAndData() async {
    await _loadUnreadCounts();
    // Mark all notifications as read when user opens Alerts screen
    await _notificationService.markAllAsRead();
    await _loadUnreadCounts();
    final prefs = await SharedPreferences.getInstance();
    final alertDays = prefs.getInt('expiry_alert_days') ?? AppConstants.defaultExpiryAlertDays;
    await _loadExpiryData(days: alertDays);
  }

  Future<void> _loadExpiryData({int? days}) async {
    setState(() => _isLoading = true);
    try {
      final expiryDays = days ?? int.tryParse(_selectedFilter) ?? 30;
      if (mounted) setState(() => _selectedFilter = '$expiryDays');
      final lowThresh = (await SharedPreferences.getInstance())
          .getInt('low_stock_threshold') ?? AppConstants.defaultLowStockThreshold;

      final expiring = await _expiryService.getExpiringMedications(expiryDays);
      final expired = await _expiryService.getExpiredMedications();
      final lowStock = await _stockService.getLowStockItems(lowThresh);
      final all = await _stockService.getAllStockItems();
      final outOfStock = all.where((i) => i.quantity == 0).toList();

      if (mounted) {
        setState(() {
          _expiringItems = expiring;
          _expiredItems = expired;
          _lowStockItems = lowStock;
          _outOfStockItems = outOfStock;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading alerts: $e')),
        );
      }
    }
  }

  void _applyFilter() {
    final days = int.tryParse(_selectedFilter) ?? 30;
    _expiryService.getExpiringMedications(days).then((items) {
      if (mounted) setState(() => _expiringItems = items);
    });
  }

  Widget _buildTab(String label, String category) {
    final hasUnread = (_unreadCounts[category] ?? 0) > 0;
    return Tab(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label),
          if (hasUnread) ...[
            const SizedBox(width: 6),
            Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.aliceBlue,
      appBar: AppBar(
        title: const Text('Alerts'),
        backgroundColor: AppColors.skyBlue,
        foregroundColor: AppColors.pureWhite,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: AppColors.pureWhite,
          unselectedLabelColor: AppColors.pureWhite.withOpacity(0.7),
          indicatorColor: AppColors.pureWhite,
          tabs: [
            _buildTab('Expiring Soon', 'expiring'),
            _buildTab('Expired', 'expired'),
            _buildTab('Low Stock', 'lowStock'),
            _buildTab('Out of Stock', 'outOfStock'),
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
                _buildStockListTab(_lowStockItems, 'No low stock items', Icons.inventory_2_outlined),
                _buildStockListTab(_outOfStockItems, 'No out of stock items', Icons.remove_shopping_cart_outlined),
              ],
            ),
    );
  }

  Widget _buildStockListTab(List<StockItem> items, String emptyText, IconData emptyIcon) {
    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(emptyIcon, size: 64, color: AppColors.mediumGray.withOpacity(0.5)),
            const SizedBox(height: 16),
            Text(
              emptyText,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(color: AppColors.mediumGray),
            ),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _loadExpiryData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: items.length,
        itemBuilder: (context, index) {
          final stockItem = items[index];
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
                      builder: (context) => MedicationDetailPage(medicationId: stockItem.medicationId),
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
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
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
