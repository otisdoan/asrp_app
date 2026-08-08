import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../providers/chat_cart_provider.dart';
import 'widgets/size_selector.dart';
import '../../../../core/utils/format_utils.dart';

/// Modal Bottom Sheet hiển thị chi tiết giỏ hàng chat AI.
///
/// Mỗi item trong giỏ hàng hiển thị:
///  - Ảnh thumbnail
///  - Tên món + giá hiệu quả
///  - Bộ chọn Size (ChoiceChip) nếu món có nhiều size
///  - Bộ điều chỉnh số lượng [-] N [+]
///
/// Footer hiển thị tổng tiền + nút "Xác nhận".
class CartDetailsBottomSheet extends ConsumerWidget {
  final ScrollController scrollController;

  const CartDetailsBottomSheet({
    super.key,
    required this.scrollController,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cartItems = ref.watch(chatCartProvider);
    final totalPrice = ref.watch(chatCartProvider.notifier).totalPrice;
    final totalItems = ref.watch(chatCartProvider.notifier).totalItems;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Drag handle ────────────────────────────────────────────────────
          const SizedBox(height: 12),
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFE5E7EB),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // ── Header ─────────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Giỏ hàng của bạn',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$totalItems món • ${FormatUtils.formatCurrency(totalPrice)}',
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFFEA580C),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded,
                      color: Color(0xFF6B7280)),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFF3F4F6)),

          // ── Danh sách món ─────────────────────────────────────────────────
          Flexible(
            child: cartItems.isEmpty
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(40),
                      child: Text(
                        'Chưa có món nào trong giỏ hàng.',
                        style: TextStyle(color: Color(0xFF9CA3AF)),
                      ),
                    ),
                  )
                : ListView.separated(
                    controller: scrollController,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: cartItems.length,
                    separatorBuilder: (_, __) => const Divider(
                      height: 1,
                      indent: 20,
                      endIndent: 20,
                      color: Color(0xFFF3F4F6),
                    ),
                    itemBuilder: (context, index) {
                      return _CartItemRow(item: cartItems[index]);
                    },
                  ),
          ),

          // ── Footer ─────────────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 12,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: Container(
                height: 52,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFF97316), Color(0xFFEA580C)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFEA580C).withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    foregroundColor: Colors.white,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    padding: EdgeInsets.zero,
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.check_circle_outline_rounded,
                          size: 18, color: Colors.white),
                      const SizedBox(width: 8),
                      Text(
                        'Xác nhận  •  ${FormatUtils.formatCurrency(totalPrice)}',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Cart Item Row (internal widget)
// ---------------------------------------------------------------------------

class _CartItemRow extends ConsumerWidget {
  final ChatCartItem item;

  const _CartItemRow({required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Row: thumbnail + info + quantity ──────────────────────────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Thumbnail
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: item.imageUrl.isNotEmpty
                    ? Image.network(
                        item.imageUrl,
                        width: 64,
                        height: 64,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _buildPlaceholder(),
                      )
                    : _buildPlaceholder(),
              ),
              const SizedBox(width: 12),

              // Name + price
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          FormatUtils.formatCurrency(item.effectivePrice),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFFEA580C),
                          ),
                        ),
                        if (item.selectedSizeName != null &&
                            item.selectedSizeName!.isNotEmpty) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFF4F0),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                  color: const Color(0xFFFFECE2), width: 0.8),
                            ),
                            child: Text(
                              item.selectedSizeName!,
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFFEA580C),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),

              // Quantity controller
              _QuantityController(item: item),
            ],
          ),

          // ── Size Selector: BẮT BUỘC render khi availableSizes.isNotEmpty ──
          if (item.availableSizes.isNotEmpty) ...[
            const SizedBox(height: 12),
            SizeSelector(
              selectedSizeId: item.selectedSizeId,
              sizeOptions: item.availableSizes
                  .map((s) => {'id': s.id, 'name': s.name})
                  .toList(),
              onSizeSelected: (newSizeId) {
                final newSize = item.availableSizes
                    .firstWhere((s) => s.id == newSizeId,
                        orElse: () => item.availableSizes.first);
                ref.read(chatCartProvider.notifier).changeItemSize(
                      item.menuItemId,
                      item.branchId,
                      newSizeId,
                      newSize.name,
                    );
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFF7ED), Color(0xFFFFEDD5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Center(
        child: Icon(Icons.fastfood_rounded,
            color: Color(0xFFEA580C), size: 28),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Quantity Controller (internal)
// ---------------------------------------------------------------------------

class _QuantityController extends ConsumerWidget {
  final ChatCartItem item;

  const _QuantityController({required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.only(left: 8),
      height: 34,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFF97316), Color(0xFFEA580C)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFEA580C).withValues(alpha: 0.2),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _iconBtn(
            Icons.remove,
            () => ref.read(chatCartProvider.notifier).updateItemQuantity(
                  item.menuItemId,
                  item.branchId,
                  item.selectedSizeId,
                  -1,
                ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              '${item.quantity}',
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 13,
                color: Colors.white,
              ),
            ),
          ),
          _iconBtn(
            Icons.add,
            () => ref.read(chatCartProvider.notifier).updateItemQuantity(
                  item.menuItemId,
                  item.branchId,
                  item.selectedSizeId,
                  1,
                ),
          ),
        ],
      ),
    );
  }

  Widget _iconBtn(IconData icon, VoidCallback onPressed) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onPressed,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Icon(icon, color: Colors.white, size: 14),
      ),
    );
  }
}
