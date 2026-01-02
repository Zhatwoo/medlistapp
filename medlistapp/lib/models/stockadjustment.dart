import 'package:medlistapp/models/stockadjustmentreason.dart';

class StockAdjustment {
  final int? id;
  final int stockItemId;
  final int oldQuantity;
  final int newQuantity;
  final StockAdjustmentReason reason;
  final String? notes;
  final DateTime adjustedAt;
  final String? adjustedBy;

  StockAdjustment({
    this.id,
    required this.stockItemId,
    required this.oldQuantity,
    required this.newQuantity,
    required this.reason,
    this.notes,
    DateTime? adjustedAt,
    this.adjustedBy,
  }) : adjustedAt = adjustedAt ?? DateTime.now();

  // Convert to Map for database
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'stock_item_id': stockItemId,
      'old_quantity': oldQuantity,
      'new_quantity': newQuantity,
      'reason': reason.name,
      'notes': notes,
      'adjusted_at': adjustedAt.toIso8601String(),
      'adjusted_by': adjustedBy,
    };
  }

  // Create from Map (database)
  factory StockAdjustment.fromMap(Map<String, dynamic> map) {
    return StockAdjustment(
      id: map['id'] as int?,
      stockItemId: map['stock_item_id'] as int,
      oldQuantity: map['old_quantity'] as int,
      newQuantity: map['new_quantity'] as int,
      reason: StockAdjustmentReason.values.firstWhere(
        (e) => e.name == map['reason'],
        orElse: () => StockAdjustmentReason.other,
      ),
      notes: map['notes'] as String?,
      adjustedAt: DateTime.parse(map['adjusted_at'] as String),
      adjustedBy: map['adjusted_by'] as String?,
    );
  }

  // Convert to JSON
  Map<String, dynamic> toJson() => toMap();

  // Create from JSON
  factory StockAdjustment.fromJson(Map<String, dynamic> json) => StockAdjustment.fromMap(json);

  // Get quantity difference
  int get quantityDifference => newQuantity - oldQuantity;

  // Create a copy with updated fields
  StockAdjustment copyWith({
    int? id,
    int? stockItemId,
    int? oldQuantity,
    int? newQuantity,
    StockAdjustmentReason? reason,
    String? notes,
    DateTime? adjustedAt,
    String? adjustedBy,
  }) {
    return StockAdjustment(
      id: id ?? this.id,
      stockItemId: stockItemId ?? this.stockItemId,
      oldQuantity: oldQuantity ?? this.oldQuantity,
      newQuantity: newQuantity ?? this.newQuantity,
      reason: reason ?? this.reason,
      notes: notes ?? this.notes,
      adjustedAt: adjustedAt ?? this.adjustedAt,
      adjustedBy: adjustedBy ?? this.adjustedBy,
    );
  }
}

