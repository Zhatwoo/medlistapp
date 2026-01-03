import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:excel/excel.dart';
import 'package:sqflite/sqflite.dart';
import 'package:medlistapp/models/medication.dart';
import 'package:medlistapp/services/databaseservice.dart';
import 'package:medlistapp/services/firestoremedicineservice.dart';
import 'package:medlistapp/utils/constants.dart';

class MOHDataParser {
  // Parse markdown table line
  static List<String> _parseTableRow(String line) {
    // Remove leading and trailing |
    line = line.trim();
    if (line.startsWith('|')) line = line.substring(1);
    if (line.endsWith('|')) line = line.substring(0, line.length - 1);
    
    // Split by | and trim each cell
    final cells = line.split('|').map((cell) => cell.trim()).toList();
    return cells;
  }

  // Parse price string to double
  static double _parsePrice(String priceStr) {
    if (priceStr.isEmpty) return 0.0;
    try {
      // Remove any non-numeric characters except decimal point
      final cleaned = priceStr.replaceAll(RegExp(r'[^\d.]'), '');
      return double.parse(cleaned);
    } catch (e) {
      return 0.0;
    }
  }

  // Parse MOH markdown file
  static Future<List<Medication>> parseMOHMarkdown(String markdownContent) async {
    final lines = markdownContent.split('\n');
    final medications = <Medication>[];
    
    bool inTable = false;
    int headerRowIndex = -1;
    List<String>? headers;
    
    for (int i = 0; i < lines.length; i++) {
      final line = lines[i].trim();
      
      // Skip empty lines
      if (line.isEmpty) continue;
      
      // Check if this is a table row
      if (line.startsWith('|')) {
        final cells = _parseTableRow(line);
        
        // Check if this is a header row (contains "Trade Name" or "Sl #")
        if (line.contains('Trade Name') || line.contains('Sl #')) {
          headers = cells;
          headerRowIndex = i;
          inTable = true;
          continue;
        }
        
        // Check if this is a separator row (all dashes)
        if (line.replaceAll(RegExp(r'[|\s-]'), '').isEmpty) {
          continue;
        }
        
        // If we're in a table and have headers, parse data rows
        if (inTable && headers != null && cells.length >= headers.length) {
          try {
            // Skip header rows and metadata rows
            if (cells[0].toLowerCase().contains('sl #') ||
                cells[0].toLowerCase().contains('trade name') ||
                cells[0].toLowerCase().contains('united arab') ||
                cells[0].toLowerCase().contains('ministry') ||
                cells[0].toLowerCase().contains('drug department') ||
                cells[0].toLowerCase().contains('price list') ||
                cells[0].toLowerCase().contains('font colour') ||
                cells[0].toLowerCase().contains('copying') ||
                cells[0].toLowerCase().contains('accordance')) {
              continue;
            }
            
            // Skip if first cell is not a number (likely a header or metadata)
            if (cells[0].isEmpty || !RegExp(r'^\d+$').hasMatch(cells[0])) {
              continue;
            }
            
            // Map cells to medication fields
            // Expected order: Sl #, Trade Name, Form, Pack Size, Pharmacy Price, Public Price, Active Ingredient, Strength, Company, Source, Agent, Dispensing Mode, Selection
            if (cells.length >= 12) {
              final medication = Medication(
                tradeName: cells[1].isEmpty ? 'Unknown' : cells[1],
                form: cells[2].isEmpty ? 'Unknown' : cells[2],
                packSize: cells[3].isEmpty ? 'Unknown' : cells[3],
                pharmacyPrice: _parsePrice(cells[4]),
                publicPrice: _parsePrice(cells[5]),
                activeIngredient: cells[6].isEmpty ? 'Unknown' : cells[6].replaceAll('\n', ' ').trim(),
                strength: cells[7].isEmpty ? 'Unknown' : cells[7].replaceAll('\n', ' ').trim(),
                company: cells[8].isEmpty ? 'Unknown' : cells[8],
                source: cells[9].isEmpty ? 'Unknown' : cells[9],
                agent: cells[10].isEmpty ? 'Unknown' : cells[10],
                dispensingMode: cells[11].isEmpty ? 'Unknown' : cells[11],
                selection: cells.length > 12 ? cells[12] : null,
              );
              
              medications.add(medication);
            }
          } catch (e) {
            // Skip rows that fail to parse
            continue;
          }
        }
      } else {
        // If we hit a non-table line after being in a table, we might be done
        // But continue to check for more tables
        if (inTable && line.startsWith('##')) {
          inTable = false;
          headers = null;
        }
      }
    }
    
    return medications;
  }

