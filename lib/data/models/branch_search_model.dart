class BranchSearchFoodItemModel {
  final String name;
  final String price;
  final String image;

  const BranchSearchFoodItemModel({
    required this.name,
    required this.price,
    required this.image,
  });

  factory BranchSearchFoodItemModel.fromJson(Map<String, dynamic> json) {
    return BranchSearchFoodItemModel(
      name: json['name'] as String? ?? '',
      price: json['price'] as String? ?? '',
      image: json['image'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'price': price,
      'image': image,
    };
  }
}

class BranchSearchResultModel {
  final String id;
  final String name;
  final String imageUrl;
  final double rating;
  final String distance;
  final String deliveryTime;
  final String discount;
  final List<BranchSearchFoodItemModel> foods;

  const BranchSearchResultModel({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.rating,
    required this.distance,
    required this.deliveryTime,
    required this.discount,
    required this.foods,
  });

  factory BranchSearchResultModel.fromJson(Map<String, dynamic> json) {
    var foodsList = json['foods'] as List? ?? [];
    var parsedFoods = foodsList
        .map((item) => BranchSearchFoodItemModel.fromJson(item as Map<String, dynamic>))
        .toList();

    return BranchSearchResultModel(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      imageUrl: json['imageUrl'] as String? ?? '',
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      distance: json['distance'] as String? ?? '',
      deliveryTime: json['deliveryTime'] as String? ?? '',
      discount: json['discount'] as String? ?? '',
      foods: parsedFoods,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'imageUrl': imageUrl,
      'rating': rating,
      'distance': distance,
      'deliveryTime': deliveryTime,
      'discount': discount,
      'foods': foods.map((e) => e.toJson()).toList(),
    };
  }
}
