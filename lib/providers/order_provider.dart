import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/repositories/order_repository.dart';
import '../data/repositories/branch_repository.dart';
import '../core/network/dio_client.dart';

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

  factory MockOrderItem.fromJson(Map<String, dynamic> json) {
    final toppings = json['toppings'] as List<dynamic>? ?? [];
    final toppingNames = toppings.map((t) {
      if (t is! Map) return '';
      final label = t['toppingLabel'] ?? t['name'] ?? '';
      final qty = t['quantity'] ?? 1;
      return qty > 1 ? '$label (x$qty)' : label;
    }).where((name) => name.isNotEmpty).join('\n');

    return MockOrderItem(
      name: json['productName'] ?? json['name'] ?? '',
      price: (json['priceAtTime'] as num?)?.toInt() ?? (json['price'] as num?)?.toInt() ?? 0,
      quantity: json['quantity'] as int? ?? 1,
      extras: toppingNames.isNotEmpty ? toppingNames : null,
    );
  }
}

enum MockOrderStatus {
  pendingConfirm, // Chờ xác nhận
  preparing,      // Đang chuẩn bị (sau khi thu ngân xác nhận)
  ready,          // Chờ nhận đơn (sẵn sàng lấy)
  completed,      // Đã nhận
  cancelled,      // Đã hủy
}

MockOrderStatus _mapBackendStatus(dynamic status) {
  if (status == null) return MockOrderStatus.pendingConfirm;
  final statusStr = status.toString();
  if (statusStr == '0' || statusStr == 'PendingConfirmation') {
    return MockOrderStatus.pendingConfirm;
  } else if (statusStr == '1' || statusStr == 'PendingInventory' || statusStr == '2' || statusStr == 'Preparing') {
    return MockOrderStatus.preparing;
  } else if (statusStr == '3' || statusStr == 'ReadyForPickup') {
    return MockOrderStatus.ready;
  } else if (statusStr == '4' || statusStr == 'Completed') {
    return MockOrderStatus.completed;
  } else if (statusStr == '5' || statusStr == 'Cancelled') {
    return MockOrderStatus.cancelled;
  }
  return MockOrderStatus.pendingConfirm;
}

class MockPayment {
  final String id;
  final String method; // 'Chuyển khoản' | 'Tiền mặt'
  final String status; // 'Chờ xử lý' | 'Đã thanh toán' | 'Thất bại' | 'Đã hoàn tiền' | 'Đã hủy'
  final int amount;
  final String? reference;
  final DateTime date;

  MockPayment({
    required this.id,
    required this.method,
    required this.status,
    required this.amount,
    this.reference,
    required this.date,
  });

