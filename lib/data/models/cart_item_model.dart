import 'topping_selection_model.dart';

class CartItemModel {
  final String id;
  final String? menuItemId;
  final String? sizeId;
  final String imageUrl;
  final String name;
  final int priceAmount; // In VND, e.g. 95000
  final String priceDisplay; // e.g. "95,000đ"
  int quantity;
  String? note;
  final List<ToppingSelectionModel> selectedToppings;

  CartItemModel({
    required this.id,
    this.menuItemId,
    this.sizeId,
    required this.imageUrl,
    required this.name,
    required this.priceAmount,
    required this.priceDisplay,
    this.quantity = 1,
    this.note,
    this.selectedToppings = const [],
  });

  int get unitTotal {
    final toppingsCost = selectedToppings.fold(0, (sum, t) => sum + t.price);
    return priceAmount + toppingsCost;
  }

  int get lineTotal => unitTotal * quantity;

  CartItemModel copyWith({
    String? id,
    String? menuItemId,
    String? sizeId,
    String? imageUrl,
    String? name,
    int? priceAmount,
    String? priceDisplay,
    int? quantity,
    String? note,
    List<ToppingSelectionModel>? selectedToppings,
  }) {
    return CartItemModel(
      id: id ?? this.id,
      menuItemId: menuItemId ?? this.menuItemId,
      sizeId: sizeId ?? this.sizeId,
      imageUrl: imageUrl ?? this.imageUrl,
      name: name ?? this.name,
      priceAmount: priceAmount ?? this.priceAmount,
      priceDisplay: priceDisplay ?? this.priceDisplay,
      quantity: quantity ?? this.quantity,
      note: note ?? this.note,
      selectedToppings: selectedToppings ?? this.selectedToppings,
    );
  }

  factory CartItemModel.fromJson(Map<String, dynamic> json) {
    return CartItemModel(
      id: json['id'] as String? ?? json['cartItemId'] as String? ?? '',
      menuItemId: json['menuItemId'] as String?,
      sizeId: json['sizeId'] as String?,
      imageUrl: json['imageUrl'] as String? ?? '',
      name: json['name'] as String? ?? '',
      priceAmount: json['priceAmount'] as int? ?? 0,
      priceDisplay: json['priceDisplay'] as String? ?? '',
      quantity: json['quantity'] as int? ?? 1,
      note: json['note'] as String?,
      selectedToppings: (json['selectedToppings'] as List<dynamic>?)
              ?.map((e) => ToppingSelectionModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      if (menuItemId != null) 'menuItemId': menuItemId,
      if (sizeId != null) 'sizeId': sizeId,
      'imageUrl': imageUrl,
      'name': name,
      'priceAmount': priceAmount,
      'priceDisplay': priceDisplay,
      'quantity': quantity,
      if (note != null) 'note': note,
      'selectedToppings': selectedToppings.map((e) => e.toJson()).toList(),
    };
  }
}
