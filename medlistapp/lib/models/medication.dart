class Medication {
  final int? id;
  final String tradeName;
  final String form;
  final String packSize;
  final double pharmacyPrice;
  final double publicPrice;
  final String activeIngredient;
  final String strength;
  final String company;
  final String source;
  final String agent;
  final String dispensingMode;
  final String? selection;
  final String? storageCondition;
  final bool isControlledDrug;
  final String? therapeuticCategory;

  Medication({
    this.id,
    required this.tradeName,
    required this.form,
    required this.packSize,
    required this.pharmacyPrice,
    required this.publicPrice,
    required this.activeIngredient,
    required this.strength,
    required this.company,
    required this.source,
    required this.agent,
    required this.dispensingMode,
    this.selection,
    this.storageCondition,
    this.isControlledDrug = false,
    this.therapeuticCategory,
  });

  // Convert to Map for database
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'trade_name': tradeName,
      'form': form,
      'pack_size': packSize,
      'pharmacy_price': pharmacyPrice,
      'public_price': publicPrice,
      'active_ingredient': activeIngredient,
      'strength': strength,
      'company': company,
      'source': source,
      'agent': agent,
      'dispensing_mode': dispensingMode,
      'selection': selection,
      'storage_condition': storageCondition,
      'is_controlled_drug': isControlledDrug ? 1 : 0,
      'therapeutic_category': therapeuticCategory,
    };
  }

  // Create from Map (database)
  factory Medication.fromMap(Map<String, dynamic> map) {
    return Medication(
      id: map['id'] as int?,
      tradeName: map['trade_name'] as String,
      form: map['form'] as String,
      packSize: map['pack_size'] as String,
      pharmacyPrice: (map['pharmacy_price'] as num).toDouble(),
      publicPrice: (map['public_price'] as num).toDouble(),
      activeIngredient: map['active_ingredient'] as String,
      strength: map['strength'] as String,
      company: map['company'] as String,
      source: map['source'] as String,
      agent: map['agent'] as String,
      dispensingMode: map['dispensing_mode'] as String,
      selection: map['selection'] as String?,
      storageCondition: map['storage_condition'] as String?,
      isControlledDrug: (map['is_controlled_drug'] as int?) == 1,
      therapeuticCategory: map['therapeutic_category'] as String?,
    );
  }

  // Convert to JSON
  Map<String, dynamic> toJson() => toMap();

  // Create from JSON
  factory Medication.fromJson(Map<String, dynamic> json) => Medication.fromMap(json);

  // Create a copy with updated fields
  Medication copyWith({
    int? id,
    String? tradeName,
    String? form,
    String? packSize,
    double? pharmacyPrice,
    double? publicPrice,
    String? activeIngredient,
    String? strength,
    String? company,
    String? source,
    String? agent,
    String? dispensingMode,
    String? selection,
    String? storageCondition,
    bool? isControlledDrug,
    String? therapeuticCategory,
  }) {
    return Medication(
      id: id ?? this.id,
      tradeName: tradeName ?? this.tradeName,
      form: form ?? this.form,
      packSize: packSize ?? this.packSize,
      pharmacyPrice: pharmacyPrice ?? this.pharmacyPrice,
      publicPrice: publicPrice ?? this.publicPrice,
      activeIngredient: activeIngredient ?? this.activeIngredient,
      strength: strength ?? this.strength,
      company: company ?? this.company,
      source: source ?? this.source,
      agent: agent ?? this.agent,
      dispensingMode: dispensingMode ?? this.dispensingMode,
      selection: selection ?? this.selection,
      storageCondition: storageCondition ?? this.storageCondition,
      isControlledDrug: isControlledDrug ?? this.isControlledDrug,
      therapeuticCategory: therapeuticCategory ?? this.therapeuticCategory,
    );
  }
}

