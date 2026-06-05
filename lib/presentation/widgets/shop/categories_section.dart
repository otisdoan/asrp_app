import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/repositories/mock_data.dart';
import '../../../providers/shop_provider.dart';
import '../../../providers/category_provider.dart';
import '../../../data/models/category_model.dart';

class CategoriesSection extends ConsumerWidget {
  const CategoriesSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedCategory = ref.watch(selectedCategoryProvider);
    final categoriesAsync = ref.watch(categoriesFutureProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (selectedCategory != 'Tất cả')
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Align(
                alignment: Alignment.centerRight,
                child: GestureDetector(
                  onTap: () {
                    ref.read(selectedCategoryProvider.notifier).state = 'Tất cả';
                    ref.read(menuCurrentPageProvider.notifier).state = 1;
                  },
                  child: const Text(
                    'Xóa lọc',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          if (selectedCategory != 'Tất cả') const SizedBox(height: 8),
          categoriesAsync.when(
            data: (categories) => _buildList(context, ref, categories.isEmpty ? MockData.categories : categories, selectedCategory),
            loading: () => _buildList(context, ref, MockData.categories, selectedCategory), // smooth loading fallback
            error: (err, stack) => _buildList(context, ref, MockData.categories, selectedCategory), // robust error fallback
          ),
        ],
      ),
    );
  }

  Widget _buildList(BuildContext context, WidgetRef ref, List<CategoryModel> categories, String selectedCategory) {
    return SizedBox(
      height: 90,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        itemCount: categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 16),
        itemBuilder: (context, index) {
          final cat = categories[index];
          final name = cat.name;
          final imageUrl = cat.imageUrl;
          final isSelected = selectedCategory == name;

          return GestureDetector(
            onTap: () {
              ref.read(selectedCategoryProvider.notifier).state = name;
              ref.read(menuCurrentPageProvider.notifier).state = 1;
              context.push('/search?category=$name');
            },
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected ? AppColors.primary : Colors.transparent,
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.06),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: imageUrl.startsWith('http')
                        ? Image.network(
                            imageUrl,
                            width: 56,
                            height: 56,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const Icon(
                              Icons.restaurant_menu_rounded,
                              color: AppColors.textSecondary,
                            ),
                          )
                        : Image.asset(
                            imageUrl,
                            width: 56,
                            height: 56,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const Icon(
                              Icons.restaurant_menu_rounded,
                              color: AppColors.textSecondary,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  name,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected ? AppColors.primary : AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
