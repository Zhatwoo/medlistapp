import 'package:medlistapp/models/userrole.dart';
import 'package:medlistapp/services/authservice.dart';
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
  final AuthService _authService = AuthService();

  Future<UserRole> _getUserRole() async {
    try {
      return await _authService.getUserRole();
    } catch (_) {
      return UserRole.pharmacist;
    }
  }

  Future<void> runDailyChecks() async {
    await checkExpiryAlerts();
    await checkLowStockAlerts();
    await checkOutOfStockAlerts();
  }

  Future<void> checkExpiryAlerts() async {
    try {
      final role = await _getUserRole();
      if (role != UserRole.pharmacist && role != UserRole.inventoryManager && role != UserRole.admin) {
        return;
      }

      final prefs = await SharedPreferences.getInstance();
      final expiryAlertDays = prefs.getInt('expiry_alert_days') ?? AppConstants.defaultExpiryAlertDays;

      // 1. Check EXPIRED items first
      final expiredItems = await _expiryService.getExpiredMedications();
      if (expiredItems.isNotEmpty) {
        final expiredList = <String>[];
        for (final item in expiredItems) {
          final medication = await _medicationService.getMedicationById(item.medicationId);
          if (medication != null) {
            expiredList.add('${medication.tradeName} (${item.quantity} units)');
          }
        }
        if (expiredList.isNotEmpty) {
          final count = expiredList.length;
          await _notificationService.showExpiryAlert(
            title: '⚠️ Medications Expired',
            body: count == 1
                ? '${expiredList.first} has expired'
                : '$count medications have expired',
            data: {'type': 'expiry', 'category': 'expired', 'count': count, 'items': expiredList},
          );
        }
      }

      // 2. Check EXPIRING items (within alert days)
      final expiringItems = await _expiryService.getExpiringMedications(expiryAlertDays);
      if (expiringItems.isEmpty) return;

      final expiringToday = <String>[];
      final expiringSoon = <String>[];

      for (final item in expiringItems) {
        final medication = await _medicationService.getMedicationById(item.medicationId);
        if (medication == null) continue;

        final daysUntilExpiry = item.daysUntilExpiry;
        final itemInfo = '${medication.tradeName} (${item.quantity} units)';

        if (daysUntilExpiry <= 0) {
          expiringToday.add(itemInfo);
        } else if (daysUntilExpiry <= 7) {
          expiringSoon.add(itemInfo);
        }
      }

      if (expiringToday.isNotEmpty) {
        final count = expiringToday.length;
        await _notificationService.showExpiryAlert(
          title: '⚠️ Medications Expiring Today',
          body: count == 1
              ? '${expiringToday.first} expires today'
              : '$count medications expire today',
          data: {'type': 'expiry', 'category': 'expiring', 'count': count, 'items': expiringToday},
        );
      } else if (expiringSoon.isNotEmpty) {
        final count = expiringSoon.length;
        await _notificationService.showExpiryAlert(
          title: '⚠️ Medications Expiring Soon',
          body: count == 1
              ? '${expiringSoon.first} is expiring within 7 days'
              : '$count medications are expiring within 7 days',
          data: {'type': 'expiry', 'category': 'expiring', 'count': count, 'items': expiringSoon},
        );
      } else if (expiringItems.isNotEmpty) {
        final count = expiringItems.length;
        await _notificationService.showExpiryAlert(
          title: '📅 Medications Expiring',
          body: '$count medication${count > 1 ? 's are' : ' is'} expiring within $expiryAlertDays days',
          data: {'type': 'expiry', 'category': 'expiring', 'count': count},
        );
      }
    } catch (e) {
      print('Error checking expiry alerts: $e');
    }
  }

  Future<void> checkLowStockAlerts() async {
    try {
      final role = await _getUserRole();
      if (role != UserRole.pharmacist && role != UserRole.inventoryManager && role != UserRole.admin) {
        return;
      }

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
          'category': 'lowStock',
          'count': count,
          'items': lowStockList,
        },
      );
    } catch (e) {
      // Log error but don't throw
      print('Error checking low stock alerts: $e');
    }
  }

  Future<void> checkOutOfStockAlerts() async {
    try {
      final role = await _getUserRole();
      if (role != UserRole.pharmacist && role != UserRole.inventoryManager && role != UserRole.admin) {
        return;
      }

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
          'category': 'outOfStock',
          'count': count,
          'items': medicationNames,
        },
      );
    } catch (e) {
      print('Error checking out of stock alerts: $e');
    }
  }
}




