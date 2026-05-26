import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../providers/cart_provider.dart';
import 'cart_bottom_sheet.dart';

class MobileCartBar extends ConsumerWidget {
  const MobileCartBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cart = ref.watch(cartProvider);
    if (cart.isEmpty) return const SizedBox.shrink();

    return GestureDetector(
      onTap: () => showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => const CartBottomSheet(),
      ),
      child: Container(
        color: AppColors.primary,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
            child: Text('${cart.totalItems} món', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.primary)),
          ),
          const SizedBox(width: 10),
          const Text('Xem giỏ hàng', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white)),
          const Spacer(),
          Text('${_fmt(cart.total)}đ →', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white)),
        ]),
      ),
    );
  }

  String _fmt(int amount) {
    final s = amount.toString();
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
      buf.write(s[i]);
    }
    return buf.toString();
  }
}
