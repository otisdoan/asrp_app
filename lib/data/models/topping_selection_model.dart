class ToppingSelectionModel {
  final String toppingId;
  final String name;
  final int price;
  final String? groupId;
  final String? groupName;

  const ToppingSelectionModel({
    required this.toppingId,
    required this.name,
    required this.price,
    this.groupId,
    this.groupName,
  });

  factory ToppingSelectionModel.fromJson(Map<String, dynamic> json) {
    return ToppingSelectionModel(
      toppingId: json['toppingId'] as String? ?? '',
      name: json['name'] as String? ?? '',
      price: json['price'] as int? ?? 0,
      groupId: json['groupId'] as String?,
      groupName: json['groupName'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'toppingId': toppingId,
      'name': name,
      'price': price,
      if (groupId != null) 'groupId': groupId,
      if (groupName != null) 'groupName': groupName,
    };
  }
}
