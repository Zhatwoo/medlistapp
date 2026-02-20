import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:medlistapp/models/medication.dart';
import 'package:medlistapp/services/databaseservice.dart';

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

  // Parse MOH data from markdown file path (for file system access)
  static Future<List<Medication>> parseMOHFromFile(String filePath) async {
    // This would require file system access
    // For now, we'll use the asset-based approach
    throw UnimplementedError('File-based parsing not yet implemented');
  }
}

