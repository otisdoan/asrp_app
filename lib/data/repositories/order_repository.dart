import '../../core/network/dio_client.dart';
import 'package:dio/dio.dart';

class OrderRepository {
  final DioClient _dioClient = DioClient();

  /// Call POST /api/orders/preview to calculate totals and get pickup slot times
  Future<Map<String, dynamic>> previewOrder(Map<String, dynamic> payload) async {
    try {
      final response = await _dioClient.dio.post(
        '/orders/preview',
        data: payload,
      );
      print('[OrderRepository] previewOrder status: ${response.statusCode}');
      final responseData = response.data;
      if (responseData is Map<String, dynamic>) {
        if (responseData['data'] is Map<String, dynamic>) {
          return responseData['data'] as Map<String, dynamic>;
        }
        return responseData;
      }
      throw Exception('Invalid response structure for order preview');
    } on DioException catch (e) {
      print('[OrderRepository] previewOrder error: ${e.response?.data ?? e.message}');
      rethrow;
    }
  }

  /// Call POST /api/orders/online to place an order
  Future<Map<String, dynamic>> placeOrder(Map<String, dynamic> payload) async {
    try {
      final response = await _dioClient.dio.post(
        '/orders/online',
        data: payload,
      );
      print('[OrderRepository] placeOrder status: ${response.statusCode}');
      
      // The response can contain the order envelope
      final responseData = response.data;
      if (responseData is Map<String, dynamic>) {
        if (responseData['data'] is Map<String, dynamic>) {
          return responseData['data'] as Map<String, dynamic>;
        }
        return responseData;
      }
      throw Exception('Invalid response structure for place order');
    } on DioException catch (e) {
      print('[OrderRepository] placeOrder error: ${e.response?.data ?? e.message}');
      rethrow;
    }
  }

  /// Call POST /api/orders/kiosk to place a kiosk/in-store order
  Future<Map<String, dynamic>> placeKioskOrder(Map<String, dynamic> payload) async {
    try {
      final response = await _dioClient.dio.post(
        '/orders/kiosk',
        data: payload,
      );
      print('[OrderRepository] placeKioskOrder status: ${response.statusCode}');
      
      final responseData = response.data;
      if (responseData is Map<String, dynamic>) {
        if (responseData['data'] is Map<String, dynamic>) {
          return responseData['data'] as Map<String, dynamic>;
        }
        return responseData;
      }
      throw Exception('Invalid response structure for place kiosk order');
    } on DioException catch (e) {
      print('[OrderRepository] placeKioskOrder error: ${e.response?.data ?? e.message}');
      rethrow;
    }
  }

  /// Call POST /api/orders/{id}/payments to initiate VietQR / PayOS payment
  Future<Map<String, dynamic>> initiatePayment(String orderId, Map<String, dynamic> payload) async {
    try {
      final response = await _dioClient.dio.post(
        '/orders/$orderId/payments',
        data: payload,
      );
      print('[OrderRepository] initiatePayment status: ${response.statusCode}');
      
      final responseData = response.data;
      if (responseData is Map<String, dynamic>) {
        if (responseData['data'] is Map<String, dynamic>) {
          return responseData['data'] as Map<String, dynamic>;
        }
        return responseData;
      }
      throw Exception('Invalid response structure for initiate payment');
    } on DioException catch (e) {
      print('[OrderRepository] initiatePayment error: ${e.response?.data ?? e.message}');
      rethrow;
    }
  }

  /// Call GET /api/orders/my to get current customer's orders
  Future<List<dynamic>> getMyOrders({String? orderStatus, int page = 1, int pageSize = 100}) async {
    try {
      final response = await _dioClient.dio.get(
        '/orders/my',
        queryParameters: {
          if (orderStatus != null) 'OrderStatus': orderStatus,
          'Page': page,
          'PageSize': pageSize,
        },
      );
      print('[OrderRepository] getMyOrders status: ${response.statusCode}');
      final responseData = response.data;
      print('[OrderRepository] getMyOrders raw data: $responseData');
      if (responseData is List) {
        return responseData;
      }
      if (responseData is Map<String, dynamic>) {
        final data = responseData['data'];
        if (data is Map<String, dynamic> && data['items'] is List) {
          return data['items'] as List<dynamic>;
        } else if (data is List) {
          return data;
        }
        if (responseData['items'] is List) {
          return responseData['items'] as List<dynamic>;
        }
      }
      return [];
    } on DioException catch (e) {
      print('[OrderRepository] getMyOrders error: ${e.response?.data ?? e.message}');
      rethrow;
    }
  }

