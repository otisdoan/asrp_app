import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

class BranchCategoryTabsDelegate extends SliverPersistentHeaderDelegate {
  final List<String> categories;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  BranchCategoryTabsDelegate({
    required this.categories,
    required this.selectedIndex,
    required this.onSelected,
  });

  @override
  double get minExtent => 48;

  @override
  double get maxExtent => 48;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: AppColors.background,
      child: Column(
        children: [
          Expanded(
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: categories.length,
              separatorBuilder: (_, __) => const SizedBox(width: 20),
              itemBuilder: (_, index) {
                final isSelected = index == selectedIndex;
                return GestureDetector(
                  onTap: () => onSelected(index),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        categories[index],
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight:
                              isSelected ? FontWeight.w700 : FontWeight.w500,
                          color: isSelected
                              ? AppColors.textPrimary
                              : AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        height: 2,
                        width: 30,
                        color:
                            isSelected ? AppColors.primary : Colors.transparent,
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          const Divider(height: 1, color: AppColors.outlineVariant),
        ],
      ),
    );
  }

  @override
  bool shouldRebuild(covariant BranchCategoryTabsDelegate oldDelegate) {
    return oldDelegate.selectedIndex != selectedIndex ||
        oldDelegate.categories != categories;
  }
}
