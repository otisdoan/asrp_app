import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/repositories/mock_data.dart';
import '../common/section_header.dart';

class BestSellerSection extends StatelessWidget {
  const BestSellerSection({super.key});

  String _fmt(int amount) {
    final s = amount.toString();
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
      buf.write(s[i]);
    }
    return buf.toString();
  }

  @override
  Widget build(BuildContext context) {
    final items = MockData.bestSellers;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const SectionHeader(icon: '🏆', title: 'Bán chạy nhất', subtitle: 'Được gọi nhiều nhất tuần này'),
      ...items.map((item) => _buildItem(item)),
    ]);
  }

  Widget _buildItem(Map<String, dynamic> item) {
    final rank = item['rank'] as int;
    final rankColors = [AppColors.accent, AppColors.onSurfaceVariant, AppColors.tertiary];
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: Row(children: [
        Container(
          width: 24, height: 24,
          decoration: BoxDecoration(color: rankColors[rank - 1].withAlpha(38), shape: BoxShape.circle),
          child: Center(child: Text('#$rank', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: rankColors[rank - 1]))),
        ),
        const SizedBox(width: 10),
        Container(
          width: 40, height: 40,
          decoration: BoxDecoration(color: AppColors.surfaceContainer, borderRadius: BorderRadius.circular(8)),
          child: Center(child: Text(item['emoji'] as String, style: const TextStyle(fontSize: 22))),
        ),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(item['name'] as String, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          const SizedBox(height: 2),
          Text('Đã bán ${_fmt(item['sold'] as int)} lần', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
        ])),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text(item['price'] as String, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.primary)),
          const SizedBox(height: 4),
          Container(
            width: 28, height: 28,
            decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
            child: const Icon(Icons.add, color: Colors.white, size: 18),
          ),
        ]),
      ]),
    );
  }
}
