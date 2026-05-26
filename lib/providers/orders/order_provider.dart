import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/orders/repositories/order_repository.dart';
import '../../data/orders/models/order_api_model.dart';

final orderRepositoryProvider = Provider<OrderRepository>((ref) {
  return OrderRepository();
});

class OrderNotifier extends StateNotifier<AsyncValue<OrderResponse?>> {
  final OrderRepository _repository;

  OrderNotifier(this._repository) : super(const AsyncValue.data(null));

  Future<bool> createOnlineOrder(CreateOnlineOrderRequest request, {bool useCash = true}) async {
    state = const AsyncValue.loading();
    try {
      final order = await _repository.createOnlineOrder(request);
      
      if (useCash) {
        // Method 0 = Cash
        await _repository.createOrderPayment(order.id, 0);
      }
      
      state = AsyncValue.data(order);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }
}

final orderProvider = StateNotifierProvider<OrderNotifier, AsyncValue<OrderResponse?>>((ref) {
  return OrderNotifier(ref.watch(orderRepositoryProvider));
});
