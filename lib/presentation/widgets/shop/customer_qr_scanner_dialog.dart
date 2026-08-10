import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/top_notification.dart';

/// CustomerQrScannerDialog — Allows customers to scan Table QR for Dine-in or Voucher QR codes.
class CustomerQrScannerDialog extends StatefulWidget {
  const CustomerQrScannerDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => const CustomerQrScannerDialog(),
    );
  }

  @override
  State<CustomerQrScannerDialog> createState() => _CustomerQrScannerDialogState();
}

class _CustomerQrScannerDialogState extends State<CustomerQrScannerDialog> {
  final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    facing: CameraFacing.back,
  );
  bool _isProcessing = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_isProcessing) return;

    for (final barcode in capture.barcodes) {
      final rawValue = barcode.rawValue;
      if (rawValue != null && rawValue.isNotEmpty) {
        setState(() => _isProcessing = true);
        _controller.stop();
        Navigator.pop(context);

        if (rawValue.contains('TABLE') || rawValue.contains('table')) {
          TopNotification.showSuccess(
            context,
            message: 'Đã nhận diện Bàn tại quán! Chuyển sang menu gọi món...',
          );
        } else if (rawValue.contains('VOUCHER') || rawValue.contains('PROMO')) {
          TopNotification.showSuccess(
            context,
            message: 'Đã áp dụng mã ưu đãi thành công!',
          );
        } else {
          TopNotification.showInfo(
            context,
            message: 'Nội dung QR: $rawValue',
          );
        }
        break;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.black,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 36),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: SizedBox(
          height: 480,
          child: Stack(
            children: [
              MobileScanner(
                controller: _controller,
                onDetect: _onDetect,
              ),
              Center(
                child: Container(
                  width: 250,
                  height: 250,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.white, width: 2.5),
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
              Positioned(
                top: 12,
                left: 12,
                right: 12,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.qr_code_scanner, color: Colors.white, size: 18),
                          SizedBox(width: 6),
                          Text(
                            'Quét mã bàn / Voucher',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: Colors.white, size: 28),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              Positioned(
                bottom: 24,
                left: 20,
                right: 20,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'Quét mã QR tại bàn để gọi món hoặc mã Voucher ưu đãi',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white70, fontSize: 12),
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
