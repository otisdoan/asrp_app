import 'package:flutter_riverpod/flutter_riverpod.dart';

class MockOrderItem {
  final String name;
  final int price;
  final int quantity;
  final String? extras;

  const MockOrderItem({
    required this.name,
    required this.price,
    required this.quantity,
    this.extras,
  });
}

enum MockOrderStatus {
  pendingConfirm, // Chờ xác nhận
  preparing,      // Đang chuẩn bị (sau khi thu ngân xác nhận)
  ready,          // Chờ nhận đơn (sẵn sàng lấy)
  completed,      // Đã nhận
  cancelled,      // Đã hủy
}

class MockOrder {
  final String id;
  final String storeName;
  final List<MockOrderItem> items;
  final int totalAmount;
  final MockOrderStatus status;
  final DateTime orderTime;
  final DateTime pickupTime;
  final int originalMinutes;
  final int extraMinutes;
  final String? storeNote;
  final List<String> timeline;
  final bool hasNotification; // Có thông báo xin thêm phút hoặc xác nhận mới chưa đọc

  MockOrder({
    required this.id,
    required this.storeName,
    required this.items,
    required this.totalAmount,
    required this.status,
    required this.orderTime,
    required this.pickupTime,
    required this.originalMinutes,
    this.extraMinutes = 0,
    this.storeNote,
    required this.timeline,
    this.hasNotification = false,
  });

  MockOrder copyWith({
    String? id,
    String? storeName,
    List<MockOrderItem>? items,
    int? totalAmount,
    MockOrderStatus? status,
    DateTime? orderTime,
    DateTime? pickupTime,
    int? originalMinutes,
    int? extraMinutes,
    String? storeNote,
    List<String>? timeline,
    bool? hasNotification,
  }) {
    return MockOrder(
      id: id ?? this.id,
      storeName: storeName ?? this.storeName,
      items: items ?? this.items,
      totalAmount: totalAmount ?? this.totalAmount,
      status: status ?? this.status,
      orderTime: orderTime ?? this.orderTime,
      pickupTime: pickupTime ?? this.pickupTime,
      originalMinutes: originalMinutes ?? this.originalMinutes,
      extraMinutes: extraMinutes ?? this.extraMinutes,
      storeNote: storeNote ?? this.storeNote,
      timeline: timeline ?? this.timeline,
      hasNotification: hasNotification ?? this.hasNotification,
    );
  }
}

class OrderListNotifier extends StateNotifier<List<MockOrder>> {
  OrderListNotifier() : super([]) {
    // Khởi tạo sẵn một đơn chuẩn bị để giao diện có dữ liệu lúc ban đầu
    final now = DateTime.now();
    state = [
      MockOrder(
        id: '#SP082',
        storeName: 'Hiên Coffee - 32 Hồ Văn Huê',
        items: [
          const MockOrderItem(name: 'Combo 1: Phần gà + khoai', price: 53000, quantity: 1, extras: 'Thêm Kem muối\n1 Gà sốt cay'),
        ],
        totalAmount: 53000,
        status: MockOrderStatus.preparing,
        orderTime: now.subtract(const Duration(minutes: 5)),
        pickupTime: now.add(const Duration(minutes: 20)),
        originalMinutes: 25,
        timeline: [
          '${_formatTime(now.subtract(const Duration(minutes: 5)))} - Đơn hàng được tạo thành công.',
          '${_formatTime(now.subtract(const Duration(minutes: 3)))} - Thu ngân đã xác nhận đơn hàng và bắt đầu chuẩn bị món.',
        ],
      )
    ];
  }

  void addOrder(MockOrder order) {
    state = [...state, order];
  }

  void confirmOrder(String id) {
    state = state.map((o) {
      if (o.id == id) {
        final nowStr = _getNowTimeString();
        return o.copyWith(
          status: MockOrderStatus.preparing,
          timeline: [...o.timeline, '$nowStr - Thu ngân đã xác nhận đơn hàng và đang chuẩn bị món.'],
          hasNotification: true,
          storeNote: 'Cửa hàng đã xác nhận đơn hàng của bạn.',
        );
      }
      return o;
    }).toList();
  }

  void requestExtraMinutes(String id, int extraMins) {
    state = state.map((o) {
      if (o.id == id) {
        final nowStr = _getNowTimeString();
        final newPickupTime = o.pickupTime.add(Duration(minutes: extraMins));
        return o.copyWith(
          extraMinutes: o.extraMinutes + extraMins,
          pickupTime: newPickupTime,
          storeNote: 'Quán xin thêm $extraMins phút chuẩn bị do đơn hàng quá tải.',
          timeline: [
            ...o.timeline,
            '$nowStr - Thu ngân xin thêm $extraMins phút. Thời gian sẵn sàng mới: ${_formatTime(newPickupTime)}.'
          ],
          hasNotification: true,
        );
      }
      return o;
    }).toList();
  }

  void makeReady(String id) {
    state = state.map((o) {
      if (o.id == id) {
        final nowStr = _getNowTimeString();
        return o.copyWith(
          status: MockOrderStatus.ready,
          storeNote: 'Món ăn đã sẵn sàng! Mời bạn đến nhận.',
          timeline: [...o.timeline, '$nowStr - Món ăn đã hoàn thành. Sẵn sàng chờ bạn đến nhận.'],
          hasNotification: true,
        );
      }
      return o;
    }).toList();
  }

  void completeOrder(String id) {
    state = state.map((o) {
      if (o.id == id) {
        final nowStr = _getNowTimeString();
        return o.copyWith(
          status: MockOrderStatus.completed,
          storeNote: 'Đơn hàng hoàn tất. Cảm ơn bạn!',
          timeline: [...o.timeline, '$nowStr - Đã hoàn thành nhận đơn hàng tại quầy.'],
        );
      }
      return o;
    }).toList();
  }

  void clearNotification(String id) {
    state = state.map((o) {
      if (o.id == id) {
        return o.copyWith(hasNotification: false);
      }
      return o;
    }).toList();
  }

  void cancelOrder(String id) {
    state = state.map((o) {
      if (o.id == id) {
        final nowStr = _getNowTimeString();
        return o.copyWith(
          status: MockOrderStatus.cancelled,
          storeNote: 'Đơn hàng này đã bị hủy.',
          timeline: [...o.timeline, '$nowStr - Khách hàng đã chủ động hủy đơn hàng.'],
        );
      }
      return o;
    }).toList();
  }

  String _getNowTimeString() {
    final now = DateTime.now();
    return '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
  }

  static String _formatTime(DateTime dt) {
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}

final orderProvider = StateNotifierProvider<OrderListNotifier, List<MockOrder>>((ref) {
  return OrderListNotifier();
});
