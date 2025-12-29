class AppConstants {
  AppConstants._(); // Private constructor

  // Database
  static const String databaseName = 'medlistapp.db';
  static const int databaseVersion = 2; // Incremented for new tables

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

  // Default values
  static const int defaultExpiryAlertDays = 30;
  static const int defaultLowStockThreshold = 10;

  // MOH Data
  static const String mohDataAssetPath = 'assets/moh_price_list.md';
  static const String dataInitializedKey = 'data_initialized';
}

