class ToppingSelectionModel {
  final String toppingId;
  final String name;
  final int price;

  const ToppingSelectionModel({
    required this.toppingId,
    required this.name,
    required this.price,
  });

  factory ToppingSelectionModel.fromJson(Map<String, dynamic> json) {
    return ToppingSelectionModel(
      toppingId: json['toppingId'] as String? ?? '',
      name: json['name'] as String? ?? '',
      price: json['price'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'toppingId': toppingId,
      'name': name,
      'price': price,
    };
  }
}
