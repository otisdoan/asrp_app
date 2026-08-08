import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/format_utils.dart';

/// Card QR thanh toán inline — hiển thị trong danh sách tin nhắn chat.
///
/// Tự chạy countdown timer và cho phép hủy qua [onCancel].
/// Được đặt tại `lib/presentation/widgets/payment/` để tái sử dụng
/// từ nhiều màn hình (Chat AI, Order Detail, v.v.)
class InlineQrPaymentCard extends StatefulWidget {
  final String orderId;
  final String qrCode;
  final double amount;
  final int initialSecondsRemaining;
  final VoidCallback onCancel;

  const InlineQrPaymentCard({
    super.key,
    required this.orderId,
    required this.qrCode,
    required this.amount,
    this.initialSecondsRemaining = 600,
    required this.onCancel,
  });

  @override
  State<InlineQrPaymentCard> createState() => _InlineQrPaymentCardState();
}

class _InlineQrPaymentCardState extends State<InlineQrPaymentCard> {
  late int _secondsRemaining;
  Timer? _countdownTimer;

  @override
  void initState() {
    super.initState();
    _secondsRemaining = widget.initialSecondsRemaining;
    _startCountdown();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  void _startCountdown() {
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          if (_secondsRemaining > 0) {
            _secondsRemaining--;
          } else {
            _countdownTimer?.cancel();
          }
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final qrImageUrl =
        'https://api.qrserver.com/v1/create-qr-code/?size=250x250&data=${Uri.encodeComponent(widget.qrCode)}';

    return Container(
      margin: const EdgeInsets.only(top: 12, left: 4, right: 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFFECE2), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFD84315).withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.qr_code_2_rounded,
                  color: Color(0xFFEA580C), size: 20),
              SizedBox(width: 8),
              Text(
                'Quét mã QR để thanh toán',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1F2937),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(color: Color(0xFFFFF4F0), height: 1),
          const SizedBox(height: 12),
          Text(
            FormatUtils.formatCurrency(widget.amount),
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Hiệu lực QR: ${FormatUtils.formatCountdown(_secondsRemaining)}',
            style: TextStyle(
              fontSize: 11,
              color: _secondsRemaining < 60
                  ? AppColors.error
                  : AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade200, width: 1.5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: CachedNetworkImage(
              imageUrl: qrImageUrl,
              width: 180,
              height: 180,
              placeholder: (context, url) => const SizedBox(
                width: 180,
                height: 180,
                child: Center(
                  child: CircularProgressIndicator(
                      color: AppColors.primary, strokeWidth: 2),
                ),
              ),
              errorWidget: (context, url, error) => const SizedBox(
                width: 180,
                height: 180,
                child: Icon(Icons.error_outline_rounded,
                    color: AppColors.error, size: 40),
              ),
            ),
          ),
          const SizedBox(height: 16),
          OutlinedButton(
            onPressed: widget.onCancel,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.error,
              side: const BorderSide(color: AppColors.error),
              minimumSize: const Size(double.infinity, 38),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Hủy thanh toán',
                style:
                    TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
