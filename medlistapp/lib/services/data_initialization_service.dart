import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import 'package:medlistapp/services/moh_data_parser.dart';
import 'package:medlistapp/services/database_service.dart';
import 'package:medlistapp/utils/constants.dart';

class DataInitializationService {
  static Future<bool> isDataInitialized() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(AppConstants.dataInitializedKey) ?? false;
  }

  static Future<void> initializeData() async {
    try {
      // Check if already initialized
      if (await isDataInitialized()) {
        return;
      }

      // Load and parse MOH data
      final medications = await MOHDataParser.loadMOHDataFromAsset(
        AppConstants.mohDataAssetPath,
      );

      // Save to database in batches to avoid blocking
      final dbService = DatabaseService();
      const batchSize = 500; // Larger batches for better performance
      
      // Get database instance for transactions
      final database = await dbService.database;
      
      for (int i = 0; i < medications.length; i += batchSize) {
        final batch = medications.skip(i).take(batchSize).toList();
        
        // Use transaction for batch insert (much faster)
        await database.transaction((txn) async {
          for (final medication in batch) {
            await txn.insert(
              AppConstants.tableMedications,
              medication.toMap(),
              conflictAlgorithm: ConflictAlgorithm.replace,
            );
          }
        });
        
        // Small delay to prevent UI blocking and allow other operations
        if (i + batchSize < medications.length) {
          await Future.delayed(const Duration(milliseconds: 50));
        }
      }

      // Mark as initialized
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(AppConstants.dataInitializedKey, true);
    } catch (e) {
      throw Exception('Failed to initialize data: $e');
    }
  }

  static Future<void> reinitializeData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppConstants.dataInitializedKey, false);
    await initializeData();
  }
}

