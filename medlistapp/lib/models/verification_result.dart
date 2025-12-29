class VerificationResult {
  final int? id;
  final bool isVerified;
  final int? medicationId;
  final String tradeName;
  final List<String>? indications;
  final List<String>? contraindications;
  final List<String>? warnings;
  final List<String>? interactions;
  final String? verificationMethod; // 'search', 'barcode', 'mims'
  final String? barcode;
  final Map<String, dynamic>? mimsData;
  final DateTime verifiedAt;

  VerificationResult({
    this.id,
    required this.isVerified,
    this.medicationId,
    required this.tradeName,
    this.indications,
    this.contraindications,
    this.warnings,
    this.interactions,
    this.verificationMethod,
    this.barcode,
    this.mimsData,
    DateTime? verifiedAt,
  }) : verifiedAt = verifiedAt ?? DateTime.now();

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'is_verified': isVerified,
      'medication_id': medicationId,
      'trade_name': tradeName,
      'indications': indications,
      'contraindications': contraindications,
      'warnings': warnings,
      'interactions': interactions,
      'verification_method': verificationMethod,
      'barcode': barcode,
      'mims_data': mimsData,
      'verified_at': verifiedAt.toIso8601String(),
    };
  }

  // Create from JSON
  factory VerificationResult.fromJson(Map<String, dynamic> json) {
    return VerificationResult(
      id: json['id'],
      isVerified: json['is_verified'] as bool,
      medicationId: json['medication_id'] as int?,
      tradeName: json['trade_name'] as String,
      indications: json['indications'] != null ? List<String>.from(json['indications']) : null,
      contraindications: json['contraindications'] != null ? List<String>.from(json['contraindications']) : null,
      warnings: json['warnings'] != null ? List<String>.from(json['warnings']) : null,
      interactions: json['interactions'] != null ? List<String>.from(json['interactions']) : null,
      verificationMethod: json['verification_method'] as String?,
      barcode: json['barcode'] as String?,
      mimsData: json['mims_data'] != null ? Map<String, dynamic>.from(json['mims_data']) : null,
      verifiedAt: DateTime.parse(json['verified_at'] as String),
    );
  }

  // Convert to Map for database
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'is_verified': isVerified ? 1 : 0,
      'medication_id': medicationId,
      'trade_name': tradeName,
      'indications': indications != null ? indications!.join('|') : null,
      'contraindications': contraindications != null ? contraindications!.join('|') : null,
      'warnings': warnings != null ? warnings!.join('|') : null,
      'interactions': interactions != null ? interactions!.join('|') : null,
      'verification_method': verificationMethod,
      'barcode': barcode,
      'mims_data': mimsData != null ? mimsData.toString() : null,
      'verified_at': verifiedAt.toIso8601String(),
    };
  }

  // Create from Map
  factory VerificationResult.fromMap(Map<String, dynamic> map) {
    return VerificationResult(
      id: map['id'],
      isVerified: map['is_verified'] == 1,
      medicationId: map['medication_id'],
      tradeName: map['trade_name'],
      indications: map['indications'] != null ? (map['indications'] as String).split('|') : null,
      contraindications: map['contraindications'] != null ? (map['contraindications'] as String).split('|') : null,
      warnings: map['warnings'] != null ? (map['warnings'] as String).split('|') : null,
      interactions: map['interactions'] != null ? (map['interactions'] as String).split('|') : null,
      verificationMethod: map['verification_method'],
      barcode: map['barcode'],
      mimsData: map['mims_data'] != null ? Map<String, dynamic>.from(map['mims_data']) : null,
      verifiedAt: DateTime.parse(map['verified_at']),
    );
  }
}

