import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:medlistapp/utils/constants.dart';
import 'package:medlistapp/utils/appcolors.dart';
import 'package:medlistapp/services/authservice.dart';
import 'package:medlistapp/services/mimsservice.dart';
import 'package:medlistapp/screens/loginscreen.dart';
import 'package:medlistapp/services/syncservice.dart';
import 'package:medlistapp/services/mimscacheservice.dart';
import 'package:medlistapp/services/localauthservice.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final AuthService _authService = AuthService();
  final MimsService _mimsService = MimsService();
  final SyncService _syncService = SyncService();
  final MimsCacheService _cacheService = MimsCacheService();
  
  int _expiryAlertDays = AppConstants.defaultExpiryAlertDays;
  int _lowStockThreshold = AppConstants.defaultLowStockThreshold;
  int _syncFrequencyHours = 24;
  bool _offlineMode = false;
  bool _isLoading = true;
  bool _hasMimsCredentials = false;
  bool _biometricEnabled = false;
  bool _biometricAvailable = false;
  bool _hasPin = false;
  bool _expiryAlertsEnabled = true;
  bool _lowStockAlertsEnabled = true;
  bool _systemAlertsEnabled = true;
  final LocalAuthService _localAuth = LocalAuthService();

  final TextEditingController _mimsApiKeyController = TextEditingController();
  final TextEditingController _mimsApiSecretController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Log out'),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.errorRed,
              foregroundColor: AppColors.pureWhite,
            ),
            child: const Text('Log out'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      await _authService.signOut();
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => LoginScreen()),
        (route) => false,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Logout failed: $e'),
            backgroundColor: AppColors.errorRed,
          ),
        );
      }
    }
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final hasCredentials = await _mimsService.hasCredentials();
    final biometricEnabled = await _localAuth.isBiometricEnabled();
    final biometricAvailable = await _localAuth.isBiometricAvailable();
    final hasPin = await _localAuth.hasPin();
    if (mounted) {
      setState(() {
        _expiryAlertDays = prefs.getInt('expiry_alert_days') ?? AppConstants.defaultExpiryAlertDays;
        _lowStockThreshold = prefs.getInt('low_stock_threshold') ?? AppConstants.defaultLowStockThreshold;
        _syncFrequencyHours = prefs.getInt('sync_frequency_hours') ?? 24;
        _offlineMode = prefs.getBool('offline_mode') ?? false;
        _hasMimsCredentials = hasCredentials;
        _biometricEnabled = biometricEnabled;
        _biometricAvailable = biometricAvailable;
        _hasPin = hasPin;
        _expiryAlertsEnabled = prefs.getBool('expiry_alerts_enabled') ?? true;
        _lowStockAlertsEnabled = prefs.getBool('low_stock_alerts_enabled') ?? true;
        _systemAlertsEnabled = prefs.getBool('system_alerts_enabled') ?? true;
        _isLoading = false;
      });
    }
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

  Future<void> _toggleBiometric(bool enabled) async {
    await _localAuth.setBiometricEnabled(enabled);
    if (mounted) setState(() => _biometricEnabled = enabled);
  }

  Future<void> _showSetPinDialog() async {
    final controller = TextEditingController();
    final confirmController = TextEditingController();
    final success = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Set PIN'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              obscureText: true,
              maxLength: 6,
              decoration: const InputDecoration(
                labelText: 'Enter 4-6 digit PIN',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: confirmController,
              keyboardType: TextInputType.number,
              obscureText: true,
              maxLength: 6,
              decoration: const InputDecoration(
                labelText: 'Confirm PIN',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final pin = controller.text;
              if (pin.length < 4) {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  const SnackBar(content: Text('PIN must be at least 4 digits')),
                );
                return;
              }
              if (pin != confirmController.text) {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  const SnackBar(content: Text('PINs do not match')),
                );
                return;
              }
              await _localAuth.setPin(pin);
              if (ctx.mounted) Navigator.pop(ctx, true);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (success == true && mounted) {
      setState(() => _hasPin = true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('PIN set successfully')),
      );
    }
  }

  Future<void> _showChangePinDialog() async {
    final controller = TextEditingController();
    final newController = TextEditingController();
    final confirmController = TextEditingController();
    final success = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Change PIN'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              obscureText: true,
              maxLength: 6,
              decoration: const InputDecoration(
                labelText: 'Current PIN',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: newController,
              keyboardType: TextInputType.number,
              obscureText: true,
              maxLength: 6,
              decoration: const InputDecoration(
                labelText: 'New PIN',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: confirmController,
              keyboardType: TextInputType.number,
              obscureText: true,
              maxLength: 6,
              decoration: const InputDecoration(
                labelText: 'Confirm new PIN',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final ok = await _localAuth.verifyPin(controller.text);
              if (!ok) {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  const SnackBar(content: Text('Current PIN is incorrect')),
                );
                return;
              }
              final newPin = newController.text;
              if (newPin.length < 4) {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  const SnackBar(content: Text('PIN must be at least 4 digits')),
                );
                return;
              }
              if (newPin != confirmController.text) {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  const SnackBar(content: Text('New PINs do not match')),
                );
                return;
              }
              await _localAuth.setPin(newPin);
              if (ctx.mounted) Navigator.pop(ctx, true);
            },
            child: const Text('Change'),
          ),
        ],
      ),
    );
    if (success == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('PIN changed successfully')),
      );
    }
  }

  Future<void> _removePin() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove PIN'),
        content: const Text(
          'Are you sure? You will no longer be prompted for PIN on app launch.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.errorRed,
              foregroundColor: AppColors.pureWhite,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (ok == true) {
      await _localAuth.clearPin();
      if (mounted) setState(() => _hasPin = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('PIN removed')),
        );
      }
    }
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
                          'Account',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 16),
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.logout, color: AppColors.errorRed),
                          title: const Text(
                            'Log out',
                            style: TextStyle(
                              color: AppColors.errorRed,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          onTap: _logout,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
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
                          'Security',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 16),
                        if (_biometricAvailable)
                          SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            title: const Text('Use biometric on app launch'),
                            subtitle: const Text('Fingerprint or face recognition'),
                            value: _biometricEnabled,
                            onChanged: _toggleBiometric,
                          ),
                        if (_biometricAvailable) const Divider(),
                        if (_hasPin)
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: const Icon(Icons.pin),
                            title: const Text('PIN'),
                            subtitle: const Text('Change or remove PIN'),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                TextButton(
                                  onPressed: _showChangePinDialog,
                                  child: const Text('Change'),
                                ),
                                TextButton(
                                  onPressed: _removePin,
                                  child: const Text('Remove'),
                                ),
                              ],
                            ),
                          )
                        else
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: const Icon(Icons.pin_outlined),
                            title: const Text('Set PIN'),
                            subtitle: const Text('Require PIN on app launch'),
                            trailing: ElevatedButton(
                              onPressed: _showSetPinDialog,
                              child: const Text('Set PIN'),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
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
                // Notification Toggles
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
                          'Notification Types',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 8),
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Expiry alerts'),
                          subtitle: const Text('Notify when medications are expiring'),
                          value: _expiryAlertsEnabled,
                          onChanged: (v) async {
                            final prefs = await SharedPreferences.getInstance();
                            await prefs.setBool('expiry_alerts_enabled', v);
                            setState(() => _expiryAlertsEnabled = v);
                          },
                        ),
                        const Divider(),
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Low stock alerts'),
                          subtitle: const Text('Notify when stock is running low'),
                          value: _lowStockAlertsEnabled,
                          onChanged: (v) async {
                            final prefs = await SharedPreferences.getInstance();
                            await prefs.setBool('low_stock_alerts_enabled', v);
                            setState(() => _lowStockAlertsEnabled = v);
                          },
                        ),
                        const Divider(),
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('System alerts'),
                          subtitle: const Text('General system notifications'),
                          value: _systemAlertsEnabled,
                          onChanged: (v) async {
                            final prefs = await SharedPreferences.getInstance();
                            await prefs.setBool('system_alerts_enabled', v);
                            setState(() => _systemAlertsEnabled = v);
                          },
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