  factory MockPayment.fromJson(Map<String, dynamic> json) {
    final methodVal = json['method'];
    String methodStr = 'Chuyển khoản';
    if (methodVal == 0 || methodVal == 'Cash') {
      methodStr = 'Tiền mặt';
    }

    final statusVal = json['status'];
    String statusStr = 'Chờ xử lý';
    if (statusVal == 36 || statusVal == 'Paid') {
      statusStr = 'Đã thanh toán';
    } else if (statusVal == 37 || statusVal == 'Failed') {
      statusStr = 'Thất bại';
    } else if (statusVal == 38 || statusVal == 'Refunded') {
      statusStr = 'Đã hoàn tiền';
    } else if (statusVal == 39 || statusVal == 'Cancelled') {
      statusStr = 'Đã hủy';
    }

    final dateStr = json['paidAt'] as String? ?? json['createdAt'] as String?;
    DateTime date = DateTime.now();
    if (dateStr != null && dateStr.isNotEmpty) {
      try {
        date = DateTime.parse(dateStr).toLocal();
      } catch (_) {}
    }

    return MockPayment(
      id: json['id']?.toString() ?? '',
      method: methodStr,
      status: statusStr,
      amount: (json['amount'] as num?)?.toInt() ?? 0,
      reference: json['transactionReference']?.toString(),
      date: date,
    );
  }
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
  final List<MockPayment> payments;
  final String orderNumber;
  final int discountPercentage;
  final String paymentStatus;
  final String orderType;

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
    this.payments = const [],
    this.orderNumber = '',
    this.discountPercentage = 0,
    this.paymentStatus = 'Pending',
    this.orderType = 'Online',
  });

  bool get isPaid => paymentStatus == 'Paid' || paymentStatus == '1' || payments.any((p) => p.status == 'Đã thanh toán');
  bool get isQrPayment => orderType == 'Online' || orderType == '0' || payments.any((p) => p.method == 'Chuyển khoản');

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
    List<MockPayment>? payments,
    String? orderNumber,
    int? discountPercentage,
    String? paymentStatus,
    String? orderType,
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
      payments: payments ?? this.payments,
      orderNumber: orderNumber ?? this.orderNumber,
      discountPercentage: discountPercentage ?? this.discountPercentage,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      orderType: orderType ?? this.orderType,
    );
  }

  factory MockOrder.fromJson(Map<String, dynamic> json, Map<String, String> branchNames) {
    final rawItems = json['items'] as List<dynamic>? ?? [];
    final itemsList = rawItems.map((item) => MockOrderItem.fromJson(item as Map<String, dynamic>)).toList();
    
    final rawPayments = json['payments'] as List<dynamic>? ?? [];
    final paymentsList = rawPayments.map((p) => MockPayment.fromJson(p as Map<String, dynamic>)).toList();
    
    final orderTimeStr = json['createdAt'] as String?;
    final orderTime = orderTimeStr != null ? DateTime.parse(orderTimeStr).toLocal() : DateTime.now();

    final pickupTimeStr = json['pickupTime'] as String? ?? json['requestedPickupTime'] as String? ?? json['confirmedPickupTime'] as String?;
    final pickupTime = pickupTimeStr != null ? DateTime.parse(pickupTimeStr).toLocal() : orderTime.add(const Duration(minutes: 15));

    final histories = json['histories'] as List<dynamic>? ?? [];
    final List<String> timeline = [];
    for (var h in histories) {
      final hStatus = _mapBackendStatus(h['orderStatus']);
      final hTimeStr = h['createdAt'] as String?;
      final hTime = hTimeStr != null ? DateTime.parse(hTimeStr).toLocal() : null;
      final timeFormatted = hTime != null ? '${hTime.hour.toString().padLeft(2, '0')}:${hTime.minute.toString().padLeft(2, '0')}' : '';
      
      String statusDesc = '';
      switch (hStatus) {
        case MockOrderStatus.pendingConfirm:
          statusDesc = 'Đơn hàng được tạo thành công.';
          break;
        case MockOrderStatus.preparing:
          statusDesc = 'Thu ngân đã xác nhận đơn hàng và bắt đầu chuẩn bị món.';
          break;
        case MockOrderStatus.ready:
          statusDesc = 'Món ăn đã hoàn thành. Sẵn sàng chờ bạn đến nhận.';
          break;
        case MockOrderStatus.completed:
          statusDesc = 'Đã hoàn thành nhận đơn hàng tại quầy.';
          break;
        case MockOrderStatus.cancelled:
          statusDesc = 'Đơn hàng này đã bị hủy.';
          break;
      }
      final note = h['note'] as String?;
      if (note != null && note.isNotEmpty) {
        statusDesc += ' ($note)';
      }
      if (timeFormatted.isNotEmpty) {
        timeline.add('$timeFormatted - $statusDesc');
      } else {
        timeline.add(statusDesc);
      }
    }
    
    if (timeline.isEmpty) {
      final nowStr = '${orderTime.hour.toString().padLeft(2, '0')}:${orderTime.minute.toString().padLeft(2, '0')}';
      timeline.add('$nowStr - Đơn hàng được tạo thành công.');
      final statusVal = _mapBackendStatus(json['orderStatus']);
      if (statusVal == MockOrderStatus.preparing) {
        timeline.add('Cửa hàng đang chuẩn bị món ăn.');
      } else if (statusVal == MockOrderStatus.ready) {
        timeline.add('Món ăn đã hoàn thành. Sẵn sàng chờ bạn đến nhận.');
      } else if (statusVal == MockOrderStatus.completed) {
        timeline.add('Đã hoàn thành nhận đơn hàng tại quầy.');
      } else if (statusVal == MockOrderStatus.cancelled) {
        timeline.add('Đơn hàng này đã bị hủy.');
      }
    }

    final diff = pickupTime.difference(orderTime).inMinutes;
    final originalMins = diff > 0 ? diff : 15;

    final branchId = json['branchId']?.toString() ?? '';
    final branchName = branchNames[branchId] ?? 'Cửa hàng DineX';

    // Calculate extra minutes if proposed pickup time is set
    int extraMins = 0;
    final proposedPickupTimeStr = json['proposedPickupTime'] as String?;
    if (proposedPickupTimeStr != null) {
      final proposedTime = DateTime.parse(proposedPickupTimeStr).toLocal();
      final requestedPickupTimeStr = json['requestedPickupTime'] as String?;
      if (requestedPickupTimeStr != null) {
        final requestedTime = DateTime.parse(requestedPickupTimeStr).toLocal();
        extraMins = proposedTime.difference(requestedTime).inMinutes;
      }
    }

    // Parse discount percentage
    final discountAmount = (json['discountAmount'] as num?)?.toDouble() ?? 0.0;
    final subtotal = (json['subtotal'] as num?)?.toDouble() ?? 0.0;
    int discountPct = 0;
    if (subtotal > 0 && discountAmount > 0) {
      discountPct = ((discountAmount / subtotal) * 100).round();
    }

    return MockOrder(
      id: json['id']?.toString() ?? '',
      storeName: branchName,
      items: itemsList,
      totalAmount: (json['finalAmount'] as num?)?.toInt() ?? (json['totalAmount'] as num?)?.toInt() ?? 0,
      status: _mapBackendStatus(json['orderStatus']),
      orderTime: orderTime,
      pickupTime: pickupTime,
      originalMinutes: originalMins,
      extraMinutes: extraMins > 0 ? extraMins : 0,
      storeNote: json['note'] ?? json['pickupTimeChangeReason'],
      timeline: timeline.reversed.toList(), 
      hasNotification: json['confirmationStatus'] == 'ProposedNewTime' || json['confirmationStatus'] == 4,
      payments: paymentsList,
      orderNumber: json['orderNumber']?.toString() ?? '',
      discountPercentage: discountPct,
      paymentStatus: json['paymentStatus']?.toString() ?? 'Pending',
      orderType: json['orderType']?.toString() ?? 'Online',
    );
  }
}

