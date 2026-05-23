import 'menu_item_model.dart';

class BranchListItemModel {
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

  const BranchListItemModel({
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
  });

  factory BranchListItemModel.fromJson(Map<String, dynamic> json) {
    return BranchListItemModel(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      imageUrl: (json['imageUrl'] ?? json['image']) as String? ?? '',
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      distance: json['distance'] as String? ?? '',
      deliveryTime: (json['deliveryTime'] ?? json['time']) as String? ?? '',
      category: json['category'] as String?,
      reviewsCount: json['reviewsCount'] as int? ?? json['reviews'] as int?,
      promo: json['promo'] as String?,
      discount: json['discount'] as String?,
      tag: json['tag'] as String?,
      adLabel: json['adLabel'] as String?,
      isFavorite: json['isFavorite'] as bool?,
      displayOrder: json['displayOrder'] as int?,
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
      if (category != null) 'category': category,
      if (reviewsCount != null) 'reviewsCount': reviewsCount,
      if (promo != null) 'promo': promo,
      if (discount != null) 'discount': discount,
      if (tag != null) 'tag': tag,
      if (adLabel != null) 'adLabel': adLabel,
      if (isFavorite != null) 'isFavorite': isFavorite,
      if (displayOrder != null) 'displayOrder': displayOrder,
    };
  }
}

class BranchMenuSectionModel {
  final String name; // Tên danh mục (ví dụ: "Món phổ biến", "Phở & Bún"...)
  final List<MenuItemModel> items; // Danh sách món ăn thuộc danh mục này

  const BranchMenuSectionModel({
    required this.name,
    required this.items,
  });

  factory BranchMenuSectionModel.fromJson(Map<String, dynamic> json) {
    return BranchMenuSectionModel(
      name: json['name'] as String? ?? '',
      items: (json['items'] as List<dynamic>?)
              ?.map((e) => MenuItemModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'items': items.map((e) => e.toJson()).toList(),
    };
  }
}

class BranchDetailModel {
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
  final List<BranchMenuSectionModel>?
      menu; // Menu động theo từng quán (Gồm Tab Name & Items)

  const BranchDetailModel({
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
  });

  factory BranchDetailModel.fromJson(Map<String, dynamic> json) {
    return BranchDetailModel(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      imageUrl: (json['imageUrl'] ?? json['image']) as String? ?? '',
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      distance: json['distance'] as String? ?? '',
      deliveryTime: (json['deliveryTime'] ?? json['time']) as String? ?? '',
      category: json['category'] as String?,
      reviewsCount: json['reviewsCount'] as int? ?? json['reviews'] as int?,
      isFavorite: json['isFavorite'] as bool?,
      likesCount: json['likesCount'] as int? ?? json['likes'] as int?,
      address: json['address'] as String?,
      description: json['description'] as String?,
      latitude: (json['latitude'] as num?)?.toDouble() ??
          (json['lat'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble() ??
          (json['lng'] as num?)?.toDouble(),
      isActive: json['isActive'] as bool?,
      promos:
          (json['promos'] as List<dynamic>?)?.map((e) => e as String).toList(),
      menu: (json['menu'] as List<dynamic>?)
          ?.map(
              (e) => BranchMenuSectionModel.fromJson(e as Map<String, dynamic>))
          .toList(),
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
      if (category != null) 'category': category,
      if (reviewsCount != null) 'reviewsCount': reviewsCount,
      if (isFavorite != null) 'isFavorite': isFavorite,
      if (likesCount != null) 'likesCount': likesCount,
      if (address != null) 'address': address,
      if (description != null) 'description': description,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      if (isActive != null) 'isActive': isActive,
      if (promos != null) 'promos': promos,
      if (menu != null) 'menu': menu!.map((e) => e.toJson()).toList(),
    };
  }
}
