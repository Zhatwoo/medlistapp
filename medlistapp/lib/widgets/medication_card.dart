import 'package:flutter/material.dart';
import 'package:medlistapp/models/medication.dart';
import 'package:medlistapp/utils/app_colors.dart';
import 'package:medlistapp/widgets/stock_status_indicator.dart';
import 'package:intl/intl.dart';

class MedicationCard extends StatelessWidget {
  final Medication medication;
  final int? stockQuantity;
  final VoidCallback? onTap;

  const MedicationCard({
    super.key,
    required this.medication,
    this.stockQuantity,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final priceFormat = NumberFormat.currency(symbol: 'AED ', decimalDigits: 2);
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.pureWhite,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          AppColors.cardShadow,
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Medication Icon with gradient
                Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.skyBlue.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.medication_rounded,
                    color: AppColors.pureWhite,
                    size: 36,
                  ),
                ),
                const SizedBox(width: 16),
                // Main Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Trade Name - Big and clear
                      Text(
                        medication.tradeName,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: AppColors.deepNavy,
                          fontSize: 18,
                          height: 1.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      // Form - Clear label
                      Row(
                        children: [
                          Icon(
                            Icons.category_rounded,
                            size: 16,
                            color: AppColors.skyBlue,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            medication.form,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppColors.mediumGray,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      // Company and Price Row
                      Row(
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                Icon(
                                  Icons.business_rounded,
                                  size: 16,
                                  color: AppColors.mediumGray,
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    medication.company,
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: AppColors.mediumGray,
                                      fontSize: 13,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                gradient: AppColors.primaryGradient,
                                borderRadius: BorderRadius.circular(10),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.skyBlue.withOpacity(0.3),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Text(
                                priceFormat.format(medication.pharmacyPrice),
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: AppColors.pureWhite,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      // Stock Status Badge
                      if (stockQuantity != null)
                        StockStatusIndicator(quantity: stockQuantity!),
                    ],
                  ),
                ),
                // Action Button - More visible
                const SizedBox(width: 12),
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.skyBlue.withOpacity(0.4),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: onTap,
                      borderRadius: BorderRadius.circular(14),
                      child: const Icon(
                        Icons.arrow_forward_rounded,
                        color: AppColors.pureWhite,
                        size: 24,
                      ),
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
