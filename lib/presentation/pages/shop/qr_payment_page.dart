import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/format_utils.dart';
import '../../../data/repositories/order_repository.dart';
import 'payment_success_page.dart';
import 'order_failure_page.dart';
import 'cancel_success_page.dart';

class QrPaymentPage extends StatefulWidget {
  final String orderId;
  final String qrCode;
  final double amount;
  final String checkoutUrl;

  const QrPaymentPage({
    super.key,
    required this.orderId,
    required this.qrCode,
    required this.amount,
    required this.checkoutUrl,
  });

  @override
  State<QrPaymentPage> createState() => _QrPaymentPageState();
}

class _QrPaymentPageState extends State<QrPaymentPage> {
  final OrderRepository _orderRepository = OrderRepository();
  Timer? _pollingTimer;
  bool _isChecking = false;
  int _secondsRemaining = 600; // 10 minutes timeout for PayOS link
  Timer? _countdownTimer;

  @override
  void initState() {
    super.initState();
    _startCountdown();
    _startPolling();
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
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

  void _startPolling() {
    // Poll every 3 seconds to check if payment succeeded
    _pollingTimer = Timer.periodic(const Duration(seconds: 3), (timer) async {
      if (_isChecking) return;
      _isChecking = true;

      try {
        final orderJson = await _orderRepository.getOrderById(widget.orderId);
        final status = orderJson['orderStatus']?.toString();
        final paymentStatus = orderJson['paymentStatus']?.toString();
        
        // Check if the order is no longer in unpaid/draft status
        bool isPaid = false;
        
        // 1. Direct check of paymentStatus
        if (paymentStatus == 'Paid' || paymentStatus == '1') {
          isPaid = true;
        }
        
        // 2. Double check payment status inside the JSON payments list
        final payments = orderJson['payments'] as List<dynamic>? ?? [];
        if (payments.isNotEmpty) {
          final firstPayment = payments.first;
          final payStatus = firstPayment['status']?.toString();
          if (payStatus == 'Paid' || payStatus == '36') {
            isPaid = true;
          }
        }
        
        // 3. Fallback: if orderStatus represents a paid progress state (preparing or later)
        // We exclude PendingConfirmation / 0 because those are the initial unpaid order status.
        if (status == 'Preparing' || status == '2' || status == 'ReadyForPickup' || status == '3' || status == 'Completed' || status == '4') {
          isPaid = true;
        }

        if (isPaid) {
          _pollingTimer?.cancel();
          _countdownTimer?.cancel();
          if (mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => PaymentSuccessPage(orderId: widget.orderId),
              ),
            );
          }
        }
      } catch (e) {
        print('[QrPaymentPage] Polling error: $e');
      } finally {
        _isChecking = false;
      }
    });
  }



  void _showCancelConfirmation() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Xác nhận hủy thanh toán?', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text(
          'Bạn có chắc chắn muốn hủy thanh toán và hủy đơn hàng này không? Hành động này không thể hoàn tác.',
          style: TextStyle(color: AppColors.textSecondary, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Không', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx); // Close confirmation dialog
              _cancelOrder(); // Trigger cancel API
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              elevation: 0,
            ),
            child: const Text('Hủy thanh toán'),
          ),
        ],
      ),
    );
  }

  Future<void> _cancelOrder() async {
    // Show a loading indicator dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      ),
    );

    try {
      await _orderRepository.cancelOrder(widget.orderId);
      
      // Close the loading dialog
      if (mounted) Navigator.pop(context);

      _pollingTimer?.cancel();
      _countdownTimer?.cancel();

      // Navigate to CancelSuccessPage
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => CancelSuccessPage(orderId: widget.orderId),
          ),
        );
      }
    } catch (e) {
      // Close the loading dialog
      if (mounted) Navigator.pop(context);

      // Show error snackbar
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi hủy thanh toán: ${e.toString().replaceAll('Exception: ', '')}'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _onBackPressed() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Rời khỏi trang thanh toán?', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text(
          'Đơn hàng của bạn đã được khởi tạo. Bạn vẫn có thể tiếp tục thanh toán sau trong chi tiết đơn hàng.',
          style: TextStyle(color: AppColors.textSecondary, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Ở lại', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx); // Close dialog
              _pollingTimer?.cancel();
              _countdownTimer?.cancel();
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) => OrderFailurePage(orderId: widget.orderId),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              elevation: 0,
            ),
            child: const Text('Xác nhận rời'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Generate QR image URL using qrserver API
    final qrImageUrl = 'https://api.qrserver.com/v1/create-qr-code/?size=300x300&data=${Uri.encodeComponent(widget.qrCode)}';

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          _onBackPressed();
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F6F8),
        appBar: AppBar(
          backgroundColor: AppColors.primary,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
            onPressed: _onBackPressed,
          ),
          centerTitle: true,
          title: const Text(
            'Thanh toán VietQR',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // ─── Amount Card ───────────────────────────────────────────────
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x08000000),
                      blurRadius: 10,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    const Text(
                      'Số tiền cần thanh toán',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      FormatUtils.formatCurrency(widget.amount),
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Divider(color: Colors.grey.shade200, height: 1),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Mã đơn hàng',
                          style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        ),
                        Text(
                          widget.orderId.substring(0, 8).toUpperCase(),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // ─── QR Code Card ──────────────────────────────────────────────
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x08000000),
                      blurRadius: 10,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    const Text(
                      'Quét mã QR để chuyển khoản',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Hiệu lực QR: ${FormatUtils.formatCountdown(_secondsRemaining)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: _secondsRemaining < 60 ? AppColors.error : AppColors.textSecondary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // QR Image
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade200, width: 1.5),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: CachedNetworkImage(
                        imageUrl: qrImageUrl,
                        width: 200,
                        height: 200,
                        placeholder: (context, url) => Container(
                          width: 200,
                          height: 200,
                          color: Colors.grey.shade50,
                          child: const Center(
                            child: CircularProgressIndicator(color: AppColors.primary),
                          ),
                        ),
                        errorWidget: (context, url, error) => Container(
                          width: 200,
                          height: 200,
                          color: Colors.grey.shade100,
                          child: const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 48),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // ─── Help Instructions ──────────────────────────────────────────
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Hướng dẫn thanh toán:',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _buildStepRow('1', 'Mở ứng dụng ngân hàng hoặc ví điện tử (Momo, ShopeePay,...).'),
                    const SizedBox(height: 8),
                    _buildStepRow('2', 'Chọn chức năng quét mã QR (VietQR) và quét ảnh trên.'),
                    const SizedBox(height: 8),
                    _buildStepRow('3', 'Kiểm tra thông tin tài khoản đích và bấm Xác nhận thanh toán.'),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              ElevatedButton(
                onPressed: _showCancelConfirmation,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Hủy thanh toán',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStepRow(String stepNum, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 18,
          height: 18,
          decoration: const BoxDecoration(
            color: AppColors.bgSoft,
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Text(
            stepNum,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }
}
