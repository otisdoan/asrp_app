import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/repositories/mock_data.dart';
import '../../../providers/shop_provider.dart';
import '../../../providers/category_provider.dart';

class ShopDrawer extends ConsumerWidget {
  const ShopDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedCategory = ref.watch(selectedCategoryProvider);
    final branch = ref.watch(selectedBranchProvider);
    final categoriesAsync = ref.watch(categoriesFutureProvider);

    return Drawer(
      child: SafeArea(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            color: AppColors.primary,
            child: Row(children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.asset(
                    'assets/images/pho.jpg',
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('BMC Phở Express', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white)),
                Text(branch.length > 20 ? '${branch.substring(0, 20)}...' : branch, style: const TextStyle(fontSize: 10, color: Color(0xCCFFFFFF))),
              ]),
            ]),
          ),
          // Table info
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: AppColors.surfaceContainer,
            child: Row(children: [
              Container(width: 8, height: 8, decoration: const BoxDecoration(color: AppColors.successBright, shape: BoxShape.circle)),
              const SizedBox(width: 8),
              const Text('Bàn 05 · 2 người · Quét lúc 12:04', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
            ]),
          ),
          const SizedBox(height: 8),
          // Categories label
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Text('DANH MỤC', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.8, color: AppColors.textSecondary.withOpacity(0.6))),
          ),
          // All
          _buildCategoryTile(context, ref, null, 'Tất cả', null, selectedCategory),
          ...categoriesAsync.maybeWhen(
            data: (categories) => categories.map((c) => _buildCategoryTile(context, ref, c.imageUrl, c.name, c.count, selectedCategory)),
            orElse: () => MockData.categories.map((c) => _buildCategoryTile(context, ref, c.imageUrl, c.name, c.count, selectedCategory)),
          ),
          const Divider(height: 24),
          // Quick filters label
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Text('LỌC NHANH', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.8, color: AppColors.textSecondary.withOpacity(0.6))),
          ),
          ...MockData.quickFilters.map((f) => _buildFilterTile(context, f['imageUrl'] as String, f['name'] as String)),
          const Spacer(),
          // Branch selector
          Padding(
            padding: const EdgeInsets.all(12),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: AppColors.primaryContainer, borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.primary.withOpacity(0.2))),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Chi nhánh', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.primary)),
                const SizedBox(height: 8),
                ...(["Bàn số: 05", "Số người: 2", "Chi nhánh: Quận 1"]).map((info) {
                  final parts = info.split(': ');
                  return Padding(padding: const EdgeInsets.only(bottom: 3), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Text(parts[0], style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                    Text(parts[1], style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                  ]));
                }),
              ]),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _buildCategoryTile(BuildContext context, WidgetRef ref, String? imageUrl, String name, int? count, String selected) {
    final isActive = selected == name;
    return InkWell(
      onTap: () {
        ref.read(selectedCategoryProvider.notifier).state = name;
        Navigator.pop(context);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isActive ? AppColors.primaryContainer : Colors.transparent,
          border: isActive ? const Border(left: BorderSide(color: AppColors.primary, width: 3)) : null,
        ),
        child: Row(children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isActive ? AppColors.primary.withOpacity(0.15) : AppColors.surfaceContainerHigh,
            ),
            child: ClipOval(
              child: imageUrl != null
                  ? (imageUrl.startsWith('http')
                      ? Image.network(
                          imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Icon(
                            Icons.restaurant_menu_rounded,
                            size: 16,
                            color: isActive ? AppColors.primary : AppColors.textSecondary,
                          ),
                        )
                      : Image.asset(
                          imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Icon(
                            Icons.restaurant_menu_rounded,
                            size: 16,
                            color: isActive ? AppColors.primary : AppColors.textSecondary,
                          ),
                        ))
                  : Icon(
                      Icons.restaurant_menu_rounded,
                      size: 16,
                      color: isActive ? AppColors.primary : AppColors.textSecondary,
                    ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(name, style: TextStyle(fontSize: 13, fontWeight: isActive ? FontWeight.w700 : FontWeight.w500, color: isActive ? AppColors.primary : AppColors.textPrimary))),
          if (count != null) Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(color: isActive ? AppColors.primary.withOpacity(0.15) : AppColors.surfaceContainerHigh, borderRadius: BorderRadius.circular(8)),
            child: Text('$count', style: TextStyle(fontSize: 10, color: isActive ? AppColors.primary : AppColors.textSecondary, fontWeight: FontWeight.w600)),
          ),
        ]),
      ),
    );
  }

  Widget _buildFilterTile(BuildContext context, String imageUrl, String name) {
    return InkWell(
      onTap: () => Navigator.pop(context),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(6),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Image.asset(imageUrl, fit: BoxFit.cover),
            ),
          ),
          const SizedBox(width: 10),
          Text(name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
        ]),
      ),
    );
  }
}
