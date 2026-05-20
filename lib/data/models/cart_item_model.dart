class CartItemModel {
  final String id;
  final String emoji;
  final String name;
  final int priceAmount; // In VND, e.g. 95000
  final String priceDisplay; // e.g. "95,000đ"
  int quantity;
  String? note;

  CartItemModel({
    required this.id,
    required this.emoji,
    required this.name,
    required this.priceAmount,
    required this.priceDisplay,
    this.quantity = 1,
    this.note,
  });

  int get lineTotal => priceAmount * quantity;

  CartItemModel copyWith({
    String? id,
    String? emoji,
    String? name,
    int? priceAmount,
    String? priceDisplay,
    int? quantity,
    String? note,
  }) {
    return CartItemModel(
      id: id ?? this.id,
      emoji: emoji ?? this.emoji,
      name: name ?? this.name,
      priceAmount: priceAmount ?? this.priceAmount,
      priceDisplay: priceDisplay ?? this.priceDisplay,
      quantity: quantity ?? this.quantity,
      note: note ?? this.note,
    );
  }
}
