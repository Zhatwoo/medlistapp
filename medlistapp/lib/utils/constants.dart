class AppConstants {
  AppConstants._(); // Private constructor

  // Database
  static const String databaseName = 'medlistapp.db';
  static const int databaseVersion = 7; // v7: add medications.gtin, stock_items.serial_number

  // Table names
  static const String tableMedications = 'medications';
  static const String tableStockItems = 'stock_items';
  static const String tableExpiryRecords = 'expiry_records';
  static const String tableVerificationResults = 'verification_results';
  static const String tableAuditLogs = 'audit_logs';
  static const String tableMimsCache = 'mims_cache';
  static const String tableDrugInteractions = 'drug_interactions';
  static const String tableVerificationHistory = 'verification_history';
  static const String tableReports = 'reports';
  static const String tableBarcodeData = 'barcode_data';
  static const String tableNotifications = 'notifications';
  static const String tableStockAdjustments = 'stock_adjustments';
  static const String tableUsers = 'users';
  static const String tablePatients = 'patients';

  // Notification channels
  static const String expiryAlertChannelId = 'expiry_alert_channel';
  static const String expiryAlertChannelName = 'Expiry Alerts';
  static const String lowStockAlertChannelId = 'low_stock_alert_channel';
  static const String lowStockAlertChannelName = 'Low Stock Alerts';
  static const String systemAlertChannelId = 'system_alert_channel';
  static const String systemAlertChannelName = 'System Alerts';

  // Default values
  static const int defaultExpiryAlertDays = 30;
  static const int defaultLowStockThreshold = 10;
  static const int defaultOverstockThreshold = 50;

  // MOH Data
  static const String mohDataAssetPath = 'assets/moh_price_list.md';
  static const String dataInitializedKey = 'data_initialized';
}

