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
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  // Create from Map (database)
  factory StockItem.fromMap(Map<String, dynamic> map) {
    return StockItem(
      id: map['id'] as int?,
      medicationId: map['medication_id'] as int,
      quantity: map['quantity'] as int,
      expiryDate: DateTime.parse(map['expiry_date'] as String),
      batchNumber: map['batch_number'] as String?,
      location: map['location'] as String?,
      purchaseDate: map['purchase_date'] != null
          ? DateTime.parse(map['purchase_date'] as String)
          : null,
      manufacturingDate: map['manufacturing_date'] != null
          ? DateTime.parse(map['manufacturing_date'] as String)
          : null,
      expectedQuantity: map['expected_quantity'] as int?,
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

  // Calculate days until expiry
  int get daysUntilExpiry {
    final now = DateTime.now();
    final difference = expiryDate.difference(now);
    return difference.inDays;
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
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }
}

