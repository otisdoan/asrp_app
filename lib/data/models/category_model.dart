class CategoryModel {
  final String id;
  final String name;
  final String? description;
  final String imageUrl;
  final int? displayOrder;
  final int? menuItemCount;

  /// Backward-compatible alias for old mock data and UI code.
  int? get count => menuItemCount;

  const CategoryModel({
    required this.id,
    required this.name,
    this.description,
    required this.imageUrl,
    this.displayOrder,
    this.menuItemCount,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    int? readInt(List<String> keys) {
      for (final key in keys) {
        final value = json[key];
        if (value is int) return value;
        if (value is num) return value.toInt();
        if (value != null) return int.tryParse(value.toString());
      }
      return null;
    }

    return CategoryModel(
      id: json['id']?.toString() ??
          json['categoryId']?.toString() ??
          json['_id']?.toString() ??
          '',
      name: json['name']?.toString() ??
          json['title']?.toString() ??
          json['categoryName']?.toString() ??
          '',
      description: json['description']?.toString(),
      imageUrl: json['imageUrl']?.toString() ??
          json['image']?.toString() ??
          json['thumbnail']?.toString() ??
          '',
      displayOrder: readInt(['displayOrder', 'order', 'sortOrder']),
      menuItemCount: readInt(['menuItemCount', 'count', 'itemsCount']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      if (description != null) 'description': description,
      'imageUrl': imageUrl,
      if (displayOrder != null) 'displayOrder': displayOrder,
      if (menuItemCount != null) 'menuItemCount': menuItemCount,
    };
  }
}
