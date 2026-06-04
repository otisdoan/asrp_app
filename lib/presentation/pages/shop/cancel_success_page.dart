import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

/// CancelSuccessPage — Shown after an order is successfully canceled.
/// Displays cancellation status and a satisfaction rating survey.
class CancelSuccessPage extends StatefulWidget {
  final String orderId;

  const CancelSuccessPage({super.key, required this.orderId});

  @override
  State<CancelSuccessPage> createState() => _CancelSuccessPageState();
}

class _CancelSuccessPageState extends State<CancelSuccessPage> {
  int _rating = 0;
  bool _submitted = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      // ─── Header Bar ────────────────────────────────────────────────────────
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: const Text(
          'Hoàn tiền đã được phê duyệt',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline_rounded, color: Colors.white),
            onPressed: () {
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  backgroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  title: const Text('Trợ giúp'),
                  content: const Text(
                    'Đơn hàng của bạn đã được hủy thành công. Số tiền thanh toán (nếu có) sẽ được hoàn lại theo quy định của hệ thống.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text(
                        'Đóng',
                        style: TextStyle(color: AppColors.primary),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // ─── Banner Canceled Status ────────────────────────────────────────
          Container(
            width: double.infinity,
            height: 90,
            color: AppColors.secondary,
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Đã hủy đơn',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                // Watermark Cancel Icon
                Icon(
                  Icons.cancel_presentation_rounded,
                  size: 54,
                  color: Colors.white.withValues(alpha: 0.12),
                ),
              ],
            ),
          ),

          // ─── Feedback Card ─────────────────────────────────────────────────
          Container(
            width: double.infinity,
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                const Text(
                  'Vui lòng cho biết mức độ hài lòng của bạn đối với trải nghiệm hủy đơn?',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 20),

                // Interactive 5-star Rating
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (index) {
                    final starIndex = index + 1;
                    final isSelected = starIndex <= _rating;
                    return GestureDetector(
                      onTap: () {
                        if (!_submitted) {
                          setState(() {
                            _rating = starIndex;
                          });
                        }
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: Icon(
                          Icons.star_rounded,
                          size: 38,
                          color: isSelected
                              ? const Color(0xFFEF9F27)
                              : const Color(0xFFE5E7EB),
                        ),
                      ),
                    );
                  }),
                ),

                if (_rating > 0) ...[
                  const SizedBox(height: 16),
                  AnimatedOpacity(
                    opacity: 1.0,
                    duration: const Duration(milliseconds: 300),
                    child: Text(
                      _submitted
                          ? 'Cảm ơn phản hồi của bạn!'
                          : 'Bạn đánh giá $_rating/5 sao.',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: _submitted ? AppColors.success : AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const Spacer(),

          // ─── Action Button ─────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(20),
            child: SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () {
                  if (_rating > 0 && !_submitted) {
                    setState(() {
                      _submitted = true;
                    });
                    final navigator = Navigator.of(context);
                    Future.delayed(const Duration(seconds: 1), () {
                      if (mounted) {
                        navigator.pop(); // Go back to orders
                      }
                    });
                  } else {
                    Navigator.pop(context); // Just go back
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  _rating > 0 && !_submitted ? 'Gửi đánh giá' : 'Quay lại đơn hàng',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}