class OrderListNotifier extends StateNotifier<List<MockOrder>> {
  final OrderRepository _orderRepository = OrderRepository();
  final BranchRepository _branchRepository = BranchRepository();
  final Map<String, String> _branchNames = {};
  bool _isLoading = false;

  bool get isLoading => _isLoading;

  OrderListNotifier() : super([]) {
    // Lazy loaded on demand to prevent unauthenticated API errors on startup
  }

  Future<void> _ensureBranchNamesLoaded() async {
    if (_branchNames.isNotEmpty) return;
    try {
      final branches = await _branchRepository.getBranches();
      for (var b in branches) {
        _branchNames[b.id] = b.name;
      }
    } catch (e) {
      print('[OrderListNotifier] Error loading branch names: $e');
    }
  }

  Future<void> fetchMyOrders() async {
    _isLoading = true;
    try {
      await _ensureBranchNamesLoaded();
      print('[OrderListNotifier] fetchMyOrders access token: ${DioClient().accessToken}');
      final rawOrders = await _orderRepository.getMyOrders();
      print('[OrderListNotifier] fetchMyOrders rawOrders count: ${rawOrders.length}');
      if (rawOrders.isNotEmpty) {
        print('[OrderListNotifier] fetchMyOrders first order keys: ${rawOrders.first.keys}');
        print('[OrderListNotifier] fetchMyOrders first order: ${rawOrders.first}');
      }
      state = rawOrders
          .map((item) {
            try {
              return MockOrder.fromJson(item as Map<String, dynamic>, _branchNames);
            } catch (e, stack) {
              print('[OrderListNotifier] Error parsing customer order: $e');
              print('Order JSON: $item');
              print(stack);
              return null;
            }
          })
          .whereType<MockOrder>()
          .toList()
        ..sort((a, b) => b.orderTime.compareTo(a.orderTime));
      print('[OrderListNotifier] fetchMyOrders mapped orders count: ${state.length}');
    } catch (e, stack) {
      print('[OrderListNotifier] fetchMyOrders error: $e');
      print(stack);
    } finally {
      _isLoading = false;
    }
  }

