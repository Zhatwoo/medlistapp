class ExpiryRecord {
  final int? id;
  final int stockItemId;
  final int daysUntilExpiry;
  final bool isExpired;
  final bool alertSent;
  final DateTime checkedAt;
  final DateTime? alertSentAt;

  ExpiryRecord({
    this.id,
    required this.stockItemId,
    required this.daysUntilExpiry,
    required this.isExpired,
    this.alertSent = false,
    DateTime? checkedAt,
    this.alertSentAt,
  }) : checkedAt = checkedAt ?? DateTime.now();

  // Convert to Map for database
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'stock_item_id': stockItemId,
      'days_until_expiry': daysUntilExpiry,
      'is_expired': isExpired ? 1 : 0,
      'alert_sent': alertSent ? 1 : 0,
      'checked_at': checkedAt.toIso8601String(),
      'alert_sent_at': alertSentAt?.toIso8601String(),
    };
  }

  // Create from Map (database)
  factory ExpiryRecord.fromMap(Map<String, dynamic> map) {
    return ExpiryRecord(
      id: map['id'] as int?,
      stockItemId: map['stock_item_id'] as int,
      daysUntilExpiry: map['days_until_expiry'] as int,
      isExpired: (map['is_expired'] as int) == 1,
      alertSent: (map['alert_sent'] as int) == 1,
      checkedAt: DateTime.parse(map['checked_at'] as String),
      alertSentAt: map['alert_sent_at'] != null
          ? DateTime.parse(map['alert_sent_at'] as String)
          : null,
    );
  }

  // Convert to JSON
  Map<String, dynamic> toJson() => toMap();

  // Create from JSON
  factory ExpiryRecord.fromJson(Map<String, dynamic> json) => ExpiryRecord.fromMap(json);

  // Create a copy with updated fields
  ExpiryRecord copyWith({
    int? id,
    int? stockItemId,
    int? daysUntilExpiry,
    bool? isExpired,
    bool? alertSent,
    DateTime? checkedAt,
    DateTime? alertSentAt,
  }) {
    return ExpiryRecord(
      id: id ?? this.id,
      stockItemId: stockItemId ?? this.stockItemId,
      daysUntilExpiry: daysUntilExpiry ?? this.daysUntilExpiry,
      isExpired: isExpired ?? this.isExpired,
      alertSent: alertSent ?? this.alertSent,
      checkedAt: checkedAt ?? this.checkedAt,
      alertSentAt: alertSentAt ?? this.alertSentAt,
    );
  }
}

