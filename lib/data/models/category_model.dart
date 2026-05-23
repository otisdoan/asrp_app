class CategoryModel {
  final String id;
  final String name;
  final String imageUrl;
  final int? count;

  const CategoryModel({
    required this.id,
    required this.name,
    required this.imageUrl,
    this.count,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      imageUrl: json['imageUrl'] as String? ?? '',
      count: json['count'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'imageUrl': imageUrl,
      if (count != null) 'count': count,
    };
  }
}