  /// Tải danh sách đơn hàng cho quản lý/thu ngân (có thể lọc theo chi nhánh)
  Future<void> fetchBranchOrders({String? branchId}) async {
    _isLoading = true;
    try {
      await _ensureBranchNamesLoaded();
      final rawOrders = await _orderRepository.getManagementOrders(branchId: branchId);
      state = rawOrders
          .map((item) {
            try {
              return MockOrder.fromJson(item as Map<String, dynamic>, _branchNames);
            } catch (e, stack) {
              print('[OrderListNotifier] Error parsing branch order: $e');
              print('Order JSON: $item');
              print(stack);
              return null;
            }
          })
          .whereType<MockOrder>()
          .toList();
    } catch (e) {
      print('[OrderListNotifier] fetchBranchOrders error: $e');
    } finally {
      _isLoading = false;
    }
  }

  /// Tải chi tiết một đơn hàng cụ thể
  Future<void> fetchOrderDetail(String id) async {
    try {
      await _ensureBranchNamesLoaded();
      final orderJson = await _orderRepository.getOrderById(id);
      final updatedOrder = MockOrder.fromJson(orderJson, _branchNames);
      final index = state.indexWhere((o) => o.id == id);
      if (index != -1) {
        state = state.map((o) => o.id == id ? updatedOrder : o).toList();
      } else {
        state = [...state, updatedOrder];
      }
    } catch (e) {
      print('[OrderListNotifier] fetchOrderDetail error: $e');
    }
  }

  /// Tạo đơn hàng tại quầy (Kiosk / Takeaway)
  Future<MockOrder> createKioskOrder({
    required String branchId,
    required List<Map<String, dynamic>> items,
    String? note,
  }) async {
    try {
      final payload = {
        'branchId': branchId,
        'paymentMethod': 0, // Cash / Tiền mặt làm mặc định cho Takeaway tại quầy
        'items': items.map((i) => {
          'menuItemId': i['menuItemId'],
          'quantity': i['quantity'],
          'note': i['note'],
        }).toList(),
        'note': note,
      };
      
      final orderJson = await _orderRepository.placeKioskOrder(payload);
      await _ensureBranchNamesLoaded();
      final order = MockOrder.fromJson(orderJson, _branchNames);
      state = [order, ...state];
      return order;
    } catch (e) {
      print('[OrderListNotifier] createKioskOrder error: $e');
      rethrow;
    }
  }

  void addOrder(MockOrder order) {
    state = [...state, order];
  }

  /// Thu ngân xác nhận đơn hàng
  Future<void> confirmOrder(String id) async {
    try {
      final updatedOrderJson = await _orderRepository.confirmOrder(id);
      await _ensureBranchNamesLoaded();
      final updatedOrder = MockOrder.fromJson(updatedOrderJson, _branchNames);
      state = state.map((o) => o.id == id ? updatedOrder : o).toList();
    } catch (e) {
      print('[OrderListNotifier] confirmOrder error: $e');
      rethrow;
    }
  }

