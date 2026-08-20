import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../core/services/chat_storage_service.dart';

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

/// Extension trợ giúp để tự động đồng bộ state của chatHistoryProvider xuống Local Storage
extension ChatHistoryNotifierX on StateController<List<Map<String, dynamic>>> {
  void updateHistoryAndSave(List<Map<String, dynamic>> newHistory, String sessionId) {
    state = newHistory;
    ChatStorageService().saveChatHistory(sessionId, newHistory);
  }

  void addMessageAndSave(Map<String, dynamic> message, String sessionId) {
    final newState = [...state, message];
    state = newState;
    ChatStorageService().saveChatHistory(sessionId, newState);
  }

  void updateStateAndSave(List<Map<String, dynamic>> Function(List<Map<String, dynamic>>) updateFn, String sessionId) {
    final newState = updateFn(state);
    state = newState;
    ChatStorageService().saveChatHistory(sessionId, newState);
  }

  void syncWithOrders(List<dynamic> orders, String sessionId) {
    final currentState = List<Map<String, dynamic>>.from(state);
    bool isChanged = false;

    for (var order in orders) {
      final bool isPaid = (order.isPaid == true);
      if (!isPaid) continue;

      final orderId = order.id?.toString();
      if (orderId == null || orderId.isEmpty) continue;

      final existingIndex = currentState.indexWhere((msg) => msg['orderId'] == orderId);
      final storeName = order.storeName;
      final double amount = (order.totalAmount as num?)?.toDouble() ?? 0.0;
      final items = order.items != null
          ? (order.items as List<dynamic>).map((i) => {
                'menu_item_name': i.name,
                'quantity': i.quantity,
                'price': (i.price as num?)?.toDouble() ?? 0.0,
              }).toList()
          : null;
      final DateTime orderTime = order.orderTime is DateTime ? order.orderTime : DateTime.now();
      final timeStr = '${orderTime.hour.toString().padLeft(2, '0')}:${orderTime.minute.toString().padLeft(2, '0')}';

      if (existingIndex != -1) {
        final existing = currentState[existingIndex];
        if (existing['isPaidBill'] != true) {
          currentState[existingIndex] = {
            ...existing,
            'isPaidBill': true,
            'qrCode': null,
            if (storeName != null) 'storeName': storeName,
            'amount': amount,
            if (items != null) 'items': items,
            'text': 'Cảm ơn bạn! Đơn hàng đã được thanh toán thành công. Mã QR lấy hàng tại quán của bạn bên dưới:',
            'updatedAt': orderTime,
          };
          isChanged = true;
        }
      } else {
        final newPaidMsg = {
          'isUser': false,
          'messageType': 'PAYMENT_SUCCESS',
          'isPaidBill': true,
          'orderId': orderId,
          'amount': amount,
          if (storeName != null) 'storeName': storeName,
          if (items != null) 'items': items,
          'text': 'Cảm ơn bạn! Dạ em đã nhận được thanh toán. Mã QR lấy hàng tại quán đã sẵn sàng bên dưới nhé!',
          'time': timeStr,
          'updatedAt': orderTime,
        };
        currentState.add(newPaidMsg);
        isChanged = true;
      }
    }

    if (isChanged) {
      currentState.sort((a, b) => parseChatMsgTime(a['updatedAt']).compareTo(parseChatMsgTime(b['updatedAt'])));
      state = currentState;
      ChatStorageService().saveChatHistory(sessionId, currentState);
    }
  }
}

DateTime parseChatMsgTime(dynamic time) {
  if (time is DateTime) return time;
  if (time is String && time.isNotEmpty) {
    final parsed = DateTime.tryParse(time);
    if (parsed != null) return parsed;

    if (time.contains(':')) {
      try {
        final parts = time.split(':');
        final hour = int.parse(parts[0].trim());
        final minute = int.parse(parts[1].trim());
        final now = DateTime.now();
        return DateTime(now.year, now.month, now.day, hour, minute);
      } catch (_) {}
    }
  }
  return DateTime.fromMillisecondsSinceEpoch(0);
}

