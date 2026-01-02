import 'package:flutter/material.dart';
import 'package:medlistapp/utils/appcolors.dart';

class CategoryItem {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  CategoryItem({
    required this.label,
    required this.icon,
    required this.onTap,
  });
}

class CategoryGridWidget extends StatelessWidget {
  final List<CategoryItem> categories;
  final int crossAxisCount;

  const CategoryGridWidget({
    super.key,
    required this.categories,
    this.crossAxisCount = 4,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.0,
      ),
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final category = categories[index];
        return _CategoryItemWidget(
          label: category.label,
          icon: category.icon,
          onTap: category.onTap,
        );
      },
    );
  }
}

class _CategoryItemWidget extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _CategoryItemWidget({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(50),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppColors.skyBlue,
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.pureWhite,
                  width: 2,
                ),
              ),
              child: Icon(
                icon,
                color: AppColors.pureWhite,
                size: 24,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.deepNavy,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

