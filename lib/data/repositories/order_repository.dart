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
}
