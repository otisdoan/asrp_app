class RecommendedCardItemModel {
  final String id;
  final String branchId;
  final String branchName;
  final String dishName;
  final double price;
  final String priceDisplay;
  final String imageUrl;
  final double rating;
  final int reviewsCount;
  final String distance;
  final String deliveryTime;
  final String category;
  final String? recommendationReason;

  const RecommendedCardItemModel({
    required this.id,
    required this.branchId,
    required this.branchName,
    required this.dishName,
    required this.price,
    required this.priceDisplay,
    required this.imageUrl,
    required this.rating,
    required this.reviewsCount,
    required this.distance,
    required this.deliveryTime,
    required this.category,
    this.recommendationReason,
  });

  factory RecommendedCardItemModel.fromJson(Map<String, dynamic> json) {
    final priceVal = (json['price'] as num?)?.toDouble() ??
        double.tryParse(json['price']?.toString() ?? '0') ??
        0.0;
    final priceFormatted = priceVal > 0
        ? '${priceVal.toInt().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')} đ'
        : (json['priceDisplay']?.toString() ?? '45.000 đ');

    return RecommendedCardItemModel(
      id: json['id']?.toString() ?? json['menuItemId']?.toString() ?? '',
      branchId: json['branchId']?.toString() ?? json['storeId']?.toString() ?? 'default_branch',
      branchName: json['branchName']?.toString() ?? json['storeName']?.toString() ?? 'Quán ăn ngon',
      dishName: json['dishName']?.toString() ?? json['name']?.toString() ?? 'Món ăn gợi ý',
      price: priceVal > 0 ? priceVal : 45000,
      priceDisplay: priceFormatted,
      imageUrl: json['imageUrl']?.toString() ?? json['image_url']?.toString() ?? '',
      rating: (json['rating'] as num?)?.toDouble() ?? 4.8,
      reviewsCount: (json['reviewsCount'] as num?)?.toInt() ?? 120,
      distance: json['distance']?.toString() ?? '1.2 km',
      deliveryTime: json['deliveryTime']?.toString() ?? '15-25 phút',
      category: json['category']?.toString() ?? 'Món ăn',
      recommendationReason: json['reason']?.toString() ?? json['recommendationReason']?.toString(),
    );
  }

  RecommendedCardItemModel copyWith({
    String? id,
    String? branchId,
    String? branchName,
    String? dishName,
    double? price,
    String? priceDisplay,
    String? imageUrl,
    double? rating,
    int? reviewsCount,
    String? distance,
    String? deliveryTime,
    String? category,
    String? recommendationReason,
  }) {
    return RecommendedCardItemModel(
      id: id ?? this.id,
      branchId: branchId ?? this.branchId,
      branchName: branchName ?? this.branchName,
      dishName: dishName ?? this.dishName,
      price: price ?? this.price,
      priceDisplay: priceDisplay ?? this.priceDisplay,
      imageUrl: imageUrl ?? this.imageUrl,
      rating: rating ?? this.rating,
      reviewsCount: reviewsCount ?? this.reviewsCount,
      distance: distance ?? this.distance,
      deliveryTime: deliveryTime ?? this.deliveryTime,
      category: category ?? this.category,
      recommendationReason: recommendationReason ?? this.recommendationReason,
    );
  }
}
