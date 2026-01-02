enum InteractionSeverity {
  mild,
  moderate,
  severe,
  contraindicated,
}

class DrugInteraction {
  final int? id;
  final String medication1Id;
  final String medication1Name;
  final String medication2Id;
  final String medication2Name;
  final InteractionSeverity severity;
  final String description;
  final String? recommendation;
  final String? alternativeMedications;
  final DateTime detectedAt;

  DrugInteraction({
    this.id,
    required this.medication1Id,
    required this.medication1Name,
    required this.medication2Id,
    required this.medication2Name,
    required this.severity,
    required this.description,
    this.recommendation,
    this.alternativeMedications,
    DateTime? detectedAt,
  }) : detectedAt = detectedAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'medication1_id': medication1Id,
      'medication1_name': medication1Name,
      'medication2_id': medication2Id,
      'medication2_name': medication2Name,
      'severity': severity.name,
      'description': description,
      'recommendation': recommendation,
      'alternative_medications': alternativeMedications,
      'detected_at': detectedAt.toIso8601String(),
    };
  }

  factory DrugInteraction.fromMap(Map<String, dynamic> map) {
    return DrugInteraction(
      id: map['id'],
      medication1Id: map['medication1_id'],
      medication1Name: map['medication1_name'],
      medication2Id: map['medication2_id'],
      medication2Name: map['medication2_name'],
      severity: InteractionSeverity.values.firstWhere(
        (e) => e.name == map['severity'],
        orElse: () => InteractionSeverity.mild,
      ),
      description: map['description'],
      recommendation: map['recommendation'],
      alternativeMedications: map['alternative_medications'],
      detectedAt: DateTime.parse(map['detected_at']),
    );
  }
}

