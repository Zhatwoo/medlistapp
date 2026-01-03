import 'package:medlistapp/services/notificationservice.dart';
import 'package:medlistapp/services/expiryservice.dart';
import 'package:medlistapp/services/stockservice.dart';
import 'package:medlistapp/services/medicationservice.dart';
import 'package:medlistapp/utils/constants.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BackgroundNotificationService {
  final NotificationService _notificationService = NotificationService();
  final ExpiryService _expiryService = ExpiryService();
  final StockService _stockService = StockService();
  final MedicationService _medicationService = MedicationService();

  // Run all daily checks
  Future<void> runDailyChecks() async {
    await checkExpiryAlerts();
    await checkLowStockAlerts();
  }

  // Check and notify about expiring medications
  Future<void> checkExpiryAlerts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final expiryAlertDays = prefs.getInt('expiry_alert_days') ?? AppConstants.defaultExpiryAlertDays;
      
      final expiringItems = await _expiryService.getExpiringMedications(expiryAlertDays);
      
      if (expiringItems.isEmpty) return;

      // Group by days until expiry
      final expiringToday = <String>[];
      final expiringSoon = <String>[];

      for (final item in expiringItems) {
        final medication = await _medicationService.getMedicationById(item.medicationId);
        if (medication == null) continue;

        final daysUntilExpiry = item.expiryDate.difference(DateTime.now()).inDays;
        final itemInfo = '${medication.tradeName} (${item.quantity} units)';

        if (daysUntilExpiry <= 0) {
          expiringToday.add(itemInfo);
        } else if (daysUntilExpiry <= 7) {
          expiringSoon.add(itemInfo);
        }
      }

      // Send notifications
      if (expiringToday.isNotEmpty) {
        final count = expiringToday.length;
        await _notificationService.showExpiryAlert(
          title: '⚠️ Medications Expired',
          body: count == 1
              ? '${expiringToday.first} has expired'
              : '$count medications have expired',
          data: {
            'type': 'expiry',
            'count': count,
            'items': expiringToday,
          },
        );
      } else if (expiringSoon.isNotEmpty) {
        final count = expiringSoon.length;
        await _notificationService.showExpiryAlert(
          title: '⚠️ Medications Expiring Soon',
          body: count == 1
              ? '${expiringSoon.first} is expiring within 7 days'
              : '$count medications are expiring within 7 days',
          data: {
            'type': 'expiry',
            'count': count,
            'items': expiringSoon,
          },
        );
      } else if (expiringItems.length > 0) {
        final count = expiringItems.length;
        await _notificationService.showExpiryAlert(
          title: '📅 Medications Expiring',
          body: '$count medication${count > 1 ? 's are' : ' is'} expiring within $expiryAlertDays days',
          data: {
            'type': 'expiry',
            'count': count,
          },
        );
      }
    } catch (e) {
      // Log error but don't throw
      print('Error checking expiry alerts: $e');
    }
  }

  // Check and notify about low stock
  Future<void> checkLowStockAlerts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lowStockThreshold = prefs.getInt('low_stock_threshold') ?? AppConstants.defaultLowStockThreshold;
      
      final lowStockItems = await _stockService.getLowStockItems(lowStockThreshold);
      
      if (lowStockItems.isEmpty) return;

      // Get medication names
      final lowStockList = <String>[];
      for (final item in lowStockItems) {
        final medication = await _medicationService.getMedicationById(item.medicationId);
        if (medication != null) {
          lowStockList.add('${medication.tradeName} (${item.quantity} left)');
        }
      }

      if (lowStockList.isEmpty) return;

      final count = lowStockList.length;
      await _notificationService.showLowStockAlert(
        title: '📦 Low Stock Alert',
        body: count == 1
            ? '${lowStockList.first} is running low'
            : '$count items are running low on stock',
        data: {
          'type': 'lowStock',
          'count': count,
          'items': lowStockList,
        },
      );
    } catch (e) {
      // Log error but don't throw
      print('Error checking low stock alerts: $e');
    }
  }

  // Check for out of stock items
  Future<void> checkOutOfStockAlerts() async {
    try {
      final allStockItems = await _stockService.getAllStockItems();
      final outOfStock = allStockItems.where((item) => item.quantity == 0).toList();

      if (outOfStock.isEmpty) return;

      final medicationNames = <String>[];
      for (final item in outOfStock) {
        final medication = await _medicationService.getMedicationById(item.medicationId);
        if (medication != null) {
          medicationNames.add(medication.tradeName);
        }
      }

      if (medicationNames.isEmpty) return;

      final count = medicationNames.length;
      await _notificationService.showLowStockAlert(
        title: '🚨 Out of Stock',
        body: count == 1
            ? '${medicationNames.first} is out of stock'
            : '$count medications are out of stock',
        data: {
          'type': 'outOfStock',
          'count': count,
          'items': medicationNames,
        },
      );
    } catch (e) {
      print('Error checking out of stock alerts: $e');
    }
  }
}


