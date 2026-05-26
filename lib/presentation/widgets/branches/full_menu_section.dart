import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/repositories/mock_data.dart';
import '../../../providers/branches_provider.dart';
import '../common/section_header.dart';
import 'menu_item_card.dart';

import '../../../data/models/menu_item_model.dart';

const _pageSize = 15;
const _sortOptions = ['Pho bien nhat', 'Gia thap nhat', 'Gia cao nhat', 'Mon moi nhat'];

class FullMenuSection extends ConsumerWidget {
  final void Function(String name)? onItemTap;
  const FullMenuSection({super.key, this.onItemTap});

  double _parsePrice(String priceStr) {
    final clean = priceStr.replaceAll('đ', '').replaceAll(',', '').replaceAll('.', '').trim();
    return double.tryParse(clean) ?? 0.0;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sort = ref.watch(menuSortProvider);
    final page = ref.watch(menuCurrentPageProvider);
    final selectedCategory = ref.watch(selectedCategoryProvider);
    final searchQuery = ref.watch(searchQueryProvider).trim().toLowerCase();
    final allItems = MockData.fullMenu;

    // 1. Filter by category & search query
    final filteredItems = allItems.where((item) {
      if (searchQuery.isNotEmpty && !item.name.toLowerCase().contains(searchQuery)) {
        return false;
      }
      if (selectedCategory == 'Tất cả') return true;
      final nameLower = item.name.toLowerCase();
      if (selectedCategory == 'Phở') return nameLower.contains('phở');
      if (selectedCategory == 'Bún') return nameLower.contains('bún');
      if (selectedCategory == 'Cơm') return nameLower.contains('cơm');
      
      if (selectedCategory == 'Đồ uống') {
        return nameLower.contains('trà') || 
               nameLower.contains('nước') || 
               nameLower.contains('sinh tố') || 
               nameLower.contains('cà phê') ||
               nameLower.contains('ép');
      }
      
      if (selectedCategory == 'Tráng miệng') {
        return nameLower.contains('chè') || 
               nameLower.contains('bánh') || 
               nameLower.contains('kem') ||
               nameLower.contains('quẩy') ||
               nameLower.contains('flan') ||
               nameLower.contains('donut');
      }
      
      return true;
    }).toList();

    // 2. Sort items
    if (sort == 'Gia thap nhat') {
      filteredItems.sort((a, b) => _parsePrice(a.price).compareTo(_parsePrice(b.price)));
    } else if (sort == 'Gia cao nhat') {
      filteredItems.sort((a, b) => _parsePrice(b.price).compareTo(_parsePrice(a.price)));
    } else if (sort == 'Mon moi nhat') {
      filteredItems.sort((a, b) => b.name.compareTo(a.name));
    }

    // 3. Paginate
    final totalPages = (filteredItems.length / _pageSize).ceil();
    final start = (page - 1) * _pageSize;
    final end = (start + _pageSize).clamp(0, filteredItems.length);
    final items = filteredItems.isEmpty 
        ? <MenuItemModel>[] 
        : filteredItems.sublist(start.clamp(0, filteredItems.length), end.clamp(0, filteredItems.length));

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const SectionHeader(icon: '🍽️', title: 'Thuc don day du', subtitle: 'Tat ca cac mon'),
      // Sort buttons
      SizedBox(
        height: 36,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: _sortOptions.length,
          separatorBuilder: (_, __) => const SizedBox(width: 6),
          itemBuilder: (_, i) {
            final isSelected = sort == _sortOptions[i];
            return GestureDetector(
              onTap: () {
                ref.read(menuSortProvider.notifier).state = _sortOptions[i];
                ref.read(menuCurrentPageProvider.notifier).state = 1;
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary : Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: isSelected ? AppColors.primary : AppColors.outlineVariant),
                ),
                child: Text(_sortOptions[i], style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: isSelected ? Colors.white : AppColors.textSecondary)),
              ),
            );
          },
        ),
      ),
      const SizedBox(height: 12),
      // Grid
      GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, childAspectRatio: 0.78, crossAxisSpacing: 10, mainAxisSpacing: 10),
        itemCount: items.length,
        itemBuilder: (_, i) => MenuItemCard(item: items[i], onTap: () => onItemTap?.call(items[i].name), onAdd: () => onItemTap?.call(items[i].name)),
      ),
      const SizedBox(height: 16),
      // Pagination
      if (totalPages > 1) Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        IconButton(
          icon: const Icon(Icons.chevron_left),
          onPressed: page > 1 ? () => ref.read(menuCurrentPageProvider.notifier).state = page - 1 : null,
        ),
        ...List.generate(totalPages, (i) {
          final p = i + 1;
          return GestureDetector(
            onTap: () => ref.read(menuCurrentPageProvider.notifier).state = p,
            child: Container(
              width: 32, height: 32, margin: const EdgeInsets.symmetric(horizontal: 3),
              decoration: BoxDecoration(
                color: p == page ? AppColors.primary : Colors.white,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: p == page ? AppColors.primary : AppColors.outlineVariant),
              ),
              child: Center(child: Text('$p', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: p == page ? Colors.white : AppColors.textSecondary))),
            ),
          );
        }),
        IconButton(
          icon: const Icon(Icons.chevron_right),
          onPressed: page < totalPages ? () => ref.read(menuCurrentPageProvider.notifier).state = page + 1 : null,
        ),
      ]),
    ]);
  }
}
