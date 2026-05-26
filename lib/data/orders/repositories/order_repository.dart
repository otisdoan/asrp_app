import '../data_sources/order_remote_data_source.dart';
import '../models/order_api_model.dart';

class OrderRepository {
  final OrderRemoteDataSource _remoteDataSource;

  OrderRepository({OrderRemoteDataSource? remoteDataSource})
      : _remoteDataSource = remoteDataSource ?? OrderRemoteDataSource();

  Future<OrderResponse> createOnlineOrder(CreateOnlineOrderRequest request) async {
    return _remoteDataSource.createOnlineOrder(request);
  }

  Future<void> createOrderPayment(String orderId, int method) async {
    final request = CreateOrderPaymentRequest(method: method);
    return _remoteDataSource.createOrderPayment(orderId, request);
  }
}
