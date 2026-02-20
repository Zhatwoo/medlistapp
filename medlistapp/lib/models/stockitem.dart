class StockItem {
  final int? id;
  final int medicationId;
  final int quantity;
  final DateTime expiryDate;
  final String? batchNumber;
  final String? location;
  final DateTime? purchaseDate;
  final DateTime? manufacturingDate;
  final int? expectedQuantity;
  final String? companyCode; // Company code for multi-tenant support
  final String? serialNumber; // GS1 serial number (AI 21)
  final DateTime createdAt;
  final DateTime? updatedAt;

  StockItem({
    this.id,
    required this.medicationId,
    required this.quantity,
    required this.expiryDate,
    this.batchNumber,
    this.location,
    this.purchaseDate,
    this.manufacturingDate,
    this.expectedQuantity,
    this.companyCode,
    this.serialNumber,
    DateTime? createdAt,
    this.updatedAt,
  }) : createdAt = createdAt ?? DateTime.now();

  // Convert to Map for database
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'medication_id': medicationId,
      'quantity': quantity,
      'expiry_date': expiryDate.toIso8601String(),
      'batch_number': batchNumber,
      'location': location,
      'purchase_date': purchaseDate?.toIso8601String(),
      'manufacturing_date': manufacturingDate?.toIso8601String(),
      'expected_quantity': expectedQuantity,
      'company_code': companyCode,
      'serial_number': serialNumber,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  /// Parses expiry_date from DB - supports ISO8601 and date-only formats.
  /// Returns far-future fallback on parse failure so item loads but won't trigger expiry alerts.
  static DateTime _parseExpiryDate(dynamic value) {
    if (value is String && value.trim().isNotEmpty) {
      final s = value.trim();
      final parsed = DateTime.tryParse(s);
      if (parsed != null) return parsed;
      final parts = s.split(RegExp(r'[\sT\-/:]'));
      if (parts.length >= 3) {
        final y = int.tryParse(parts[0]);
        final m = int.tryParse(parts[1]);
        final d = int.tryParse(parts[2]);
        if (y != null && m != null && d != null && m >= 1 && m <= 12 && d >= 1 && d <= 31) {
          return DateTime(y, m, d);
        }
      }
    }
    return DateTime(2099, 12, 31);
  }

  // Create from Map (database)
  factory StockItem.fromMap(Map<String, dynamic> map) {
    return StockItem(
      id: map['id'] as int?,
      medicationId: map['medication_id'] as int,
      quantity: map['quantity'] as int,
      expiryDate: _parseExpiryDate(map['expiry_date']),
      batchNumber: map['batch_number'] as String?,
      location: map['location'] as String?,
      purchaseDate: map['purchase_date'] != null
          ? DateTime.parse(map['purchase_date'] as String)
          : null,
      manufacturingDate: map['manufacturing_date'] != null
          ? DateTime.parse(map['manufacturing_date'] as String)
          : null,
      expectedQuantity: map['expected_quantity'] as int?,
      companyCode: map['company_code'] as String?,
      serialNumber: map['serial_number'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'] as String)
          : null,
    );
  }

  // Convert to JSON
  Map<String, dynamic> toJson() => toMap();

  // Create from JSON
  factory StockItem.fromJson(Map<String, dynamic> json) => StockItem.fromMap(json);

  // Calculate days until expiry (date-only: product valid through end of expiry day)
  int get daysUntilExpiry {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final expiryDay = DateTime(expiryDate.year, expiryDate.month, expiryDate.day);
    return expiryDay.difference(today).inDays;
  }

  // Check if expired
  bool get isExpired => daysUntilExpiry < 0;

  // Check if expiring soon (within 30 days)
  bool isExpiringSoon([int days = 30]) => daysUntilExpiry >= 0 && daysUntilExpiry <= days;

  // Calculate variance (actual - expected)
  int? get variance {
    if (expectedQuantity == null) return null;
    return quantity - expectedQuantity!;
  }

  // Check if overstocked (actual > expected)
  bool get isOverstocked {
    if (expectedQuantity == null) return false;
    return quantity > expectedQuantity!;
  }

  // Check if understocked (actual < expected)
  bool get isUnderstocked {
    if (expectedQuantity == null) return false;
    return quantity < expectedQuantity!;
  }

  // Create a copy with updated fields
  StockItem copyWith({
    int? id,
    int? medicationId,
    int? quantity,
    DateTime? expiryDate,
    String? batchNumber,
    String? location,
    DateTime? purchaseDate,
    DateTime? manufacturingDate,
    int? expectedQuantity,
    String? companyCode,
    String? serialNumber,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return StockItem(
      id: id ?? this.id,
      medicationId: medicationId ?? this.medicationId,
      quantity: quantity ?? this.quantity,
      expiryDate: expiryDate ?? this.expiryDate,
      batchNumber: batchNumber ?? this.batchNumber,
      location: location ?? this.location,
      purchaseDate: purchaseDate ?? this.purchaseDate,
      manufacturingDate: manufacturingDate ?? this.manufacturingDate,
      expectedQuantity: expectedQuantity ?? this.expectedQuantity,
      companyCode: companyCode ?? this.companyCode,
      serialNumber: serialNumber ?? this.serialNumber,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }
}

