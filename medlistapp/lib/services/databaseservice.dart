import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:medlistapp/utils/constants.dart';
import 'package:medlistapp/models/medication.dart';
import 'package:medlistapp/models/stockitem.dart';
import 'package:medlistapp/models/expiryrecord.dart';
import 'package:medlistapp/models/verificationresult.dart';
import 'package:medlistapp/models/auditlog.dart';
import 'package:medlistapp/models/mimsdrugdata.dart';
import 'package:medlistapp/models/druginteraction.dart';
import 'package:medlistapp/models/verificationhistory.dart';
import 'package:medlistapp/models/report.dart';
import 'package:medlistapp/models/barcodedata.dart';
import 'package:medlistapp/models/patient.dart';
import 'package:medlistapp/models/notification.dart';
import 'package:medlistapp/models/stockadjustment.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), AppConstants.databaseName);
    return await openDatabase(
      path,
      version: AppConstants.databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Add new tables for version 2
      await _createNewTables(db);
    }
    if (oldVersion < 3) {
      // Add patient table for version 3
      await _createPatientTable(db);
    }
    if (oldVersion < 4) {
      // Add notifications table for version 4
      await _createNotificationsTable(db);
    }
    if (oldVersion < 5) {
      // Add medication master data fields for version 5
      await _addMedicationMasterDataFields(db);
    }
    if (oldVersion < 6) {
      // Add stock management enhancements for version 6
      await _addStockManagementFields(db);
      await _createStockAdjustmentsTable(db);
    }
  }

  Future<void> _onCreate(Database db, int version) async {
    // Medications table
    await db.execute('''
      CREATE TABLE ${AppConstants.tableMedications} (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        trade_name TEXT NOT NULL,
        form TEXT NOT NULL,
        pack_size TEXT NOT NULL,
        pharmacy_price REAL NOT NULL,
        public_price REAL NOT NULL,
        active_ingredient TEXT NOT NULL,
        strength TEXT NOT NULL,
        company TEXT NOT NULL,
        source TEXT NOT NULL,
        agent TEXT NOT NULL,
        dispensing_mode TEXT NOT NULL,
        selection TEXT,
        storage_condition TEXT,
        is_controlled_drug INTEGER DEFAULT 0,
        therapeutic_category TEXT
      )
    ''');

    // Stock items table
    await db.execute('''
      CREATE TABLE ${AppConstants.tableStockItems} (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        medication_id INTEGER NOT NULL,
        quantity INTEGER NOT NULL,
        expiry_date TEXT NOT NULL,
        batch_number TEXT,
        location TEXT,
        purchase_date TEXT,
        manufacturing_date TEXT,
        expected_quantity INTEGER,
        created_at TEXT NOT NULL,
        updated_at TEXT,
        FOREIGN KEY (medication_id) REFERENCES ${AppConstants.tableMedications}(id) ON DELETE CASCADE
      )
    ''');

    // Expiry records table
    await db.execute('''
      CREATE TABLE ${AppConstants.tableExpiryRecords} (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        stock_item_id INTEGER NOT NULL,
        days_until_expiry INTEGER NOT NULL,
        is_expired INTEGER NOT NULL,
        alert_sent INTEGER NOT NULL DEFAULT 0,
        checked_at TEXT NOT NULL,
        alert_sent_at TEXT,
        FOREIGN KEY (stock_item_id) REFERENCES ${AppConstants.tableStockItems}(id) ON DELETE CASCADE
      )
    ''');

    // Create indexes for better performance
    await db.execute('''
      CREATE INDEX idx_medication_trade_name ON ${AppConstants.tableMedications}(trade_name)
    ''');
    await db.execute('''
      CREATE INDEX idx_medication_company ON ${AppConstants.tableMedications}(company)
    ''');
    await db.execute('''
      CREATE INDEX idx_stock_medication_id ON ${AppConstants.tableStockItems}(medication_id)
    ''');
    await db.execute('''
      CREATE INDEX idx_stock_expiry_date ON ${AppConstants.tableStockItems}(expiry_date)
    ''');
    
    // Create new tables
    await _createNewTables(db);
    // Create patient table
    await _createPatientTable(db);
    // Create notifications table
    await _createNotificationsTable(db);
    // Create stock adjustments table
    await _createStockAdjustmentsTable(db);
  }

  Future<void> _createNewTables(Database db) async {
    // Verification results table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS ${AppConstants.tableVerificationResults} (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        is_verified INTEGER NOT NULL,
        medication_id INTEGER,
        trade_name TEXT NOT NULL,
        indications TEXT,
        contraindications TEXT,
        warnings TEXT,
        interactions TEXT,
        verification_method TEXT,
        barcode TEXT,
        mims_data TEXT,
        verified_at TEXT NOT NULL,
        FOREIGN KEY (medication_id) REFERENCES ${AppConstants.tableMedications}(id) ON DELETE SET NULL
      )
    ''');

    // Audit logs table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS ${AppConstants.tableAuditLogs} (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        action_type TEXT NOT NULL,
        entity_type TEXT NOT NULL,
        entity_id INTEGER,
        user_id TEXT,
        description TEXT,
        metadata TEXT,
        timestamp TEXT NOT NULL
      )
    ''');

    // MIMS cache table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS ${AppConstants.tableMimsCache} (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        drug_code TEXT,
        drug_name TEXT NOT NULL,
        generic_name TEXT,
        therapeutic_class TEXT,
        indications TEXT,
        contraindications TEXT,
        dosage TEXT,
        administration TEXT,
        side_effects TEXT,
        interactions TEXT,
        precautions TEXT,
        storage TEXT,
        last_updated TEXT,
        cached_at TEXT NOT NULL
      )
    ''');

    // Drug interactions table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS ${AppConstants.tableDrugInteractions} (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        medication1_id TEXT NOT NULL,
        medication1_name TEXT NOT NULL,
        medication2_id TEXT NOT NULL,
        medication2_name TEXT NOT NULL,
        severity TEXT NOT NULL,
        description TEXT NOT NULL,
        recommendation TEXT,
        alternative_medications TEXT,
        detected_at TEXT NOT NULL
      )
    ''');

    // Verification history table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS ${AppConstants.tableVerificationHistory} (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        medication_id INTEGER,
        medication_name TEXT NOT NULL,
        identity_verified INTEGER NOT NULL,
        contraindication_found INTEGER,
        interaction_found INTEGER,
        verification_method TEXT,
        barcode TEXT,
        notes TEXT,
        verified_at TEXT NOT NULL,
        FOREIGN KEY (medication_id) REFERENCES ${AppConstants.tableMedications}(id) ON DELETE SET NULL
      )
    ''');

    // Reports table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS ${AppConstants.tableReports} (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        type TEXT NOT NULL,
        title TEXT NOT NULL,
        data TEXT NOT NULL,
        start_date TEXT NOT NULL,
        end_date TEXT NOT NULL,
        generated_at TEXT NOT NULL,
        file_path TEXT
      )
    ''');

    // Barcode data table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS ${AppConstants.tableBarcodeData} (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        barcode TEXT NOT NULL,
        format TEXT,
        medication_id INTEGER,
        medication_name TEXT,
        matched INTEGER NOT NULL,
        scanned_at TEXT NOT NULL,
        FOREIGN KEY (medication_id) REFERENCES ${AppConstants.tableMedications}(id) ON DELETE SET NULL
      )
    ''');

    // Create indexes for new tables
    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_verification_medication_id 
      ON ${AppConstants.tableVerificationResults}(medication_id)
    ''');
    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_audit_timestamp 
      ON ${AppConstants.tableAuditLogs}(timestamp)
    ''');
    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_mims_drug_name 
      ON ${AppConstants.tableMimsCache}(drug_name)
    ''');
    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_interaction_medications 
      ON ${AppConstants.tableDrugInteractions}(medication1_id, medication2_id)
    ''');
    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_verification_history_medication 
      ON ${AppConstants.tableVerificationHistory}(medication_id)
    ''');
    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_barcode_barcode 
      ON ${AppConstants.tableBarcodeData}(barcode)
    ''');
  }

  Future<void> _createPatientTable(Database db) async {
    // Patients table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS ${AppConstants.tablePatients} (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        age INTEGER NOT NULL,
        gender TEXT NOT NULL,
        weight REAL,
        allergies TEXT,
        conditions TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT
      )
    ''');

    // Create index for patient name
    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_patient_name 
      ON ${AppConstants.tablePatients}(name)
    ''');
  }

  Future<void> _createNotificationsTable(Database db) async {
    // Notifications table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS ${AppConstants.tableNotifications} (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        type TEXT NOT NULL,
        title TEXT NOT NULL,
        body TEXT NOT NULL,
        data TEXT,
        scheduled_at TEXT,
        sent_at TEXT,
        created_at TEXT NOT NULL
      )
    ''');

    // Create indexes for notifications
    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_notification_type 
      ON ${AppConstants.tableNotifications}(type)
    ''');
    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_notification_created_at 
      ON ${AppConstants.tableNotifications}(created_at)
    ''');
  }

  Future<void> _addMedicationMasterDataFields(Database db) async {
    // Add storage_condition column
    try {
      await db.execute('''
        ALTER TABLE ${AppConstants.tableMedications}
        ADD COLUMN storage_condition TEXT
      ''');
    } catch (e) {
      // Column might already exist, ignore error
    }

    // Add is_controlled_drug column
    try {
      await db.execute('''
        ALTER TABLE ${AppConstants.tableMedications}
        ADD COLUMN is_controlled_drug INTEGER DEFAULT 0
      ''');
    } catch (e) {
      // Column might already exist, ignore error
    }

    // Add therapeutic_category column
    try {
      await db.execute('''
        ALTER TABLE ${AppConstants.tableMedications}
        ADD COLUMN therapeutic_category TEXT
      ''');
    } catch (e) {
      // Column might already exist, ignore error
    }
  }

  Future<void> _addStockManagementFields(Database db) async {
    // Add manufacturing_date column
    try {
      await db.execute('''
        ALTER TABLE ${AppConstants.tableStockItems}
        ADD COLUMN manufacturing_date TEXT
      ''');
    } catch (e) {
      // Column might already exist, ignore error
    }

    // Add expected_quantity column
    try {
      await db.execute('''
        ALTER TABLE ${AppConstants.tableStockItems}
        ADD COLUMN expected_quantity INTEGER
      ''');
    } catch (e) {
      // Column might already exist, ignore error
    }
  }

  Future<void> _createStockAdjustmentsTable(Database db) async {
    // Stock adjustments table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS ${AppConstants.tableStockAdjustments} (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        stock_item_id INTEGER NOT NULL,
        old_quantity INTEGER NOT NULL,
        new_quantity INTEGER NOT NULL,
        reason TEXT NOT NULL,
        notes TEXT,
        adjusted_at TEXT NOT NULL,
        adjusted_by TEXT,
        FOREIGN KEY (stock_item_id) REFERENCES ${AppConstants.tableStockItems}(id) ON DELETE CASCADE
      )
    ''');

    // Create indexes for stock adjustments
    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_stock_adjustment_item_id 
      ON ${AppConstants.tableStockAdjustments}(stock_item_id)
    ''');
    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_stock_adjustment_date 
      ON ${AppConstants.tableStockAdjustments}(adjusted_at)
    ''');
  }

  // Medications CRUD
  Future<int> insertMedication(Medication medication) async {
    final db = await database;
    return await db.insert(
      AppConstants.tableMedications,
      medication.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Medication>> getAllMedications() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(AppConstants.tableMedications);
    return List.generate(maps.length, (i) => Medication.fromMap(maps[i]));
  }

  Future<Medication?> getMedicationById(int id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      AppConstants.tableMedications,
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isEmpty) return null;
    return Medication.fromMap(maps.first);
  }

  Future<List<Medication>> searchMedications(String query) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      AppConstants.tableMedications,
      where: 'trade_name LIKE ? OR active_ingredient LIKE ? OR company LIKE ?',
      whereArgs: ['%$query%', '%$query%', '%$query%'],
    );
    return List.generate(maps.length, (i) => Medication.fromMap(maps[i]));
  }

  Future<int> updateMedication(Medication medication) async {
    final db = await database;
    return await db.update(
      AppConstants.tableMedications,
      medication.toMap(),
      where: 'id = ?',
      whereArgs: [medication.id],
    );
  }

  Future<int> deleteMedication(int id) async {
    final db = await database;
    return await db.delete(
      AppConstants.tableMedications,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Stock Items CRUD
  Future<int> insertStockItem(StockItem stockItem) async {
    final db = await database;
    return await db.insert(
      AppConstants.tableStockItems,
      stockItem.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<StockItem>> getAllStockItems() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(AppConstants.tableStockItems);
    return List.generate(maps.length, (i) => StockItem.fromMap(maps[i]));
  }

  Future<List<StockItem>> getStockItemsByMedicationId(int medicationId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      AppConstants.tableStockItems,
      where: 'medication_id = ?',
      whereArgs: [medicationId],
    );
    return List.generate(maps.length, (i) => StockItem.fromMap(maps[i]));
  }

  Future<StockItem?> getStockItemById(int id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      AppConstants.tableStockItems,
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isEmpty) return null;
    return StockItem.fromMap(maps.first);
  }

  Future<int> updateStockItem(StockItem stockItem) async {
    final db = await database;
    return await db.update(
      AppConstants.tableStockItems,
      stockItem.toMap(),
      where: 'id = ?',
      whereArgs: [stockItem.id],
    );
  }

  Future<int> deleteStockItem(int id) async {
    final db = await database;
    return await db.delete(
      AppConstants.tableStockItems,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Stock Adjustments CRUD
  Future<int> insertStockAdjustment(StockAdjustment adjustment) async {
    final db = await database;
    return await db.insert(
      AppConstants.tableStockAdjustments,
      adjustment.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<StockAdjustment>> getAllStockAdjustments() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      AppConstants.tableStockAdjustments,
      orderBy: 'adjusted_at DESC',
    );
    return List.generate(maps.length, (i) => StockAdjustment.fromMap(maps[i]));
  }

  Future<List<StockAdjustment>> getStockAdjustmentsByStockItemId(int stockItemId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      AppConstants.tableStockAdjustments,
      where: 'stock_item_id = ?',
      whereArgs: [stockItemId],
      orderBy: 'adjusted_at DESC',
    );
    return List.generate(maps.length, (i) => StockAdjustment.fromMap(maps[i]));
  }

  Future<StockAdjustment?> getStockAdjustmentById(int id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      AppConstants.tableStockAdjustments,
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isEmpty) return null;
    return StockAdjustment.fromMap(maps.first);
  }

  // Expiry Records CRUD
  Future<int> insertExpiryRecord(ExpiryRecord record) async {
    final db = await database;
    return await db.insert(
      AppConstants.tableExpiryRecords,
      record.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<ExpiryRecord>> getAllExpiryRecords() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(AppConstants.tableExpiryRecords);
    return List.generate(maps.length, (i) => ExpiryRecord.fromMap(maps[i]));
  }

  Future<List<ExpiryRecord>> getExpiryRecordsByStockItemId(int stockItemId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      AppConstants.tableExpiryRecords,
      where: 'stock_item_id = ?',
      whereArgs: [stockItemId],
    );
    return List.generate(maps.length, (i) => ExpiryRecord.fromMap(maps[i]));
  }

  // Get total stock quantity for a medication
  Future<int> getTotalStockQuantity(int medicationId) async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT SUM(quantity) as total FROM ${AppConstants.tableStockItems} WHERE medication_id = ?',
      [medicationId],
    );
    return result.first['total'] as int? ?? 0;
  }

  // Verification Results CRUD
  Future<int> insertVerificationResult(VerificationResult result) async {
    final db = await database;
    return await db.insert(
      AppConstants.tableVerificationResults,
      result.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<VerificationResult>> getVerificationResults() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(AppConstants.tableVerificationResults, orderBy: 'verified_at DESC');
    return List.generate(maps.length, (i) => VerificationResult.fromMap(maps[i]));
  }

  // Audit Logs CRUD
  Future<int> insertAuditLog(AuditLog log) async {
    final db = await database;
    return await db.insert(
      AppConstants.tableAuditLogs,
      log.toMap(),
    );
  }

  Future<List<AuditLog>> getAuditLogs({DateTime? startDate, DateTime? endDate, String? actionType}) async {
    final db = await database;
    String where = '1=1';
    List<dynamic> whereArgs = [];
    
    if (startDate != null) {
      where += ' AND timestamp >= ?';
      whereArgs.add(startDate.toIso8601String());
    }
    if (endDate != null) {
      where += ' AND timestamp <= ?';
      whereArgs.add(endDate.toIso8601String());
    }
    if (actionType != null) {
      where += ' AND action_type = ?';
      whereArgs.add(actionType);
    }
    
    final List<Map<String, dynamic>> maps = await db.query(
      AppConstants.tableAuditLogs,
      where: where,
      whereArgs: whereArgs.isEmpty ? null : whereArgs,
      orderBy: 'timestamp DESC',
    );
    return List.generate(maps.length, (i) => AuditLog.fromMap(maps[i]));
  }

  // MIMS Cache CRUD
  Future<int> insertMimsData(MimsDrugData data) async {
    final db = await database;
    return await db.insert(
      AppConstants.tableMimsCache,
      data.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<MimsDrugData?> getMimsDataByDrugName(String drugName) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      AppConstants.tableMimsCache,
      where: 'drug_name = ?',
      whereArgs: [drugName],
    );
    if (maps.isEmpty) return null;
    return MimsDrugData.fromMap(maps.first);
  }

  Future<List<MimsDrugData>> getAllMimsData() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(AppConstants.tableMimsCache);
    return List.generate(maps.length, (i) => MimsDrugData.fromMap(maps[i]));
  }

  // Drug Interactions CRUD
  Future<int> insertDrugInteraction(DrugInteraction interaction) async {
    final db = await database;
    return await db.insert(
      AppConstants.tableDrugInteractions,
      interaction.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<DrugInteraction>> getDrugInteractions(String medicationId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      AppConstants.tableDrugInteractions,
      where: 'medication1_id = ? OR medication2_id = ?',
      whereArgs: [medicationId, medicationId],
    );
    return List.generate(maps.length, (i) => DrugInteraction.fromMap(maps[i]));
  }

  // Verification History CRUD
  Future<int> insertVerificationHistory(VerificationHistory history) async {
    final db = await database;
    return await db.insert(
      AppConstants.tableVerificationHistory,
      history.toMap(),
    );
  }

  Future<List<VerificationHistory>> getVerificationHistory({int? medicationId, int? limit}) async {
    final db = await database;
    String? where;
    List<dynamic>? whereArgs;
    
    if (medicationId != null) {
      where = 'medication_id = ?';
      whereArgs = [medicationId];
    }
    
    final List<Map<String, dynamic>> maps = await db.query(
      AppConstants.tableVerificationHistory,
      where: where,
      whereArgs: whereArgs,
      orderBy: 'verified_at DESC',
      limit: limit,
    );
    return List.generate(maps.length, (i) => VerificationHistory.fromMap(maps[i]));
  }

  // Reports CRUD
  Future<int> insertReport(Report report) async {
    final db = await database;
    return await db.insert(
      AppConstants.tableReports,
      report.toMap(),
    );
  }

  Future<List<Report>> getReports({ReportType? type}) async {
    final db = await database;
    String? where;
    List<dynamic>? whereArgs;
    
    if (type != null) {
      where = 'type = ?';
      whereArgs = [type.name];
    }
    
    final List<Map<String, dynamic>> maps = await db.query(
      AppConstants.tableReports,
      where: where,
      whereArgs: whereArgs,
      orderBy: 'generated_at DESC',
    );
    return List.generate(maps.length, (i) => Report.fromMap(maps[i]));
  }

  // Barcode Data CRUD
  Future<int> insertBarcodeData(BarcodeData data) async {
    final db = await database;
    return await db.insert(
      AppConstants.tableBarcodeData,
      data.toMap(),
    );
  }

  Future<BarcodeData?> getBarcodeData(String barcode) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      AppConstants.tableBarcodeData,
      where: 'barcode = ?',
      whereArgs: [barcode],
      orderBy: 'scanned_at DESC',
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return BarcodeData.fromMap(maps.first);
  }

  // Patients CRUD
  Future<int> insertPatient(Patient patient) async {
    final db = await database;
    return await db.insert(
      AppConstants.tablePatients,
      patient.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Patient>> getAllPatients() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      AppConstants.tablePatients,
      orderBy: 'name ASC',
    );
    return List.generate(maps.length, (i) => Patient.fromMap(maps[i]));
  }

  Future<Patient?> getPatientById(int id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      AppConstants.tablePatients,
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isEmpty) return null;
    return Patient.fromMap(maps.first);
  }

  Future<List<Patient>> searchPatients(String query) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      AppConstants.tablePatients,
      where: 'name LIKE ?',
      whereArgs: ['%$query%'],
      orderBy: 'name ASC',
    );
    return List.generate(maps.length, (i) => Patient.fromMap(maps[i]));
  }

  Future<int> updatePatient(Patient patient) async {
    final db = await database;
    final updatedPatient = patient.copyWith(updatedAt: DateTime.now());
    return await db.update(
      AppConstants.tablePatients,
      updatedPatient.toMap(),
      where: 'id = ?',
      whereArgs: [patient.id],
    );
  }

  Future<int> deletePatient(int id) async {
    final db = await database;
    return await db.delete(
      AppConstants.tablePatients,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Notifications CRUD
  Future<int> insertNotification(AppNotification notification) async {
    final db = await database;
    return await db.insert(
      AppConstants.tableNotifications,
      notification.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<AppNotification>> getAllNotifications() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      AppConstants.tableNotifications,
      orderBy: 'created_at DESC',
    );
    return List.generate(maps.length, (i) => AppNotification.fromMap(maps[i]));
  }

  Future<List<AppNotification>> getNotificationsByType(NotificationType type) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      AppConstants.tableNotifications,
      where: 'type = ?',
      whereArgs: [type.name],
      orderBy: 'created_at DESC',
    );
    return List.generate(maps.length, (i) => AppNotification.fromMap(maps[i]));
  }

  Future<AppNotification?> getNotificationById(int id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      AppConstants.tableNotifications,
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isEmpty) return null;
    return AppNotification.fromMap(maps.first);
  }

  Future<int> updateNotification(AppNotification notification) async {
    final db = await database;
    return await db.update(
      AppConstants.tableNotifications,
      notification.toMap(),
      where: 'id = ?',
      whereArgs: [notification.id],
    );
  }

  Future<int> deleteNotification(int id) async {
    final db = await database;
    return await db.delete(
      AppConstants.tableNotifications,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Close database
  Future<void> close() async {
    final db = await database;
    await db.close();
  }
}

