class VerificationHistory {
  final int? id;
  final int? medicationId;
  final String medicationName;
  final bool identityVerified;
  final bool? contraindicationFound;
  final bool? interactionFound;
  final String? verificationMethod; // 'search', 'barcode', 'mims'
  final String? barcode;
  final String? notes;
  final DateTime verifiedAt;

  VerificationHistory({
    this.id,
    this.medicationId,
    required this.medicationName,
    required this.identityVerified,
    this.contraindicationFound,
    this.interactionFound,
    this.verificationMethod,
    this.barcode,
    this.notes,
    DateTime? verifiedAt,
  }) : verifiedAt = verifiedAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'medication_id': medicationId,
      'medication_name': medicationName,
      'identity_verified': identityVerified ? 1 : 0,
      'contraindication_found': contraindicationFound != null ? (contraindicationFound! ? 1 : 0) : null,
      'interaction_found': interactionFound != null ? (interactionFound! ? 1 : 0) : null,
      'verification_method': verificationMethod,
      'barcode': barcode,
      'notes': notes,
      'verified_at': verifiedAt.toIso8601String(),
    };
  }

  factory VerificationHistory.fromMap(Map<String, dynamic> map) {
    return VerificationHistory(
      id: map['id'],
      medicationId: map['medication_id'],
      medicationName: map['medication_name'],
      identityVerified: map['identity_verified'] == 1,
      contraindicationFound: map['contraindication_found'] != null ? (map['contraindication_found'] == 1) : null,
      interactionFound: map['interaction_found'] != null ? (map['interaction_found'] == 1) : null,
      verificationMethod: map['verification_method'],
      barcode: map['barcode'],
      notes: map['notes'],
      verifiedAt: DateTime.parse(map['verified_at']),
    );
  }
}

