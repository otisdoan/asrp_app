class PaginatedBranchResponse<T> {
  final List<T> items;
  final int totalCount;
  final int page;
  final int pageSize;
  final int totalPages;

  PaginatedBranchResponse({
    required this.items,
    required this.totalCount,
    required this.page,
    required this.pageSize,
    required this.totalPages,
  });

  factory PaginatedBranchResponse.fromJson(Map<String, dynamic> json, T Function(Map<String, dynamic>) fromJsonT) {
    return PaginatedBranchResponse(
      items: (json['items'] as List<dynamic>?)?.map((e) => fromJsonT(e as Map<String, dynamic>)).toList() ?? [],
      totalCount: json['totalCount'] as int? ?? 0,
      page: json['page'] as int? ?? 1,
      pageSize: json['pageSize'] as int? ?? 20,
      totalPages: json['totalPages'] as int? ?? 1,
    );
  }
}

class BranchSummaryResponse {
  final String id;
  final String name;
  final String imageUrl;
  final double rating;
  final String distance;
  final String deliveryTime;
  final String? category;
  final int? reviewsCount;
  final String? promo;
  final String? discount;
  final String? tag;
  final String? adLabel;
  final bool? isFavorite;
  final int? displayOrder;
  final String? address;
  final String? phone;
  final int? floor;
  final String? openingTime;
  final String? closingTime;
  final bool isActive;
  final double? latitude;
  final double? longitude;
  final String? description;
  final List<String>? promos;
  final int likesCount;
  final double averageRating;
  final int reviewCount;
  final String createdAt;

  BranchSummaryResponse({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.rating,
    required this.distance,
    required this.deliveryTime,
    this.category,
    this.reviewsCount,
    this.promo,
    this.discount,
    this.tag,
    this.adLabel,
    this.isFavorite,
    this.displayOrder,
    this.address,
    this.phone,
    this.floor,
    this.openingTime,
    this.closingTime,
    required this.isActive,
    this.latitude,
    this.longitude,
    this.description,
    this.promos,
    required this.likesCount,
    required this.averageRating,
    required this.reviewCount,
    required this.createdAt,
  });

  factory BranchSummaryResponse.fromJson(Map<String, dynamic> json) {
    return BranchSummaryResponse(
      id: _stringFromJson(json['id']),
      name: _stringFromJson(json['name']),
      imageUrl: _stringFromJson(json['imageUrl']),
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      distance: _stringFromJson(json['distance']),
      deliveryTime: _stringFromJson(json['deliveryTime']),
      category: _nullableStringFromJson(json['category']),
      reviewsCount: json['reviewsCount'] as int?,
      promo: _nullableStringFromJson(json['promo']),
      discount: _nullableStringFromJson(json['discount']),
      tag: _nullableStringFromJson(json['tag']),
      adLabel: _nullableStringFromJson(json['adLabel']),
      isFavorite: json['isFavorite'] as bool?,
      displayOrder: json['displayOrder'] as int?,
      address: _nullableStringFromJson(json['address']),
      phone: _nullableStringFromJson(json['phone']),
      floor: json['floor'] as int?,
      openingTime: _nullableStringFromJson(json['openingTime']),
      closingTime: _nullableStringFromJson(json['closingTime']),
      isActive: json['isActive'] as bool? ?? false,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      description: _nullableStringFromJson(json['description']),
      promos: _stringListFromJson(json['promos']),
      likesCount: json['likesCount'] as int? ?? 0,
      averageRating: (json['averageRating'] as num?)?.toDouble() ?? 0.0,
      reviewCount: json['reviewCount'] as int? ?? 0,
      createdAt: _stringFromJson(json['createdAt']),
    );
  }
}

class BranchDetailResponse {
  final String id;
  final String name;
  final String imageUrl;
  final double rating;
  final String distance;
  final String deliveryTime;
  final String? category;
  final int? reviewsCount;
  final bool? isFavorite;
  final int? likesCount;
  final String? address;
  final String? description;
  final double? latitude;
  final double? longitude;
  final bool? isActive;
  final List<String>? promos;
  final List<BranchMenuItemResponse>? menu;
  final String? phone;
  final int? floor;
  final String? openingTime;
  final String? closingTime;
  final int displayOrder;
  final String? promo;
  final String? discount;
  final String? tag;
  final String? adLabel;
  final double averageRating;
  final int reviewCount;