  // Load and parse MOH data from asset
  static Future<List<Medication>> loadMOHDataFromAsset(String assetPath) async {
    try {
      final String content = await rootBundle.loadString(assetPath);
      return await parseMOHMarkdown(content);
    } catch (e) {
      throw Exception('Failed to load MOH data: $e');
    }
  }

  // Load MOH data and save to database
  static Future<void> loadAndSaveMOHData(String assetPath) async {
    try {
      final medications = await loadMOHDataFromAsset(assetPath);
      final dbService = DatabaseService();
      
      // Clear existing data (optional - you might want to keep existing stock)
      // await dbService.deleteAllMedications(); // Uncomment if needed
      
      // Insert medications
      for (final medication in medications) {
        await dbService.insertMedication(medication);
      }
    } catch (e) {
      throw Exception('Failed to load and save MOH data: $e');
    }
  }

  // Parse MOH data from XLSX file
  static Future<List<Medication>> parseMOHFromXLSX(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        throw Exception('File not found: $filePath');
      }

      print('Reading Excel file: ${file.path}');
      final bytes = await file.readAsBytes();
      print('File size: ${bytes.length} bytes');
      
      final excel = Excel.decodeBytes(bytes);
      final medications = <Medication>[];

      // Get the first sheet (usually the data sheet)
      if (excel.tables.isEmpty) {
        throw Exception('Excel file has no sheets');
      }

      final sheetName = excel.tables.keys.first;
      final sheet = excel.tables[sheetName]!;
      print('Processing sheet: $sheetName, Rows: ${sheet.maxRows}');
      
      // Find header row (usually row 0 or 1)
      int headerRowIndex = -1;
      Map<String, int> columnMap = {};
      
      // Try to find header row by checking first 15 rows
      for (int row = 0; row < sheet.maxRows && row < 15; row++) {
        final rowData = sheet.rows[row];
        if (rowData.isEmpty) continue;
        
        // Check if this row contains headers
        bool isHeaderRow = false;
        int headerCount = 0;
        
        for (int col = 0; col < rowData.length && col < 20; col++) {
          final cellValue = rowData[col]?.value?.toString().toLowerCase().trim() ?? '';
          if (cellValue.contains('trade name') || 
              cellValue.contains('sl #') || 
              cellValue.contains('form') ||
              cellValue.contains('pack size') ||
              cellValue.contains('pharmacy price')) {
            isHeaderRow = true;
            headerCount++;
          }
        }
        
        // If we found enough header indicators, this is likely the header row
        if (isHeaderRow && headerCount >= 3) {
          headerRowIndex = row;
          
          // Map column names to indices
          for (int col = 0; col < rowData.length; col++) {
            final cellValue = rowData[col]?.value?.toString().toLowerCase().trim() ?? '';
            if (cellValue.contains('trade name') || cellValue == 'trade name') {
              columnMap['tradeName'] = col;
            } else if (cellValue.contains('form') && !cellValue.contains('pack')) {
              columnMap['form'] = col;
            } else if (cellValue.contains('pack size') || cellValue.contains('pack size')) {
              columnMap['packSize'] = col;
            } else if (cellValue.contains('pharmacy price') || cellValue.contains('pharmacy')) {
              columnMap['pharmacyPrice'] = col;
            } else if (cellValue.contains('public price') || cellValue.contains('public')) {
              columnMap['publicPrice'] = col;
            } else if (cellValue.contains('active ingredient') || cellValue.contains('ingredient')) {
              columnMap['activeIngredient'] = col;
            } else if (cellValue.contains('strength')) {
              columnMap['strength'] = col;
            } else if (cellValue.contains('company') || cellValue.contains('manufacturer')) {
              columnMap['company'] = col;
            } else if (cellValue.contains('source')) {
              columnMap['source'] = col;
            } else if (cellValue.contains('agent')) {
              columnMap['agent'] = col;
            } else if (cellValue.contains('dispensing mode') || cellValue.contains('dispensing')) {
              columnMap['dispensingMode'] = col;
            } else if (cellValue.contains('selection')) {
              columnMap['selection'] = col;
            } else if (cellValue.contains('storage condition') || cellValue.contains('storage')) {
              columnMap['storageCondition'] = col;
            } else if (cellValue.contains('controlled drug') || cellValue.contains('controlled')) {
              columnMap['isControlledDrug'] = col;
            } else if (cellValue.contains('therapeutic category') || cellValue.contains('category')) {
              columnMap['therapeuticCategory'] = col;
            }
          }
          
          // If we found enough column mappings, break
          if (columnMap.length >= 5) break;
        }
      }

