import 'package:flutter/material.dart';
import 'package:medlistapp/utils/appcolors.dart';
import 'package:medlistapp/utils/constants.dart';

class StockStatusIndicator extends StatelessWidget {
  final int quantity;
  final int? threshold;

  const StockStatusIndicator({
    super.key,
    required this.quantity,
    this.threshold,
  });

  Color _getStatusColor() {
    final lowStockThreshold = threshold ?? AppConstants.defaultLowStockThreshold;
    if (quantity == 0) {
      return AppColors.errorRed;
    } else if (quantity < lowStockThreshold) {
      return AppColors.lowStockYellow;
    } else {
      return AppColors.successGreen;
    }
  }

  String _getStatusText() {
    final lowStockThreshold = threshold ?? AppConstants.defaultLowStockThreshold;
    if (quantity == 0) {
      return 'Out of Stock';
    } else if (quantity < lowStockThreshold) {
      return 'Low Stock';
    } else {
      return 'In Stock';
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor();
    final statusText = _getStatusText();
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            statusColor,
            statusColor.withOpacity(0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: statusColor.withOpacity(0.3),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: AppColors.pureWhite,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            statusText,
            style: const TextStyle(
              color: AppColors.pureWhite,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            '($quantity)',
            style: TextStyle(
              color: AppColors.pureWhite.withOpacity(0.9),
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