  BranchDetailResponse({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.rating,
    required this.distance,
    required this.deliveryTime,
    this.category,
    this.reviewsCount,
    this.isFavorite,
    this.likesCount,
    this.address,
    this.description,
    this.latitude,
    this.longitude,
    this.isActive,
    this.promos,
    this.menu,
    this.phone,
    this.floor,
    this.openingTime,
    this.closingTime,
    required this.displayOrder,
    this.promo,
    this.discount,
    this.tag,
    this.adLabel,
    required this.averageRating,
    required this.reviewCount,
  });

  factory BranchDetailResponse.fromJson(Map<String, dynamic> json) {
    return BranchDetailResponse(
      id: _stringFromJson(json['id']),
      name: _stringFromJson(json['name']),
      imageUrl: _stringFromJson(json['imageUrl']),
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      distance: _stringFromJson(json['distance']),
      deliveryTime: _stringFromJson(json['deliveryTime']),
      category: _nullableStringFromJson(json['category']),
      reviewsCount: json['reviewsCount'] as int?,
      isFavorite: json['isFavorite'] as bool?,
      likesCount: json['likesCount'] as int?,
      address: _nullableStringFromJson(json['address']),
      description: _nullableStringFromJson(json['description']),
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      isActive: json['isActive'] as bool?,
      promos: _stringListFromJson(json['promos']),
      menu: (json['menu'] as List<dynamic>?)?.map((e) => BranchMenuItemResponse.fromJson(e as Map<String, dynamic>)).toList(),
      phone: _nullableStringFromJson(json['phone']),
      floor: json['floor'] as int?,
      openingTime: _nullableStringFromJson(json['openingTime']),
      closingTime: _nullableStringFromJson(json['closingTime']),
      displayOrder: json['displayOrder'] as int? ?? 0,
      promo: _nullableStringFromJson(json['promo']),
      discount: _nullableStringFromJson(json['discount']),
      tag: _nullableStringFromJson(json['tag']),
      adLabel: _nullableStringFromJson(json['adLabel']),
      averageRating: (json['averageRating'] as num?)?.toDouble() ?? 0.0,
      reviewCount: json['reviewCount'] as int? ?? 0,
    );
  }
}

class BranchMenuItemResponse {
  final String id;
  final String menuItemId;
  final String? slug;
  final String imageUrl;
  final String name;
  final String? description;
  final String price;
  final double? rating;
  final int? soldCount;
  final int? likesCount;
  final int priceAmount;
  final double basePrice;
  final List<String> galleryImages;
  final bool isAvailable;
  final bool isSoldOut;
  final String categoryId;
  final String categoryName;
  final int reviewCount;
  final String? badgeLabel;
  final String? badgeType;

  BranchMenuItemResponse({
    required this.id,
    required this.menuItemId,
    this.slug,
    required this.imageUrl,
    required this.name,
    this.description,
    required this.price,
    this.rating,
    this.soldCount,
    this.likesCount,
    required this.priceAmount,
    required this.basePrice,
    required this.galleryImages,
    required this.isAvailable,
    required this.isSoldOut,
    required this.categoryId,
    required this.categoryName,
    required this.reviewCount,
    this.badgeLabel,
    this.badgeType,
  });

  factory BranchMenuItemResponse.fromJson(Map<String, dynamic> json) {
    return BranchMenuItemResponse(
      id: json['id']?.toString() ?? '',
      menuItemId: json['menuItemId']?.toString() ?? '',
      slug: json['slug']?.toString(),
      imageUrl: json['imageUrl']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString(),
      price: json['price']?.toString() ?? '',
      rating: (json['rating'] as num?)?.toDouble(),
      soldCount: json['soldCount'] as int?,
      likesCount: json['likesCount'] as int?,
      priceAmount: json['priceAmount'] as int? ?? 0,
      basePrice: (json['basePrice'] as num?)?.toDouble() ?? 0.0,
      galleryImages: (json['galleryImages'] as List<dynamic>?)
              ?.where((e) => e != null)
              .map((e) => e.toString())
              .toList() ??
          [],
      isAvailable: json['isAvailable'] as bool? ?? true,
      isSoldOut: json['isSoldOut'] as bool? ?? false,
      categoryId: json['categoryId']?.toString() ?? '',
      categoryName: json['categoryName']?.toString() ?? '',
      reviewCount: json['reviewCount'] as int? ?? 0,
      badgeLabel: json['badgeLabel']?.toString(),
      badgeType: json['badgeType']?.toString(),
    );
  }
}

String _stringFromJson(Object? value) => value?.toString() ?? '';

String? _nullableStringFromJson(Object? value) => value?.toString();

List<String>? _stringListFromJson(Object? value) {
  if (value is! List) return null;
  return value.where((e) => e != null).map((e) => e.toString()).toList();
}
