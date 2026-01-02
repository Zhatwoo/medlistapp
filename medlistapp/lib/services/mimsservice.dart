import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:medlistapp/models/mimsdrugdata.dart';
import 'package:medlistapp/services/mimscacheservice.dart';
import 'package:medlistapp/services/databaseservice.dart';
import 'package:medlistapp/utils/constants.dart';

class MimsService {
  static const String _apiBaseUrl = 'https://api.mims.com'; // Replace with actual MIMS API URL
  static const String _apiKeyPref = 'mims_api_key';
  static const String _apiSecretPref = 'mims_api_secret';
  static const String _apiTokenPref = 'mims_api_token';
  static const String _tokenExpiryPref = 'mims_token_expiry';

  final MimsCacheService _cacheService = MimsCacheService();
  final DatabaseService _dbService = DatabaseService();
  String? _cachedToken;
  DateTime? _tokenExpiry;

  // Get API credentials from secure storage
  Future<Map<String, String>> _getCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    final apiKey = prefs.getString(_apiKeyPref);
    final apiSecret = prefs.getString(_apiSecretPref);
    
    if (apiKey == null || apiSecret == null) {
      throw Exception('MIMS API credentials not configured. Please set them in Settings.');
    }
    
    return {'apiKey': apiKey, 'apiSecret': apiSecret};
  }

  // Authenticate with MIMS API
  Future<String> _authenticate() async {
    // Check if we have a valid cached token
    if (_cachedToken != null && _tokenExpiry != null && DateTime.now().isBefore(_tokenExpiry!)) {
      return _cachedToken!;
    }

    try {
      final credentials = await _getCredentials();
      final response = await http.post(
        Uri.parse('$_apiBaseUrl/auth/token'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'api_key': credentials['apiKey'],
          'api_secret': credentials['apiSecret'],
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final token = data['token'] as String;
        final expirySeconds = data['expires_in'] as int? ?? 3600;
        
        _cachedToken = token;
        _tokenExpiry = DateTime.now().add(Duration(seconds: expirySeconds));
        
        // Cache token in preferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_apiTokenPref, token);
        await prefs.setString(_tokenExpiryPref, _tokenExpiry!.toIso8601String());
        
        return token;
      } else {
        throw Exception('MIMS authentication failed: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to authenticate with MIMS: $e');
    }
  }

  // Get authorization header
  Future<Map<String, String>> _getAuthHeaders() async {
    final token = await _authenticate();
    return {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };
  }

  // Search drug by name or code
  Future<List<MimsDrugData>> searchDrug(String query) async {
    try {
      // Check cache first
      final cached = await _cacheService.getCachedDrug(query);
      if (cached != null) {
        return [cached];
      }

      // If offline, return cached data
      final prefs = await SharedPreferences.getInstance();
      final offlineMode = prefs.getBool('offline_mode') ?? false;
      if (offlineMode) {
        final allCached = await _cacheService.getAllCachedDrugs();
        return allCached.where((drug) => 
          drug.drugName.toLowerCase().contains(query.toLowerCase()) ||
          (drug.genericName?.toLowerCase().contains(query.toLowerCase()) ?? false)
        ).toList();
      }

      // Search via API
      final headers = await _getAuthHeaders();
      final response = await http.get(
        Uri.parse('$_apiBaseUrl/drugs/search?q=${Uri.encodeComponent(query)}'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> results = data['results'] ?? [];
        
        final drugs = results.map((item) => _parseDrugData(item)).toList();
        
        // Cache results
        for (final drug in drugs) {
          await _cacheService.cacheDrug(drug);
        }
        
        return drugs;
      } else {
        throw Exception('MIMS search failed: ${response.statusCode}');
      }
    } catch (e) {
      // Fallback to cache on error
      final cached = await _cacheService.getAllCachedDrugs();
      return cached.where((drug) => 
        drug.drugName.toLowerCase().contains(query.toLowerCase())
      ).toList();
    }
  }

  // Get full drug monograph
  Future<MimsDrugData?> getDrugMonograph(String drugCode) async {
    try {
      // Check cache first
      final cached = await _dbService.getMimsDataByDrugName(drugCode);
      if (cached != null) {
        return cached;
      }

      // If offline, return null
      final prefs = await SharedPreferences.getInstance();
      final offlineMode = prefs.getBool('offline_mode') ?? false;
      if (offlineMode) {
        return null;
      }

      // Fetch from API
      final headers = await _getAuthHeaders();
      final response = await http.get(
        Uri.parse('$_apiBaseUrl/drugs/$drugCode'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final drug = _parseDrugData(data);
        
        // Cache the monograph
        await _cacheService.cacheDrug(drug);
        
        return drug;
      } else {
        return null;
      }
    } catch (e) {
      return null;
    }
  }

  // Get drug interactions
  Future<Map<String, dynamic>> getDrugInteractions(String drugCode, List<String> otherDrugCodes) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.post(
        Uri.parse('$_apiBaseUrl/drugs/$drugCode/interactions'),
        headers: headers,
        body: jsonEncode({'drug_codes': otherDrugCodes}),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return {};
      }
    } catch (e) {
      return {};
    }
  }

  // Parse drug data from API response
  MimsDrugData _parseDrugData(Map<String, dynamic> data) {
    return MimsDrugData(
      drugCode: data['code'] as String?,
      drugName: data['name'] as String? ?? '',
      genericName: data['generic_name'] as String?,
      therapeuticClass: data['therapeutic_class'] as String?,
      indications: data['indications'] != null ? List<String>.from(data['indications']) : null,
      contraindications: data['contraindications'] != null ? List<String>.from(data['contraindications']) : null,
      dosage: data['dosage'] as String?,
      administration: data['administration'] as String?,
      sideEffects: data['side_effects'] != null ? List<String>.from(data['side_effects']) : null,
      interactions: data['interactions'] != null ? Map<String, dynamic>.from(data['interactions']) : null,
      precautions: data['precautions'] as String?,
      storage: data['storage'] as String?,
      lastUpdated: data['last_updated'] != null ? DateTime.parse(data['last_updated']) : null,
    );
  }

  // Set API credentials
  Future<void> setCredentials(String apiKey, String apiSecret) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_apiKeyPref, apiKey);
    await prefs.setString(_apiSecretPref, apiSecret);
    // Clear cached token to force re-authentication
    _cachedToken = null;
    _tokenExpiry = null;
    await prefs.remove(_apiTokenPref);
    await prefs.remove(_tokenExpiryPref);
  }

  // Check if credentials are configured
  Future<bool> hasCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    final apiKey = prefs.getString(_apiKeyPref);
    final apiSecret = prefs.getString(_apiSecretPref);
    return apiKey != null && apiSecret != null;
  }
}

