import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../providers/chat_cart_provider.dart';
import '../../../../core/utils/format_utils.dart';

/// Bottom Checkout Bar — hiển thị tổng tiền, số món, nút chọn giờ và tạo QR.
///
/// Callbacks:
///  - [onCartTap]: mở CartDetailsBottomSheet
///  - [onPickupTimeTap]: mở time picker
///  - [onQrTap]: gọi direct action tạo QR
///  - [selectedPickupTime]: giờ lấy món đang được chọn (null = giao ngay)
class CheckoutBar extends ConsumerWidget {
  final VoidCallback onCartTap;
  final VoidCallback onPickupTimeTap;
  final VoidCallback onQrTap;
  final DateTime? selectedPickupTime;

  const CheckoutBar({
    super.key,
    required this.onCartTap,
    required this.onPickupTimeTap,
    required this.onQrTap,
    this.selectedPickupTime,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cart = ref.watch(chatCartProvider);
    if (cart.isEmpty) return const SizedBox.shrink();

    final totalItems = ref.read(chatCartProvider.notifier).totalItems;
    final totalPrice = ref.read(chatCartProvider.notifier).totalPrice;

    final pickupLabel = selectedPickupTime != null
        ? '${selectedPickupTime!.hour.toString().padLeft(2, '0')}:'
            '${selectedPickupTime!.minute.toString().padLeft(2, '0')}'
        : 'Giao ngay';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFDFB),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFD84315).withValues(alpha: 0.07),
            blurRadius: 14,
            offset: const Offset(0, -4),
          ),
        ],
        border: const Border(
          top: BorderSide(color: Color(0xFFFFECE2), width: 1.0),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // ── LEFT: Tổng tiền + số món (bấm để xem giỏ) ────────────────────
          Expanded(
            child: InkWell(
              onTap: onCartTap,
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '🛒 Đã chọn $totalItems món',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF4B5563),
                          ),
                        ),
                        const SizedBox(width: 3),
                        const Icon(Icons.keyboard_arrow_up,
                            size: 16, color: Color(0xFF4B5563)),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      FormatUtils.formatCurrency(totalPrice),
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFFEA580C),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(width: 8),

          // ── RIGHT: Chọn giờ + Tạo QR ──────────────────────────────────────
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Nút chọn giờ
              SizedBox(
                height: 40,
                child: OutlinedButton.icon(
                  onPressed: onPickupTimeTap,
                  icon: const Icon(Icons.access_time_rounded,
                      size: 16, color: Color(0xFFEA580C)),
                  label: Text(
                    pickupLabel,
                    style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFFEA580C)),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFEA580C),
                    side: const BorderSide(color: Color(0xFFEA580C)),
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20)),
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // Nút Tạo QR
              Container(
                height: 40,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFF97316), Color(0xFFEA580C)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFEA580C).withValues(alpha: 0.28),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: ElevatedButton.icon(
                  onPressed: onQrTap,
                  icon: const Icon(Icons.qr_code_rounded,
                      size: 16, color: Colors.white),
                  label: const Text(
                    'Tạo QR',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    foregroundColor: Colors.white,
                    shadowColor: Colors.transparent,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
