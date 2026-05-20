import 'package:flutter/material.dart';
import '../../../data/repositories/mock_data.dart';

class MiniPromoBanners extends StatelessWidget {
  const MiniPromoBanners({super.key});

  @override
  Widget build(BuildContext context) {
    final promos = MockData.miniPromos;
    return Row(children: promos.asMap().entries.map((e) {
      final idx = e.key;
      final p = e.value;
      return Expanded(child: Container(
        margin: EdgeInsets.only(right: idx < promos.length - 1 ? 10 : 0),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Color(p['bgColor'] as int),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(p['icon'] as String, style: const TextStyle(fontSize: 28)),
          const SizedBox(height: 8),
          Text(p['title'] as String, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(p['textColor'] as int))),
          const SizedBox(height: 4),
          Text(p['desc'] as String, style: TextStyle(fontSize: 10, color: Color(p['textColor'] as int).withOpacity(0.8))),
        ]),
      ));
    }).toList());
  }
}
