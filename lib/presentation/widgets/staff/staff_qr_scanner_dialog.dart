import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/qr_utils.dart';

/// StaffQrScannerDialog — Uses mobile camera to scan customer pickup QR codes.
class StaffQrScannerDialog extends StatefulWidget {
  final ValueChanged<String> onOrderScanned;

  const StaffQrScannerDialog({
    super.key,
    required this.onOrderScanned,
  });

  static Future<void> show(
    BuildContext context, {
    required ValueChanged<String> onOrderScanned,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => StaffQrScannerDialog(onOrderScanned: onOrderScanned),
    );
  }

  @override
  State<StaffQrScannerDialog> createState() => _StaffQrScannerDialogState();
}

class _StaffQrScannerDialogState extends State<StaffQrScannerDialog> {
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
        final orderId = QrUtils.parseOrderQrPayload(rawValue);
        if (orderId != null) {
          setState(() {
            _isProcessing = true;
          });
          _controller.stop();
          Navigator.pop(context); // Close scanner dialog
          widget.onOrderScanned(orderId);
          break;
        }
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
              // 1. Camera Feed
              MobileScanner(
                controller: _controller,
                onDetect: _onDetect,
              ),

              // 2. Scanner Overlay Frame
              Center(
                child: Container(
                  width: 250,
                  height: 250,
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.primary, width: 3),
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),

              // 3. Header Controls
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
                            'Quét mã lấy hàng',
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

              // 4. Bottom Hint
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
                    'Di chuyển camera vào mã QR đơn hàng trên máy của khách',
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