      // If no header row found, try default column positions
      if (headerRowIndex == -1 || columnMap.isEmpty) {
        // Default MOH Price List format: Sl #, Trade Name, Form, Pack Size, Pharmacy Price, Public Price, Active Ingredient, Strength, Company, Source, Agent, Dispensing Mode, Selection
        columnMap = {
          'tradeName': 1,
          'form': 2,
          'packSize': 3,
          'pharmacyPrice': 4,
          'publicPrice': 5,
          'activeIngredient': 6,
          'strength': 7,
          'company': 8,
          'source': 9,
          'agent': 10,
          'dispensingMode': 11,
          'selection': 12,
        };
        headerRowIndex = 0;
      }

      // Parse data rows
      for (int row = headerRowIndex + 1; row < sheet.maxRows; row++) {
        final rowData = sheet.rows[row];
        if (rowData.isEmpty) continue;

        try {
          // Get cell values
          final getCell = (String key) {
            final col = columnMap[key];
            if (col == null || col >= rowData.length) return '';
            final cell = rowData[col];
            if (cell == null) return '';
            return cell.value?.toString().trim() ?? '';
          };

          final tradeName = getCell('tradeName');
          
          // Skip empty rows or header-like rows
          final tradeNameLower = tradeName.toLowerCase().trim();
          if (tradeName.isEmpty || 
              tradeNameLower.contains('trade name') ||
              tradeNameLower.contains('sl #') ||
              tradeNameLower.contains('sl#') ||
              tradeNameLower == 'united arab' ||
              tradeNameLower.contains('ministry') ||
              tradeNameLower.contains('emirates') ||
              tradeNameLower == 'total' ||
              RegExp(r'^[0-9\s]+$').hasMatch(tradeName) && tradeName.length < 5) {
            continue;
          }

          // Parse prices
          final pharmacyPrice = _parsePrice(getCell('pharmacyPrice'));
          final publicPrice = _parsePrice(getCell('publicPrice'));

          // Create medication
          final medication = Medication(
            tradeName: tradeName.isEmpty ? 'Unknown' : tradeName,
            form: getCell('form').isEmpty ? 'Unknown' : getCell('form'),
            packSize: getCell('packSize').isEmpty ? 'Unknown' : getCell('packSize'),
            pharmacyPrice: pharmacyPrice,
            publicPrice: publicPrice,
            activeIngredient: getCell('activeIngredient').isEmpty 
                ? 'Unknown' 
                : getCell('activeIngredient').replaceAll('\n', ' ').trim(),
            strength: getCell('strength').isEmpty 
                ? 'Unknown' 
                : getCell('strength').replaceAll('\n', ' ').trim(),
            company: getCell('company').isEmpty ? 'Unknown' : getCell('company'),
            source: getCell('source').isEmpty ? 'Unknown' : getCell('source'),
            agent: getCell('agent').isEmpty ? 'Unknown' : getCell('agent'),
            dispensingMode: getCell('dispensingMode').isEmpty 
                ? 'Unknown' 
                : getCell('dispensingMode'),
            selection: getCell('selection').isEmpty ? null : getCell('selection'),
            storageCondition: getCell('storageCondition').isEmpty 
                ? null 
                : getCell('storageCondition'),
            isControlledDrug: getCell('isControlledDrug').toLowerCase().contains('yes') ||
                            getCell('isControlledDrug').toLowerCase().contains('true') ||
                            getCell('isControlledDrug') == '1',
            therapeuticCategory: getCell('therapeuticCategory').isEmpty 
                ? null 
                : getCell('therapeuticCategory'),
          );

          medications.add(medication);
        } catch (e) {
          // Skip rows that fail to parse
          continue;
        }
      }

