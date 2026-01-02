enum Gender {
  male,
  female,
  other,
}

class Patient {
  final int? id;
  final String name;
  final int age;
  final Gender gender;
  final double? weight;
  final List<String> allergies;
  final List<String> conditions;
  final DateTime createdAt;
  final DateTime? updatedAt;

  Patient({
    this.id,
    required this.name,
    required this.age,
    required this.gender,
    this.weight,
    required this.allergies,
    required this.conditions,
    DateTime? createdAt,
    this.updatedAt,
  }) : createdAt = createdAt ?? DateTime.now();

  // Convert to Map for database
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'age': age,
      'gender': gender.name,
      'weight': weight,
      'allergies': _listToJson(allergies),
      'conditions': _listToJson(conditions),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  // Create from Map (database)
  factory Patient.fromMap(Map<String, dynamic> map) {
    return Patient(
      id: map['id'] as int?,
      name: map['name'] as String,
      age: map['age'] as int,
      gender: Gender.values.firstWhere(
        (e) => e.name == map['gender'],
        orElse: () => Gender.other,
      ),
      weight: map['weight'] as double?,
      allergies: _jsonToList(map['allergies'] as String?),
      conditions: _jsonToList(map['conditions'] as String?),
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'] as String)
          : null,
    );
  }

  // Convert to JSON
  Map<String, dynamic> toJson() => toMap();

  // Create from JSON
  factory Patient.fromJson(Map<String, dynamic> json) => Patient.fromMap(json);

  // Create a copy with updated fields
  Patient copyWith({
    int? id,
    String? name,
    int? age,
    Gender? gender,
    double? weight,
    List<String>? allergies,
    List<String>? conditions,
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
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Helper methods for JSON conversion
  static String _listToJson(List<String> list) {
    if (list.isEmpty) return '[]';
    return '[' + list.map((item) => '"${item.replaceAll('"', '\\"')}"').join(',') + ']';
  }

  static List<String> _jsonToList(String? json) {
    if (json == null || json.isEmpty || json == '[]') return [];
    try {
      // Handle JSON array format
      if (json.startsWith('[') && json.endsWith(']')) {
        final cleaned = json.substring(1, json.length - 1);
        if (cleaned.isEmpty) return [];
        return cleaned
            .split(',')
            .map((item) => item.trim().replaceAll('"', '').replaceAll("'", ''))
            .where((item) => item.isNotEmpty)
            .toList();
      }
      // Fallback to comma-separated for backward compatibility
      return json.split(',').map((item) => item.trim()).where((item) => item.isNotEmpty).toList();
    } catch (e) {
      // Fallback to comma-separated
      return json.split(',').map((item) => item.trim()).where((item) => item.isNotEmpty).toList();
    }
  }
}

