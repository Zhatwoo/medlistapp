class Patient {
  final int? id;
  final String name;
  final int? age;
  final String? gender;
  final double? weight;
  final List<String> allergies;
  final List<String> conditions;
  final List<String> medications;
  final String? notes;
  final DateTime createdAt;
  final DateTime? updatedAt;

  Patient({
    this.id,
    required this.name,
    this.age,
    this.gender,
    this.weight,
    this.allergies = const [],
    this.conditions = const [],
    this.medications = const [],
    this.notes,
    DateTime? createdAt,
    this.updatedAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'age': age,
      'gender': gender,
      'weight': weight,
      'allergies': allergies.isEmpty ? null : allergies.join('|'),
      'conditions': conditions.isEmpty ? null : conditions.join('|'),
      'medications': medications.isEmpty ? null : medications.join('|'),
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  factory Patient.fromMap(Map<String, dynamic> map) {
    return Patient(
      id: map['id'] as int?,
      name: map['name'] as String,
      age: map['age'] as int?,
      gender: map['gender'] as String?,
      weight: map['weight'] != null ? (map['weight'] as num).toDouble() : null,
      allergies: map['allergies'] != null
          ? (map['allergies'] as String).split('|').where((s) => s.isNotEmpty).toList()
          : [],
      conditions: map['conditions'] != null
          ? (map['conditions'] as String).split('|').where((s) => s.isNotEmpty).toList()
          : [],
      medications: map['medications'] != null
          ? (map['medications'] as String).split('|').where((s) => s.isNotEmpty).toList()
          : [],
      notes: map['notes'] as String?,
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String)
          : null,
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'] as String)
          : null,
    );
  }

  Patient copyWith({
    int? id,
    String? name,
    int? age,
    String? gender,
    double? weight,
    List<String>? allergies,
    List<String>? conditions,
    List<String>? medications,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Patient(
      id: id ?? this.id,
      name: name ?? this.name,
      age: age ?? this.age,
      gender: gender ?? this.gender,
      weight: weight ?? this.weight,
      allergies: allergies ?? this.allergies,
      conditions: conditions ?? this.conditions,
      medications: medications ?? this.medications,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
