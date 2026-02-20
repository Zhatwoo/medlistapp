import 'package:flutter/material.dart';
import 'package:medlistapp/models/stockitem.dart';
import 'package:medlistapp/models/medication.dart';
import 'package:medlistapp/utils/appcolors.dart';
import 'package:intl/intl.dart';

class ExpiryAlertCard extends StatelessWidget {
  final StockItem stockItem;
  final Medication? medication;
  final VoidCallback? onTap;

  const ExpiryAlertCard({
    super.key,
    required this.stockItem,
    this.medication,
    this.onTap,
  });

  Color _getAlertColor() {
    if (stockItem.isExpired) {
      return AppColors.errorRed;
    } else if (stockItem.daysUntilExpiry <= 7) {
      return AppColors.warningOrange;
    } else {
      return AppColors.lowStockYellow;
    }
  }

  String _getAlertText() {
    if (stockItem.isExpired) {
      return 'Expired';
    } else if (stockItem.daysUntilExpiry == 0) {
      return 'Expires Today';
    } else {
      return '${stockItem.daysUntilExpiry} days left';
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM dd, yyyy');
    final alertColor = _getAlertColor();
    final alertText = _getAlertText();
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.pureWhite,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: alertColor.withOpacity(0.3),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: alertColor.withOpacity(0.2),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Alert indicator with icon
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        alertColor,
                        alertColor.withOpacity(0.7),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: alertColor.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(
                    stockItem.isExpired
                        ? Icons.error_rounded
                        : Icons.warning_rounded,
                    color: AppColors.pureWhite,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        medication?.tradeName ?? 'Unknown Medication',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: AppColors.deepNavy,
                          fontSize: 16,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.calendar_today_rounded,
                            size: 14,
                            color: AppColors.mediumGray,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'Expiry: ${dateFormat.format(stockItem.expiryDate)}',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: AppColors.mediumGray,
                                fontWeight: FontWeight.w600,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                        ],
                      ),
                      if (stockItem.batchNumber != null) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.inventory_2_rounded,
                              size: 14,
                              color: AppColors.mediumGray,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                'Batch: ${stockItem.batchNumber}',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: AppColors.mediumGray,
                                ),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerRight,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                alertColor,
                                alertColor.withOpacity(0.8),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: alertColor.withOpacity(0.4),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Text(
                            alertText,
                            style: const TextStyle(
                              color: AppColors.pureWhite,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.softBlue,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            'Qty: ${stockItem.quantity}',
                            style: TextStyle(
                              color: AppColors.deepNavy,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

