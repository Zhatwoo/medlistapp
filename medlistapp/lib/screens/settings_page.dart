import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:medlistapp/utils/constants.dart';
import 'package:medlistapp/utils/app_colors.dart';
import 'package:medlistapp/services/mims_service.dart';
import 'package:medlistapp/services/sync_service.dart';
import 'package:medlistapp/services/mims_cache_service.dart';
import 'package:medlistapp/services/data_initialization_service.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final MimsService _mimsService = MimsService();
  final SyncService _syncService = SyncService();
  final MimsCacheService _cacheService = MimsCacheService();
  
  int _expiryAlertDays = AppConstants.defaultExpiryAlertDays;
  int _lowStockThreshold = AppConstants.defaultLowStockThreshold;
  int _syncFrequencyHours = 24;
  bool _offlineMode = false;
  bool _isLoading = true;
  bool _hasMimsCredentials = false;
  
  final TextEditingController _mimsApiKeyController = TextEditingController();
  final TextEditingController _mimsApiSecretController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final hasCredentials = await _mimsService.hasCredentials();
    setState(() {
      _expiryAlertDays = prefs.getInt('expiry_alert_days') ?? AppConstants.defaultExpiryAlertDays;
      _lowStockThreshold = prefs.getInt('low_stock_threshold') ?? AppConstants.defaultLowStockThreshold;
      _syncFrequencyHours = prefs.getInt('sync_frequency_hours') ?? 24;
      _offlineMode = prefs.getBool('offline_mode') ?? false;
      _hasMimsCredentials = hasCredentials;
      _isLoading = false;
    });
  }

  Future<void> _saveExpiryAlertDays(int days) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('expiry_alert_days', days);
    setState(() => _expiryAlertDays = days);
  }

  Future<void> _saveLowStockThreshold(int threshold) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('low_stock_threshold', threshold);
    setState(() => _lowStockThreshold = threshold);
  }

  Future<void> _saveMimsCredentials() async {
    if (_mimsApiKeyController.text.isEmpty || _mimsApiSecretController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter both API Key and Secret')),
      );
      return;
    }

    try {
      await _mimsService.setCredentials(
        _mimsApiKeyController.text,
        _mimsApiSecretController.text,
      );
      setState(() => _hasMimsCredentials = true);
      _mimsApiKeyController.clear();
      _mimsApiSecretController.clear();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('MIMS credentials saved successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving credentials: $e')),
        );
      }
    }
  }

  Future<void> _saveSyncFrequency(int hours) async {
    await _syncService.setSyncFrequency(hours);
    setState(() => _syncFrequencyHours = hours);
  }

  Future<void> _toggleOfflineMode(bool enabled) async {
    await _syncService.setOfflineMode(enabled);
    setState(() => _offlineMode = enabled);
  }

  Future<void> _performSync() async {
    final result = await _syncService.sync();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.success
              ? 'Sync completed successfully'
              : 'Sync failed: ${result.errorMessage}'),
        ),
      );
    }
  }

  Future<void> _clearCache() async {
    await _cacheService.clearAllCache();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cache cleared successfully')),
      );
    }
  }

  Future<void> _exportData() async {
    // Export functionality would go here
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Data export functionality coming soon')),
      );
    }
  }

  @override
  void dispose() {
    _mimsApiKeyController.dispose();
    _mimsApiSecretController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.aliceBlue,
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: AppColors.skyBlue,
        foregroundColor: AppColors.pureWhite,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Alert Settings',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 16),
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Expiry Alert Days'),
                          subtitle: Text('Alert when medication expires within $_expiryAlertDays days'),
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.softBlue,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: DropdownButton<int>(
                              value: _expiryAlertDays,
                              underline: Container(),
                              items: [7, 14, 30, 60, 90].map((days) {
                                return DropdownMenuItem(
                                  value: days,
                                  child: Text('$days days'),
                                );
                              }).toList(),
                              onChanged: (value) {
                                if (value != null) {
                                  _saveExpiryAlertDays(value);
                                }
                              },
                            ),
                          ),
                        ),
                        const Divider(),
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Low Stock Threshold'),
                          subtitle: Text('Alert when stock is below $_lowStockThreshold'),
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.softBlue,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: DropdownButton<int>(
                              value: _lowStockThreshold,
                              underline: Container(),
                              items: [5, 10, 15, 20, 25, 50].map((threshold) {
                                return DropdownMenuItem(
                                  value: threshold,
                                  child: Text('$threshold'),
                                );
                              }).toList(),
                              onChanged: (value) {
                                if (value != null) {
                                  _saveLowStockThreshold(value);
                                }
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // MIMS Configuration
                Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'MIMS Configuration',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 16),
                        if (_hasMimsCredentials)
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: Icon(Icons.check_circle, color: AppColors.successGreen),
                            title: const Text('MIMS Credentials'),
                            subtitle: const Text('Configured'),
                          )
                        else ...[
                          TextField(
                            controller: _mimsApiKeyController,
                            decoration: InputDecoration(
                              labelText: 'MIMS API Key',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            obscureText: false,
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _mimsApiSecretController,
                            decoration: InputDecoration(
                              labelText: 'MIMS API Secret',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            obscureText: true,
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.skyBlue,
                                foregroundColor: AppColors.pureWhite,
                              ),
                              onPressed: _saveMimsCredentials,
                              child: const Text('Save Credentials'),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Sync Settings
                Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Sync Settings',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 16),
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Sync Frequency'),
                          subtitle: Text('Sync every $_syncFrequencyHours hours'),
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.softBlue,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: DropdownButton<int>(
                              value: _syncFrequencyHours,
                              underline: Container(),
                              items: [1, 6, 12, 24, 48].map((hours) {
                                return DropdownMenuItem(
                                  value: hours,
                                  child: Text('$hours hours'),
                                );
                              }).toList(),
                              onChanged: (value) {
                                if (value != null) {
                                  _saveSyncFrequency(value);
                                }
                              },
                            ),
                          ),
                        ),
                        const Divider(),
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Offline Mode'),
                          subtitle: const Text('Disable online sync'),
                          value: _offlineMode,
                          onChanged: _toggleOfflineMode,
                        ),
                        const Divider(),
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Manual Sync'),
                          subtitle: const Text('Sync data now'),
                          trailing: IconButton(
                            icon: const Icon(Icons.sync),
                            onPressed: _performSync,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Data Management
                Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Data Management',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 16),
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Clear MIMS Cache'),
                          subtitle: const Text('Remove cached MIMS data'),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_outline),
                            onPressed: _clearCache,
                          ),
                        ),
                        const Divider(),
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Export Data'),
                          subtitle: const Text('Export all data to file'),
                          trailing: IconButton(
                            icon: const Icon(Icons.download),
                            onPressed: _exportData,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // About
                Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'About',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 16),
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('App Version'),
                          subtitle: const Text('1.0.0'),
                        ),
                        const Divider(),
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Data Source'),
                          subtitle: const Text('MOH Price List - UAE'),
                        ),
                        const Divider(),
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Last Updated'),
                          subtitle: const Text('May 5, 2023'),
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