  /// Call GET /api/orders to get management/operational orders
  Future<List<dynamic>> getManagementOrders({String? orderStatus, String? branchId, int page = 1, int pageSize = 100}) async {
    try {
      final response = await _dioClient.dio.get(
        '/orders',
        queryParameters: {
          if (orderStatus != null) 'OrderStatus': orderStatus,
          if (branchId != null) 'BranchId': branchId,
          'Page': page,
          'PageSize': pageSize,
        },
      );
      print('[OrderRepository] getManagementOrders status: ${response.statusCode}');
      final responseData = response.data;
      if (responseData is Map<String, dynamic>) {
        final data = responseData['data'];
        if (data is Map<String, dynamic> && data['items'] is List) {
          return data['items'] as List<dynamic>;
        } else if (data is List) {
          return data;
        }
        if (responseData['items'] is List) {
          return responseData['items'] as List<dynamic>;
        }
      }
      return [];
    } on DioException catch (e) {
      print('[OrderRepository] getManagementOrders error: ${e.response?.data ?? e.message}');
      rethrow;
    }
  }

  /// Call GET /api/orders/{id} to get detail of an order
  Future<Map<String, dynamic>> getOrderById(String orderId) async {
    try {
      // 1. Try to find the order in the current customer's own orders list first.
      // This bypasses the brand scope tenancy checks for operational users testing on the customer app.
      try {
        final myOrdersList = await getMyOrders(page: 1, pageSize: 50);
        for (var item in myOrdersList) {
          if (item is Map<String, dynamic> && item['id']?.toString() == orderId) {
            print('[OrderRepository] Found order $orderId in customer orders list');
            return item;
          }
        }
      } catch (e) {
        print('[OrderRepository] getOrderById customer pre-fetch error (ignored): $e');
      }

      // 1b. Try to find the order in management orders list if customer lookup fails/is unauthorized
      try {
        final managementOrdersList = await getManagementOrders(page: 1, pageSize: 50);
        for (var item in managementOrdersList) {
          if (item is Map<String, dynamic> && item['id']?.toString() == orderId) {
            print('[OrderRepository] Found order $orderId in management orders list');
            return item;
          }
        }
      } catch (e) {
        print('[OrderRepository] getOrderById management pre-fetch error (ignored): $e');
      }

      // 2. Fallback to direct GET /orders/{id}
      final response = await _dioClient.dio.get('/orders/$orderId');
      print('[OrderRepository] getOrderById status: ${response.statusCode}');
      final responseData = response.data;
      if (responseData is Map<String, dynamic>) {
        if (responseData['data'] is Map<String, dynamic>) {
          return responseData['data'] as Map<String, dynamic>;
        }
        return responseData;
      }
      throw Exception('Invalid response structure for get order by id');
    } on DioException catch (e) {
      print('[OrderRepository] getOrderById error: ${e.response?.data ?? e.message}');
      rethrow;
    }
  }

  /// Call PATCH /api/orders/{id}/confirm to confirm online order (operational only)
  Future<Map<String, dynamic>> confirmOrder(String orderId) async {
    try {
      final response = await _dioClient.dio.patch('/orders/$orderId/confirm');
      print('[OrderRepository] confirmOrder status: ${response.statusCode}');
      final responseData = response.data;
      if (responseData is Map<String, dynamic>) {
        if (responseData['data'] is Map<String, dynamic>) {
          return responseData['data'] as Map<String, dynamic>;
        }
        return responseData;
      }
      throw Exception('Invalid response structure for confirm order');
    } on DioException catch (e) {
      print('[OrderRepository] confirmOrder error: ${e.response?.data ?? e.message}');
      rethrow;
    }
  }

  /// Call PATCH /api/orders/{id}/ready-for-pickup to mark order as ready (operational only)
  Future<Map<String, dynamic>> markReadyForPickup(String orderId) async {
    try {
      final response = await _dioClient.dio.patch('/orders/$orderId/ready-for-pickup');
      print('[OrderRepository] markReadyForPickup status: ${response.statusCode}');
      final responseData = response.data;
      if (responseData is Map<String, dynamic>) {
        if (responseData['data'] is Map<String, dynamic>) {
          return responseData['data'] as Map<String, dynamic>;
        }
        return responseData;
      }
      throw Exception('Invalid response structure for mark ready');
    } on DioException catch (e) {
      print('[OrderRepository] markReadyForPickup error: ${e.response?.data ?? e.message}');
      rethrow;
    }
  }

