class BarcodeData {
  final String barcode;
  final String? format; // 'EAN13', 'QR_CODE', etc.
  final int? medicationId;
  final String? medicationName;
  final bool matched;
  final DateTime scannedAt;

  BarcodeData({
    required this.barcode,
    this.format,
    this.medicationId,
    this.medicationName,
    required this.matched,
    DateTime? scannedAt,
  }) : scannedAt = scannedAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'barcode': barcode,
      'format': format,
      'medication_id': medicationId,
      'medication_name': medicationName,
      'matched': matched ? 1 : 0,
      'scanned_at': scannedAt.toIso8601String(),
    };
  }

  factory BarcodeData.fromMap(Map<String, dynamic> map) {
    return BarcodeData(
      barcode: map['barcode'],
      format: map['format'],
      medicationId: map['medication_id'],
      medicationName: map['medication_name'],
      matched: map['matched'] == 1,
      scannedAt: DateTime.parse(map['scanned_at']),
    );
  }
}

