import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

/// Provider lưu trữ toàn bộ lịch sử trò chuyện chat AI.
/// Được tách ra khỏi UI để có thể tái sử dụng từ nhiều màn hình.
///
/// Mỗi message là một Map với các key:
/// - `isUser` (bool): tin nhắn từ user hay AI
/// - `text` (String): nội dung text
/// - `time` (String): HH:mm
/// - `showChips` (bool): hiển thị chip gợi ý hay không
/// - `orderPreview` (Map?): preview hóa đơn tạm tính
/// - `orderDraft` (Map?): draft đặt hàng
/// - `resolvedItems` (List?): danh sách món đã resolve
/// - `recommendations` (List<String>?): gợi ý keyword chips
/// - `branchRecommendations` (List?): danh sách card chi nhánh gợi ý
/// - `qrCode` (String?): nội dung mã QR thanh toán
/// - `orderId` (String?): ID đơn hàng liên kết với QR
/// - `amount` (double?): số tiền thanh toán
/// - `secondsRemaining` (int?): thời gian hiệu lực QR (giây)
final chatHistoryProvider =
    StateProvider<List<Map<String, dynamic>>>((ref) {
  final currentTime = DateFormat('HH:mm').format(DateTime.now());
  return [
    {
      'isUser': false,
      'text':
          'Xin chào! Tôi là trợ lý ảo AI DineX. Tôi có thể giúp gì cho bạn hôm nay? '
          '(Bạn có thể chọn câu hỏi gợi ý bên dưới hoặc tự nhập câu hỏi nhé)',
      'time': currentTime,
      'showChips': true,
    }
  ];
});