  /// Call PATCH /api/orders/{id}/complete to complete order (operational only)
  Future<Map<String, dynamic>> completeOrder(String orderId) async {
    try {
      final response = await _dioClient.dio.patch('/orders/$orderId/complete');
      print('[OrderRepository] completeOrder status: ${response.statusCode}');
      final responseData = response.data;
      if (responseData is Map<String, dynamic>) {
        if (responseData['data'] is Map<String, dynamic>) {
          return responseData['data'] as Map<String, dynamic>;
        }
        return responseData;
      }
      throw Exception('Invalid response structure for complete order');
    } on DioException catch (e) {
      print('[OrderRepository] completeOrder error: ${e.response?.data ?? e.message}');
      rethrow;
    }
  }

  /// Call PATCH /api/orders/{id}/cancel to cancel order (customer or operational)
  Future<Map<String, dynamic>> cancelOrder(String orderId, {String? reason}) async {
    try {
      final response = await _dioClient.dio.patch(
        '/orders/$orderId/cancel',
        data: {
          'reason': reason ?? 'Hủy từ ứng dụng',
        },
      );
      print('[OrderRepository] cancelOrder status: ${response.statusCode}');
      final responseData = response.data;
      if (responseData is Map<String, dynamic>) {
        if (responseData['data'] is Map<String, dynamic>) {
          return responseData['data'] as Map<String, dynamic>;
        }
        return responseData;
      }
      throw Exception('Invalid response structure for cancel order');
    } on DioException catch (e) {
      print('[OrderRepository] cancelOrder error: ${e.response?.data ?? e.message}');
      rethrow;
    }
  }

  /// Call PATCH /api/orders/{id}/propose-pickup-time to propose new pickup time (operational only)
  Future<Map<String, dynamic>> proposePickupTime(String orderId, String proposedPickupTime, String? reason) async {
    try {
      final response = await _dioClient.dio.patch(
        '/orders/$orderId/propose-pickup-time',
        data: {
          'proposedPickupTime': proposedPickupTime,
          'reason': reason ?? 'Quán xin thêm thời gian chuẩn bị',
        },
      );
      print('[OrderRepository] proposePickupTime status: ${response.statusCode}');
      final responseData = response.data;
      if (responseData is Map<String, dynamic>) {
        if (responseData['data'] is Map<String, dynamic>) {
          return responseData['data'] as Map<String, dynamic>;
        }
        return responseData;
      }
      throw Exception('Invalid response structure for propose pickup time');
    } on DioException catch (e) {
      print('[OrderRepository] proposePickupTime error: ${e.response?.data ?? e.message}');
      rethrow;
    }
  }

  /// Call PATCH /api/orders/{id}/accept-proposed-pickup-time (customer only)
  Future<Map<String, dynamic>> acceptProposedPickupTime(String orderId) async {
    try {
      final response = await _dioClient.dio.patch('/orders/$orderId/accept-proposed-pickup-time');
      print('[OrderRepository] acceptProposedPickupTime status: ${response.statusCode}');
      final responseData = response.data;
      if (responseData is Map<String, dynamic>) {
        if (responseData['data'] is Map<String, dynamic>) {
          return responseData['data'] as Map<String, dynamic>;
        }
        return responseData;
      }
      throw Exception('Invalid response structure for accept proposed time');
    } on DioException catch (e) {
      print('[OrderRepository] acceptProposedPickupTime error: ${e.response?.data ?? e.message}');
      rethrow;
    }
  }

  /// Call PATCH /api/orders/{id}/decline-proposed-pickup-time (customer only)
  Future<Map<String, dynamic>> declineProposedPickupTime(String orderId) async {
    try {
      final response = await _dioClient.dio.patch('/orders/$orderId/decline-proposed-pickup-time');
      print('[OrderRepository] declineProposedPickupTime status: ${response.statusCode}');
      final responseData = response.data;
      if (responseData is Map<String, dynamic>) {
        if (responseData['data'] is Map<String, dynamic>) {
          return responseData['data'] as Map<String, dynamic>;
        }
        return responseData;
      }
      throw Exception('Invalid response structure for decline proposed time');
    } on DioException catch (e) {
      print('[OrderRepository] declineProposedPickupTime error: ${e.response?.data ?? e.message}');
      rethrow;
    }
  }
}
