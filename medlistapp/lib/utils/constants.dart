class AppConstants {
  AppConstants._(); // Private constructor

  // Database
  static const String databaseName = 'medlistapp.db';
  static const int databaseVersion = 6; // Incremented for stock management enhancements

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
  static const String tablePatients = 'patients';
  static const String tableNotifications = 'notifications';
  static const String tableStockAdjustments = 'stock_adjustments';

  // Default values
  static const int defaultExpiryAlertDays = 30;
  static const int defaultLowStockThreshold = 10;
  static const double defaultOverstockThreshold = 2.0; // 200% of expected quantity

  // Notification channels
  static const String expiryAlertChannelId = 'expiry_alerts';
  static const String expiryAlertChannelName = 'Expiry Alerts';
  static const String lowStockAlertChannelId = 'low_stock_alerts';
  static const String lowStockAlertChannelName = 'Low Stock Alerts';
  static const String systemAlertChannelId = 'system_alerts';
  static const String systemAlertChannelName = 'System Alerts';

  // MOH Data
  static const String mohDataAssetPath = 'assets/moh_price_list.md';
  static const String dataInitializedKey = 'data_initialized';
}

