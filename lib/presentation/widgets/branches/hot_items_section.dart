import 'package:flutter/material.dart';
import '../../../data/repositories/mock_data.dart';
import '../common/section_header.dart';
import 'menu_item_card.dart';

class HotItemsSection extends StatelessWidget {
  final void Function(String name)? onItemTap;
  const HotItemsSection({super.key, this.onItemTap});

  @override
  Widget build(BuildContext context) {
    final items = MockData.hotItems;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const SectionHeader(icon: '🔥', title: 'Đang bán chạy', subtitle: 'Món ăn được ưa chuộng nhất hôm nay', actionLabel: 'Xem tất cả →', onAction: null),
      SizedBox(
        height: 170,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: items.length,
          separatorBuilder: (_, __) => const SizedBox(width: 10),
          itemBuilder: (_, i) => SizedBox(
            width: 130,
            child: MenuItemCard(item: items[i], onTap: () => onItemTap?.call(items[i].name), onAdd: () => onItemTap?.call(items[i].name)),
          ),
        ),
      ),
    ]);
  }
}