  /// Thu ngân xin thêm phút (sử dụng API propose-pickup-time)
  Future<void> requestExtraMinutes(String id, int extraMins) async {
    try {
      final orderIndex = state.indexWhere((o) => o.id == id);
      if (orderIndex == -1) return;
      final order = state[orderIndex];
      final newPickupTime = order.pickupTime.add(Duration(minutes: extraMins));
      
      final updatedOrderJson = await _orderRepository.proposePickupTime(
        id,
        newPickupTime.toUtc().toIso8601String(),
        'Quán xin thêm $extraMins phút chuẩn bị do quá tải.',
      );
      
      await _ensureBranchNamesLoaded();
      final updatedOrder = MockOrder.fromJson(updatedOrderJson, _branchNames);
      state = state.map((o) => o.id == id ? updatedOrder : o).toList();
    } catch (e) {
      print('[OrderListNotifier] requestExtraMinutes error: $e');
      rethrow;
    }
  }

  /// Thu ngân báo đơn đã sẵn sàng lấy món
  Future<void> makeReady(String id) async {
    try {
      final updatedOrderJson = await _orderRepository.markReadyForPickup(id);
      await _ensureBranchNamesLoaded();
      final updatedOrder = MockOrder.fromJson(updatedOrderJson, _branchNames);
      state = state.map((o) => o.id == id ? updatedOrder : o).toList();
    } catch (e) {
      print('[OrderListNotifier] makeReady error: $e');
      rethrow;
    }
  }

  /// Thu ngân hoàn tất giao đơn cho khách
  Future<void> completeOrder(String id) async {
    try {
      final updatedOrderJson = await _orderRepository.completeOrder(id);
      await _ensureBranchNamesLoaded();
      final updatedOrder = MockOrder.fromJson(updatedOrderJson, _branchNames);
      state = state.map((o) => o.id == id ? updatedOrder : o).toList();
    } catch (e) {
      print('[OrderListNotifier] completeOrder error: $e');
      rethrow;
    }
  }

  /// Khách hàng hoặc Thu ngân hủy đơn
  Future<void> cancelOrder(String id, [String? reason]) async {
    try {
      final updatedOrderJson = await _orderRepository.cancelOrder(id, reason: reason);
      await _ensureBranchNamesLoaded();
      final updatedOrder = MockOrder.fromJson(updatedOrderJson, _branchNames);
      state = state.map((o) => o.id == id ? updatedOrder : o).toList();
    } catch (e) {
      print('[OrderListNotifier] cancelOrder error: $e');
      rethrow;
    }
  }

  /// Khách hàng đồng ý thời gian chuẩn bị mới đề xuất
  Future<void> acceptProposedTime(String id) async {
    try {
      final updatedOrderJson = await _orderRepository.acceptProposedPickupTime(id);
      await _ensureBranchNamesLoaded();
      final updatedOrder = MockOrder.fromJson(updatedOrderJson, _branchNames);
      state = state.map((o) => o.id == id ? updatedOrder : o).toList();
    } catch (e) {
      print('[OrderListNotifier] acceptProposedTime error: $e');
      rethrow;
    }
  }

  /// Khách hàng từ chối thời gian chuẩn bị mới đề xuất
  Future<void> declineProposedTime(String id) async {
    try {
      final updatedOrderJson = await _orderRepository.declineProposedPickupTime(id);
      await _ensureBranchNamesLoaded();
      final updatedOrder = MockOrder.fromJson(updatedOrderJson, _branchNames);
      state = state.map((o) => o.id == id ? updatedOrder : o).toList();
    } catch (e) {
      print('[OrderListNotifier] declineProposedTime error: $e');
      rethrow;
    }
  }

  void clearNotification(String id) {
    state = state.map((o) {
      if (o.id == id) {
        return o.copyWith(hasNotification: false);
      }
      return o;
    }).toList();
  }
}

final orderProvider = StateNotifierProvider<OrderListNotifier, List<MockOrder>>((ref) {
  return OrderListNotifier();
});
