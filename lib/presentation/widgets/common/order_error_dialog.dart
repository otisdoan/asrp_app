import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/top_notification.dart';
import '../../../providers/cart_provider.dart';

/// Global Order Error Dialog — handles Backend BadRequestExceptions,
/// presents user with choice to clear invalid dish/cart & exit order page safely without app crash.
class OrderErrorDialog {
  static void show(
    BuildContext context,
    WidgetRef ref,
    dynamic error, {
    String? branchId,
    VoidCallback? onDismiss,
  }) {
    final errorMsg = parseError(error);

    // Extract dish name if specified in quotes (e.g. "Món 'bún thơm' chưa được...")
    String? invalidDishName;
    final match = RegExp(r"Món\s+['’]([^'’]+)['’]", caseSensitive: false).firstMatch(errorMsg);
    if (match != null) {
      invalidDishName = match.group(1);
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: const [
            Icon(Icons.warning_amber_rounded, color: Colors.amber, size: 28),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Cảnh báo món ăn',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              errorMsg,
              style: const TextStyle(fontSize: 14, color: Colors.black87, height: 1.4),
            ),
            const SizedBox(height: 14),
            Text(
              invalidDishName != null
                  ? 'Bạn có muốn xóa món "$invalidDishName" và quay lại?'
                  : 'Bạn có muốn xóa giỏ hàng không hợp lệ và quay lại?',
              style: TextStyle(fontSize: 13, color: Colors.grey[700], fontWeight: FontWeight.w500),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(dialogCtx);
              if (onDismiss != null) onDismiss();
            },
            child: const Text('Đóng', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              Navigator.pop(dialogCtx); // Close dialog

              final cartNotifier = ref.read(cartProvider.notifier);
              final carts = ref.read(cartProvider).carts;

              if (invalidDishName != null) {
                bool removed = false;
                for (final entry in carts.entries) {
                  final matchingItem = entry.value.items.cast().firstWhere(
                    (i) => i.name.toLowerCase().contains(invalidDishName!.toLowerCase()),
                    orElse: () => null,
                  );
                  if (matchingItem != null) {
                    cartNotifier.removeItem(matchingItem.id);
                    removed = true;
                    break;
                  }
                }
                if (!removed && branchId != null) {
                  cartNotifier.clearBranchCart(branchId);
                }
              } else if (branchId != null) {
                cartNotifier.clearBranchCart(branchId);
              }

              if (Navigator.canPop(context)) {
                Navigator.pop(context); // Safely exit order page
              }

              TopNotification.show(
                context,
                message: invalidDishName != null
                    ? 'Đã xóa món "$invalidDishName" khỏi giỏ hàng'
                    : 'Đã xóa giỏ hàng không hợp lệ',
                isError: false,
              );
            },
            child: const Text('Xóa món & Thoát', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  static String parseError(dynamic e) {
    if (e is DioException) {
      final data = e.response?.data;
      if (data is Map<String, dynamic>) {
        final msg = data['detail'] ??
            data['Detail'] ??
            data['message'] ??
            data['error'] ??
            data['title'] ??
            data['Title'];
        if (msg != null && msg.toString().isNotEmpty) {
          return msg.toString();
        }
      } else if (data is String && data.isNotEmpty) {
        return data;
      }
    }
    return e.toString().replaceAll('Exception: ', '');
  }
}
