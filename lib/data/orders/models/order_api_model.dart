class CreateOnlineOrderRequest {
  final String branchId;
  final String pickupTime;
  final List<OrderItemRequest> items;
  final String? note;

  CreateOnlineOrderRequest({
    required this.branchId,
    required this.pickupTime,
    required this.items,
    this.note,
  });

  Map<String, dynamic> toJson() {
    return {
      'branchId': branchId,
      'pickupTime': pickupTime,
      'items': items.map((e) => e.toJson()).toList(),
      if (note != null) 'note': note,
    };
  }
}

class OrderItemRequest {
  final String menuItemId;
  final String? sizeId;
  final int quantity;
  final String? note;
  final List<OrderItemToppingRequest>? toppings;

  OrderItemRequest({
    required this.menuItemId,
    this.sizeId,
    required this.quantity,
    this.note,
    this.toppings,
  });

  Map<String, dynamic> toJson() {
    return {
      'menuItemId': menuItemId,
      if (sizeId != null) 'sizeId': sizeId,
      'quantity': quantity,
      if (note != null) 'note': note,
      if (toppings != null) 'toppings': toppings!.map((e) => e.toJson()).toList(),
    };
  }
}

class OrderItemToppingRequest {
  final String toppingId;
  final int quantity;

  OrderItemToppingRequest({
    required this.toppingId,
    this.quantity = 1,
  });

  Map<String, dynamic> toJson() {
    return {
      'toppingId': toppingId,
      'quantity': quantity,
    };
  }
}

class CreateOrderPaymentRequest {
  final int method; // 0 = Cash, 1 = VnPay, 2 = Momo
  final String? transactionReference;
  final String? note;

  CreateOrderPaymentRequest({
    required this.method,
    this.transactionReference,
    this.note,
  });

  Map<String, dynamic> toJson() {
    return {
      'method': method,
      if (transactionReference != null) 'transactionReference': transactionReference,
      if (note != null) 'note': note,
    };
  }
}

class OrderResponse {
  final String id;
  final String orderNumber;

  OrderResponse({
    required this.id,
    required this.orderNumber,
  });

  factory OrderResponse.fromJson(Map<String, dynamic> json) {
    return OrderResponse(
      id: json['id'] as String? ?? '',
      orderNumber: json['orderNumber'] as String? ?? '',
    );
  }
}
