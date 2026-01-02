enum StockAdjustmentReason {
  dispensed,
  damaged,
  expired,
  lost,
  other,
}

extension StockAdjustmentReasonExtension on StockAdjustmentReason {
  String get displayName {
    switch (this) {
      case StockAdjustmentReason.dispensed:
        return 'Dispensed';
      case StockAdjustmentReason.damaged:
        return 'Damaged';
      case StockAdjustmentReason.expired:
        return 'Expired';
      case StockAdjustmentReason.lost:
        return 'Lost';
      case StockAdjustmentReason.other:
        return 'Other';
    }
  }
}

