enum BadgeType { hot, newItem, best, sale }

class BadgeModel {
  final String label;
  final BadgeType type;

  const BadgeModel({required this.label, required this.type});

  factory BadgeModel.fromJson(Map<String, dynamic> json) {
    return BadgeModel(
      label: json['label'] as String? ?? '',
      type: BadgeType.values.firstWhere(
        (e) => e.name == json['type'] || e.toString().split('.').last == json['type'],
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
  final String? slug;
  final String imageUrl;
  final String name;
  final String? description;
  final String price;
  final BadgeModel? badge;
  final double? rating;
  final int? soldCount;
  final int? likesCount;

  const MenuItemModel({
    this.slug,
    this.imageUrl = '',
    required this.name,
    this.description,
    required this.price,
    this.badge,
    this.rating,
    this.soldCount,
    this.likesCount,
  });

  factory MenuItemModel.fromJson(Map<String, dynamic> json) {
    BadgeModel? parsedBadge;
    if (json['badge'] != null) {
      parsedBadge = BadgeModel.fromJson(json['badge'] as Map<String, dynamic>);
    } else if (json['badgeLabel'] != null && json['badgeLabel'].toString().isNotEmpty) {
      parsedBadge = BadgeModel(
        label: json['badgeLabel'] as String,
        type: BadgeType.values.firstWhere(
          (e) => e.name == json['badgeType'] || e.toString().split('.').last == json['badgeType'],
          orElse: () => BadgeType.hot,
        ),
      );
    }

    return MenuItemModel(
      slug: json['slug'] as String?,
      imageUrl: (json['imageUrl'] ?? json['image']) as String? ?? '',
      name: json['name'] as String? ?? '',
      description: json['description'] as String?,
      price: json['price']?.toString() ?? '',
      badge: parsedBadge,
      rating: (json['rating'] as num?)?.toDouble(),
      soldCount: json['soldCount'] as int? ?? json['sold'] as int?,
      likesCount: json['likesCount'] as int? ?? json['likes'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (slug != null) 'slug': slug,
      'imageUrl': imageUrl,
      'name': name,
      if (description != null) 'description': description,
      'price': price,
      if (badge != null) 'badge': badge!.toJson(),
      if (rating != null) 'rating': rating,
      if (soldCount != null) 'soldCount': soldCount,
      if (likesCount != null) 'likesCount': likesCount,
    };
  }
}
