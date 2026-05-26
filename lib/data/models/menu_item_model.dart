enum BadgeType { hot, newItem, best, sale }

class BadgeModel {
  final String label;
  final BadgeType type;

  const BadgeModel({required this.label, required this.type});

  factory BadgeModel.fromJson(Map<String, dynamic> json) {
    return BadgeModel(
      label: json['label'] as String? ?? '',
      type: BadgeType.values.firstWhere(
        (e) =>
            e.name == json['type'] ||
            e.toString().split('.').last == json['type'],
        orElse: () => BadgeType.hot,
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'label': label,
      'type': type.name,
    };
  }
}

class MenuItemModel {
  final String? id;
  final String? slug;
  final String? categoryId;
  final String? branchId;
  final String imageUrl;
  final String name;
  final String? description;
  final String price;
  final num? rawPrice;
  final num? rawOriginalPrice;
  final String? originalPrice;
  final BadgeModel? badge;
  final double? rating;
  final int? soldCount;
  final int? likesCount;

  const MenuItemModel({
    this.id,
    this.slug,
    this.categoryId,
    this.branchId,
    this.imageUrl = '',
    required this.name,
    this.description,
    required this.price,
    this.rawPrice,
    this.rawOriginalPrice,
    this.originalPrice,
    this.badge,
    this.rating,
    this.soldCount,
    this.likesCount,
  });

  static String _formatPrice(num value) {
    final normalized = value.toStringAsFixed(value is int ? 0 : 2);
    final parts = normalized.split('.');
    final integerPart = parts.first;
    final fractionPart = parts.length > 1 ? parts.last : '';
    final formattedInteger = integerPart.replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (match) => '${match[1]}.',
    );
    if (fractionPart.isEmpty || fractionPart == '00') {
      return '$formattedIntegerđ';
    }
    return '$formattedInteger,$fractionPartđ';
  }

  factory MenuItemModel.fromJson(Map<String, dynamic> json) {
    final parsedRawPrice = json['rawPrice'] as num? ?? json['price'] as num?;
    final parsedRawOriginalPrice =
        json['rawOriginalPrice'] as num? ?? json['originalPrice'] as num?;
    final parsedPriceText = json['price'];
    return MenuItemModel(
      id: json['id']?.toString(),
      slug: json['slug'] as String?,
      categoryId: json['categoryId']?.toString(),
      branchId: json['branchId']?.toString(),
      imageUrl: (json['imageUrl'] ?? json['image']) as String? ?? '',
      name: json['name'] as String? ?? '',
      description: json['description'] as String?,
      price: parsedRawPrice != null
          ? _formatPrice(parsedRawPrice)
          : parsedPriceText?.toString() ?? '',
      rawPrice: parsedRawPrice,
      rawOriginalPrice: parsedRawOriginalPrice,
      originalPrice: json['originalPrice']?.toString(),
      badge: json['badge'] != null
          ? BadgeModel.fromJson(json['badge'] as Map<String, dynamic>)
          : null,
      rating: (json['rating'] as num?)?.toDouble(),
      soldCount: json['soldCount'] as int? ?? json['sold'] as int?,
      likesCount: json['likesCount'] as int? ?? json['likes'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      if (slug != null) 'slug': slug,
      if (categoryId != null) 'categoryId': categoryId,
      if (branchId != null) 'branchId': branchId,
      'imageUrl': imageUrl,
      'name': name,
      if (description != null) 'description': description,
      'price': price,
      if (rawPrice != null) 'rawPrice': rawPrice,
      if (rawOriginalPrice != null) 'rawOriginalPrice': rawOriginalPrice,
      if (originalPrice != null) 'originalPrice': originalPrice,
      if (badge != null) 'badge': badge!.toJson(),
      if (rating != null) 'rating': rating,
      if (soldCount != null) 'soldCount': soldCount,
      if (likesCount != null) 'likesCount': likesCount,
    };
  }
}
