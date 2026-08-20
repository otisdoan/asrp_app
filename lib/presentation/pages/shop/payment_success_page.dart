import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import 'order_detail_page.dart';
import 'chat_assistant_page.dart';
import '../../widgets/common/you_may_also_like_section.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_constants.dart';

class PaymentSuccessPage extends ConsumerWidget {
  final String orderId;

  const PaymentSuccessPage({super.key, required this.orderId});

  void _goToHome(BuildContext context) {
    Navigator.of(context).popUntil((route) => route.isFirst);
    context.go(AppConstants.routeHome);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: Colors.white, size: 20),
          onPressed: () => _goToHome(context),
        ),
        centerTitle: true,
        title: const Text(
          'Thanh toán thành công',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 36),
              // Checkmark Icon
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check_circle_rounded,
                  size: 72,
                  color: Colors.green.shade600,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Thanh toán hoàn tất!',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  'Đơn hàng của bạn đã được thanh toán thành công. Cửa hàng đang chuẩn bị món ăn nóng hổi cho bạn.',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 36),
              // Divider
              Container(
                height: 1,
                color: AppColors.outlineVariant,
                margin: const EdgeInsets.symmetric(horizontal: 24),
              ),
              const SizedBox(height: 24),
              // "Có thể bạn cũng thích" Section
              const YouMayAlsoLikeSection(
                padding: EdgeInsets.symmetric(horizontal: 24),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(
            top: BorderSide(color: AppColors.outlineVariant, width: 1),
          ),
        ),
        child: SafeArea(
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (_) => OrderDetailPage(orderId: orderId),
                      ),
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: const BorderSide(color: AppColors.primary),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                  child: const Text(
                    'Xem tiến độ đơn',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ChatAssistantPage(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.chat_bubble_outline_rounded, size: 16, color: Colors.white),
                  label: const Text(
                    'Quay lại khung chat',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                    elevation: 0,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
