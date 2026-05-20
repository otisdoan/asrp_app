import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/repositories/mock_data.dart';
import '../common/section_header.dart';

class ComboSection extends StatelessWidget {
  const ComboSection({super.key});

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
    final combos = MockData.combos;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const SectionHeader(icon: '🎁', title: 'Combo tiết kiệm', subtitle: 'Giảm giá sâu khi đặt theo combo'),
      ...combos.map((c) => _buildComboCard(context, c)),
    ]);
  }

  Widget _buildComboCard(BuildContext context, Map<String, dynamic> c) {
    final emojis = c['emojis'] as List;
    final price = c['price'] as int;
    final originalPrice = c['originalPrice'] as int;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.outlineVariant),
        boxShadow: const [BoxShadow(color: Color(0x0A000000), blurRadius: 4, offset: Offset(0, 2))],
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
        // Emoji stack
        SizedBox(
          width: 80,
          height: 50,
          child: Stack(
            children: List.generate(emojis.length, (i) => Positioned(
              left: i * 22.0,
              child: Container(
                width: 44, height: 44,
                decoration: BoxDecoration(color: AppColors.surfaceContainer, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.white, width: 2)),
                child: Center(child: Text(emojis[i], style: const TextStyle(fontSize: 20))),
              ),
            )),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(color: AppColors.badgeBestBg, borderRadius: BorderRadius.circular(4)),
            child: Text(c['badge'] ?? 'COMBO', style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: AppColors.badgeBestText)),
          ),
          const SizedBox(height: 4),
          Text(c['name'] as String, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
          const SizedBox(height: 2),
          Text(c['description'] as String, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
          const SizedBox(height: 6),
          Row(children: [
            Text('${_fmt(price)}d', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.primary)),
            const SizedBox(width: 8),
            Text('${_fmt(originalPrice)}d', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, decoration: TextDecoration.lineThrough)),
            const SizedBox(width: 8),
            Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: AppColors.successContainer, borderRadius: BorderRadius.circular(4)), child: Text(c['saving'] as String, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.success))),
          ]),
        ])),
        Container(
          width: 32, height: 32,
          decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
          child: const Icon(Icons.add, color: Colors.white, size: 20),
        ),
      ]),
    );
  }
}
