import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../providers/cart_provider.dart';
import '../../../data/models/cart_item_model.dart';

class CartBottomSheet extends ConsumerStatefulWidget {
  const CartBottomSheet({super.key});
  @override
  ConsumerState<CartBottomSheet> createState() => _CartBottomSheetState();
}

class _CartBottomSheetState extends ConsumerState<CartBottomSheet> {
  final _noteController = TextEditingController();

  @override
  void dispose() { _noteController.dispose(); super.dispose(); }

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
    final cart = ref.watch(cartProvider);
    final notifier = ref.read(cartProvider.notifier);

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      child: Column(children: [
        // Handle
        Container(margin: const EdgeInsets.only(top: 8, bottom: 4), width: 40, height: 4, decoration: BoxDecoration(color: AppColors.outlineVariant, borderRadius: BorderRadius.circular(2))),
        // Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(children: [
            const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Giỏ hàng của bạn', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
              Text('Bàn 05 · Chi nhánh Quận 1', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
            ]),
            const Spacer(),
            IconButton(icon: const Icon(Icons.close, size: 20), onPressed: () => Navigator.pop(context)),
          ]),
        ),
        const Divider(height: 1),
        // Items
        Expanded(child: ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: cart.items.length,
          separatorBuilder: (_, __) => const Divider(height: 16),
          itemBuilder: (_, i) => _buildCartItem(cart.items[i], notifier),
        )),
        // Summary
        Container(
          padding: const EdgeInsets.all(16),
          decoration: const BoxDecoration(border: Border(top: BorderSide(color: AppColors.outlineVariant))),
          child: Column(children: [
            _buildSummaryRow('Tạm tính (${cart.totalItems} món)', '${_fmt(cart.subtotal)}đ', isTotal: false),
            const SizedBox(height: 4),
            _buildSummaryRow('Khuyến mãi', '-${_fmt(cart.discount)}đ', isDiscount: true),
            const Divider(height: 16),
            _buildSummaryRow('Tổng cộng', '${_fmt(cart.total)}đ', isTotal: true),
            const SizedBox(height: 12),
            // Note
            const Align(alignment: Alignment.centerLeft, child: Text('Ghi chú cho bếp:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textSecondary))),
            const SizedBox(height: 6),
            TextField(
              controller: _noteController,
              maxLines: 2,
              style: const TextStyle(fontSize: 12),
              decoration: InputDecoration(
                hintText: 'VD: không hành, ít cay...',
                hintStyle: const TextStyle(fontSize: 12, color: AppColors.textPlaceholder),
                filled: true, fillColor: AppColors.surfaceContainer,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.all(10),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(width: double.infinity, child: ElevatedButton(
              onPressed: () { Navigator.pop(context); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đặt món thành công!')));
              },
              style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
              child: Text('Gọi món ngay · ${_fmt(cart.total)}đ', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
            )),
          ]),
        ),
        SizedBox(height: MediaQuery.of(context).padding.bottom),
      ]),
    );
  }

  Widget _buildCartItem(CartItemModel item, CartNotifier notifier) {
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(
        width: 44, height: 44,
        decoration: BoxDecoration(color: AppColors.surfaceContainer, borderRadius: BorderRadius.circular(8)),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.asset(item.imageUrl, fit: BoxFit.cover, width: 44, height: 44),
        ),
      ),
      const SizedBox(width: 10),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(item.name, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
        const SizedBox(height: 2),
        Text('${_fmt(item.priceAmount)}đ', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.primary)),
        const SizedBox(height: 6),
        Row(children: [
          _qtyBtn('-', () => notifier.updateQuantity(item.id, item.quantity - 1)),
          Padding(padding: const EdgeInsets.symmetric(horizontal: 10), child: Text('${item.quantity}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700))),
          _qtyBtn('+', () => notifier.updateQuantity(item.id, item.quantity + 1)),
        ]),
      ])),
    ]);
  }

  Widget _qtyBtn(String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 24, height: 24,
        decoration: BoxDecoration(border: Border.all(color: AppColors.outlineVariant), borderRadius: BorderRadius.circular(6)),
        child: Center(child: Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary))),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isTotal = false, bool isDiscount = false}) {
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(label, style: TextStyle(fontSize: isTotal ? 14 : 12, fontWeight: isTotal ? FontWeight.w700 : FontWeight.w400, color: isTotal ? AppColors.textPrimary : AppColors.textSecondary)),
      Text(value, style: TextStyle(fontSize: isTotal ? 15 : 12, fontWeight: isTotal ? FontWeight.w800 : FontWeight.w500, color: isTotal ? AppColors.primary : isDiscount ? AppColors.success : AppColors.textSecondary)),
    ]);
  }
}
