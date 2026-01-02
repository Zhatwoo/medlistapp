class MimsDrugData {
  final int? id;
  final String? drugCode;
  final String drugName;
  final String? genericName;
  final String? therapeuticClass;
  final List<String>? indications;
  final List<String>? contraindications;
  final String? dosage;
  final String? administration;
  final List<String>? sideEffects;
  final Map<String, dynamic>? interactions;
  final String? precautions;
  final String? storage;
  final DateTime? lastUpdated;
  final DateTime cachedAt;

  MimsDrugData({
    this.id,
    this.drugCode,
    required this.drugName,
    this.genericName,
    this.therapeuticClass,
    this.indications,
    this.contraindications,
    this.dosage,
    this.administration,
    this.sideEffects,
    this.interactions,
    this.precautions,
    this.storage,
    this.lastUpdated,
    DateTime? cachedAt,
  }) : cachedAt = cachedAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'drug_code': drugCode,
      'drug_name': drugName,
      'generic_name': genericName,
      'therapeutic_class': therapeuticClass,
      'indications': indications != null ? indications!.join('|') : null,
      'contraindications': contraindications != null ? contraindications!.join('|') : null,
      'dosage': dosage,
      'administration': administration,
      'side_effects': sideEffects != null ? sideEffects!.join('|') : null,
      'interactions': interactions != null ? interactions.toString() : null,
      'precautions': precautions,
      'storage': storage,
      'last_updated': lastUpdated?.toIso8601String(),
      'cached_at': cachedAt.toIso8601String(),
    };
  }

  factory MimsDrugData.fromMap(Map<String, dynamic> map) {
    return MimsDrugData(
      id: map['id'],
      drugCode: map['drug_code'],
      drugName: map['drug_name'],
      genericName: map['generic_name'],
      therapeuticClass: map['therapeutic_class'],
      indications: map['indications'] != null ? (map['indications'] as String).split('|') : null,
      contraindications: map['contraindications'] != null ? (map['contraindications'] as String).split('|') : null,
      dosage: map['dosage'],
      administration: map['administration'],
      sideEffects: map['side_effects'] != null ? (map['side_effects'] as String).split('|') : null,
      interactions: map['interactions'] != null ? Map<String, dynamic>.from(map['interactions']) : null,
      precautions: map['precautions'],
      storage: map['storage'],
      lastUpdated: map['last_updated'] != null ? DateTime.parse(map['last_updated']) : null,
      cachedAt: DateTime.parse(map['cached_at']),
    );
  }
}

