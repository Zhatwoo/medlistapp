import 'package:medlistapp/models/mimsdrugdata.dart';
import 'package:medlistapp/services/databaseservice.dart';
import 'package:medlistapp/utils/constants.dart';

class MimsCacheService {
  final DatabaseService _dbService = DatabaseService();

  // Cache drug data
  Future<void> cacheDrug(MimsDrugData drug) async {
    await _dbService.insertMimsData(drug);
  }

  // Get cached drug by name
  Future<MimsDrugData?> getCachedDrug(String drugName) async {
    return await _dbService.getMimsDataByDrugName(drugName);
  }

  // Get all cached drugs
  Future<List<MimsDrugData>> getAllCachedDrugs() async {
    return await _dbService.getAllMimsData();
  }

  // Clear expired cache (older than specified days)
  Future<void> clearExpiredCache(int daysOld) async {
    final db = await _dbService.database;
    final cutoffDate = DateTime.now().subtract(Duration(days: daysOld));
    await db.delete(
      AppConstants.tableMimsCache,
      where: 'cached_at < ?',
      whereArgs: [cutoffDate.toIso8601String()],
    );
  }

  // Clear all cache
  Future<void> clearAllCache() async {
    final db = await _dbService.database;
    await db.delete(AppConstants.tableMimsCache);
  }

  // Check if drug is cached
  Future<bool> isCached(String drugName) async {
    final cached = await getCachedDrug(drugName);
    return cached != null;
  }
}

