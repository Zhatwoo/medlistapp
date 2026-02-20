import 'package:flutter/material.dart';
import 'package:medlistapp/utils/appcolors.dart';

/// Clinical Disclaimer Widget
/// Displays the required clinical disclaimer as per Section 7.3
class ClinicalDisclaimerWidget extends StatelessWidget {
  final EdgeInsets? padding;
  final bool compact;

  const ClinicalDisclaimerWidget({
    super.key,
    this.padding,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppColors.warningOrange.withOpacity(0.1),
      margin: padding ?? const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: AppColors.warningOrange.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.info_outline,
              color: AppColors.warningOrange,
              size: compact ? 20 : 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'This application supports clinical decision-making and does not replace professional medical judgment.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.deepNavy,
                      fontWeight: FontWeight.w500,
                      fontSize: compact ? 12 : 14,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}



