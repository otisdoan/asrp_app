import 'package:dio/dio.dart';
import '../../../core/network/dio_client.dart';
import '../models/order_api_model.dart';

class OrderRemoteDataSource {
  final Dio _dio;

  OrderRemoteDataSource({Dio? dio}) : _dio = dio ?? DioClient().dio;

  Future<OrderResponse> createOnlineOrder(CreateOnlineOrderRequest request) async {
    try {
      final response = await _dio.post(
        '/orders/online',
        data: request.toJson(),
      );

      final data = response.data['data'] ?? response.data;
      return OrderResponse.fromJson(data);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> createOrderPayment(String orderId, CreateOrderPaymentRequest request) async {
    try {
      await _dio.post(
        '/orders/$orderId/payments',
        data: request.toJson(),
      );
    } catch (e) {
      rethrow;
    }
  }
}
