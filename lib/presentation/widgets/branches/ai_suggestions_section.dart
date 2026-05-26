import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/repositories/mock_data.dart';
import 'menu_item_card.dart';

class AiSuggestionsSection extends StatelessWidget {
  final void Function(String name)? onItemTap;
  const AiSuggestionsSection({super.key, this.onItemTap});

  @override
  Widget build(BuildContext context) {
    final items = MockData.aiSuggestions;
    return Container(
      decoration: BoxDecoration(color: AppColors.aiSectionBg, borderRadius: BorderRadius.circular(12)),
      padding: const EdgeInsets.all(14),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(width: 10, height: 10, decoration: const BoxDecoration(color: AppColors.successBright, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Color(0x334CAF50), blurRadius: 6, spreadRadius: 3)])),
          const SizedBox(width: 8),
          const Text('Món ngon bạn yêu thích', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white)),
        ]),
        const SizedBox(height: 12),
        SizedBox(
          height: 160,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (_, i) => SizedBox(
              width: 120,
              child: MenuItemCard(item: items[i], onTap: () => onItemTap?.call(items[i].name), onAdd: () => onItemTap?.call(items[i].name)),
            ),
          ),
        ),
      ]),
    );
  }
}