      return medications;
    } catch (e) {
      throw Exception('Failed to parse XLSX file: $e');
    }
  }

  // Import MOH data from XLSX file and save to Firestore and database
  static Future<ImportResult> importMOHFromXLSX(
    String filePath, {
    bool clearExisting = false,
    String? companyCode,
  }) async {
    try {
      print('Starting XLSX import from: $filePath');
      final medications = await parseMOHFromXLSX(filePath);
      print('Parsed ${medications.length} medications from file');
      
      if (medications.isEmpty) {
        return ImportResult(
          success: false,
          message: 'No medications found in the file. Please check the file format.',
          importedCount: 0,
          skippedCount: 0,
        );
      }

      // Validate company code
      if (companyCode == null || companyCode.trim().isEmpty) {
        return ImportResult(
          success: false,
          message: 'Company code is required to import medications.',
          importedCount: 0,
          skippedCount: 0,
        );
      }

      final normalizedCode = companyCode.trim().toUpperCase();
      final firestoreService = FirestoreMedicineService();
      final dbService = DatabaseService();
      
      // Clear existing data if requested
      if (clearExisting) {
        print('Clearing existing medicines for company: $normalizedCode');
        // Clear from Firestore
        try {
          await firestoreService.deleteAllMedicines(normalizedCode);
        } catch (e) {
          print('Warning: Failed to clear Firestore medicines: $e');
        }
        
        // Clear from SQLite (for backward compatibility)
        try {
          final allMeds = await dbService.getAllMedications(companyCode: normalizedCode);
          for (final med in allMeds) {
            if (med.id != null) {
              await dbService.deleteMedication(med.id!);
            }
          }
        } catch (e) {
          print('Warning: Failed to clear SQLite medicines: $e');
        }
      }

      // Filter valid medications
      final validMedications = medications.where((med) {
        return med.tradeName.isNotEmpty && med.tradeName != 'Unknown';
      }).toList();

      int imported = 0;
      int skipped = medications.length - validMedications.length;

      // Save to Firestore in batches
      print('Saving ${validMedications.length} medicines to Firestore...');
      try {
        await firestoreService.addMedicinesBatch(validMedications, normalizedCode);
        imported = validMedications.length;
        print('Successfully saved $imported medicines to Firestore');
      } catch (e) {
        print('Error saving to Firestore: $e');
        // Continue to save to SQLite as fallback
      }

      // Also save to SQLite for backward compatibility and offline support
      print('Saving medicines to SQLite for offline support...');
      final database = await dbService.database;
      const batchSize = 100;

      for (int i = 0; i < validMedications.length; i += batchSize) {
        final batch = validMedications.skip(i).take(batchSize).toList();
        
        try {
          await database.transaction((txn) async {
            for (final medication in batch) {
              try {
                final medicationMap = medication.toMap();
                medicationMap.remove('id');
                medicationMap['company_code'] = normalizedCode;
                
                await txn.insert(
                  AppConstants.tableMedications,
                  medicationMap,
                  conflictAlgorithm: ConflictAlgorithm.replace,
                );
              } catch (e) {
                print('Error inserting medication to SQLite ${medication.tradeName}: $e');
              }
            }
          });
        } catch (e) {
          print('Batch SQLite insert failed: $e');
        }

        // Yield to UI thread
        if (i + batchSize < validMedications.length) {
          await Future.delayed(const Duration(milliseconds: 50));
        }
      }

      // Verify import by checking Firestore
      final firestoreCount = await firestoreService.getMedicinesCount(normalizedCode);
      print('Import complete. Imported: $imported, Skipped: $skipped, Total in Firestore: $firestoreCount');
      
      return ImportResult(
        success: true,
        message: 'Successfully imported $imported medications to company "$normalizedCode"\n'
            'Total medications in Firestore: $firestoreCount\n'
            'Medicines are now shared with all users in your company.',
        importedCount: imported,
        skippedCount: skipped,
      );
    } catch (e, stackTrace) {
      print('Import error: $e');
      print('Stack trace: $stackTrace');
      return ImportResult(
        success: false,
        message: 'Failed to import: ${e.toString()}\n\nPlease check the file format and try again.',
        importedCount: 0,
        skippedCount: 0,
      );
    }
  }

  // Parse MOH data from markdown file path (for file system access)
  static Future<List<Medication>> parseMOHFromFile(String filePath) async {
    // This would require file system access
    // For now, we'll use the asset-based approach
    throw UnimplementedError('File-based parsing not yet implemented');
  }
}

// Import result class
class ImportResult {
  final bool success;
  final String message;
  final int importedCount;
  final int skippedCount;

  ImportResult({
    required this.success,
    required this.message,
    required this.importedCount,
    required this.skippedCount,
  });
}

