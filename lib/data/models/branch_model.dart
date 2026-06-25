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
  final double? latitude;
  final double? longitude;

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
    this.latitude,
    this.longitude,
  });

  factory BranchListItemModel.fromJson(Map<String, dynamic> json) {
    String? rawDiscount = json['discount'] as String?;
    String? formattedDiscount;
    if (rawDiscount != null && rawDiscount.isNotEmpty) {
      final parsedDouble = double.tryParse(rawDiscount);
      if (parsedDouble != null) {
        if (parsedDouble >= 1000) {
          final kValue = parsedDouble / 1000;
          if (kValue == kValue.roundToDouble()) {
            formattedDiscount = '${kValue.toInt()}K';
          } else {
            formattedDiscount = '${kValue.toStringAsFixed(1).replaceAll('.0', '')}K';
          }
        } else {
          formattedDiscount = parsedDouble.toInt().toString();
        }
      } else {
        formattedDiscount = rawDiscount;
      }
    }

    // Lấy phần tử đầu tiên trong promos để làm tag giảm giá chính
    String? mergedPromo = json['promo'] as String?;
    if (json['promos'] is List) {
      final promosList = (json['promos'] as List).map((e) => e.toString()).where((e) => e.isNotEmpty).toList();
      if (promosList.isNotEmpty) {
        mergedPromo = promosList.first;
      }
    }
    if (mergedPromo != null && mergedPromo.contains(' · ')) {
      mergedPromo = mergedPromo.split(' · ').first;
    }

    return BranchListItemModel(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      imageUrl: (json['imageUrl'] ?? json['image']) as String? ?? '',
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      distance: json['distance'] as String? ?? '',
      deliveryTime: (json['deliveryTime'] ?? json['time']) as String? ?? '',
      category: json['category'] as String?,
      reviewsCount: json['reviewsCount'] as int? ?? json['reviews'] as int?,
      promo: mergedPromo,
      discount: formattedDiscount,
      tag: json['tag'] as String?,
      adLabel: json['adLabel'] as String?,
      isFavorite: json['isFavorite'] as bool?,
      displayOrder: json['displayOrder'] as int?,
      latitude: (json['latitude'] as num?)?.toDouble() ?? (json['lat'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble() ?? (json['lng'] as num?)?.toDouble(),
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
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
    };
  }
}

class BranchMenuSectionModel {
  final String name; // Tên danh mục (ví dụ: "Món phổ biến", "Phở & bún"...)
  final List<MenuItemModel> items; // Danh sách món ăn thuộc danh mục này

  const BranchMenuSectionModel({
    required this.name,
    required this.items,
  });

  factory BranchMenuSectionModel.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'] ?? json['menuItems'];
    return BranchMenuSectionModel(
      name: (json['categoryName'] ?? json['name']) as String? ?? '',
      items: (rawItems as List<dynamic>?)
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
  final String? phone;
  final String? openingTime;
  final String? closingTime;
  final String? coverImageUrl;
  final String? status;
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
    this.phone,
    this.openingTime,
    this.closingTime,
    this.coverImageUrl,
    this.status,
    this.promos,
    this.menu,
  });

  factory BranchDetailModel.fromJson(Map<String, dynamic> json) {
    final List<dynamic>? rawMenu = json['menu'] as List<dynamic>?;
    List<BranchMenuSectionModel>? groupedMenu;

    if (rawMenu != null) {
      final Map<String, List<MenuItemModel>> categoryGroups = {};
      
      for (final item in rawMenu) {
        if (item is Map<String, dynamic>) {
          if (item['items'] is List && (item['name'] != null || item['categoryName'] != null)) {
            groupedMenu ??= [];
            groupedMenu.add(BranchMenuSectionModel.fromJson(item));
            continue;
          }
          
          final menuItem = MenuItemModel.fromJson(item);
          final categoryName = item['categoryName'] as String? ?? item['category'] as String? ?? 'Khác';
          
          categoryGroups.putIfAbsent(categoryName, () => []).add(menuItem);
        }
      }
      
      if (categoryGroups.isNotEmpty) {
        groupedMenu ??= [];
        categoryGroups.forEach((catName, items) {
          groupedMenu!.add(BranchMenuSectionModel(
            name: catName,
            items: items,
          ));
        });
      }
    }

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
      phone: json['phone'] as String?,
      openingTime: _formatTime(json['openingTime']),
      closingTime: _formatTime(json['closingTime']),
      coverImageUrl: json['coverImageUrl'] as String?,
      status: json['status'] as String?,
      promos:
          (json['promos'] as List<dynamic>?)?.map((e) => e as String).toList(),
      menu: groupedMenu,
    );
  }

  static String? _formatTime(dynamic timeVal) {
    if (timeVal == null) return null;
    final str = timeVal.toString().trim();
    if (str.isEmpty) return null;
    if (str.length >= 5) {
      return str.substring(0, 5);
    }
    return str;
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
      if (phone != null) 'phone': phone,
      if (openingTime != null) 'openingTime': openingTime,
      if (closingTime != null) 'closingTime': closingTime,
      if (coverImageUrl != null) 'coverImageUrl': coverImageUrl,
      if (status != null) 'status': status,
      if (promos != null) 'promos': promos,
      if (menu != null) 'menu': menu!.map((e) => e.toJson()).toList(),
    };
  }

  BranchDetailModel copyWith({
    String? id,
    String? name,
    String? imageUrl,
    double? rating,
    String? distance,
    String? deliveryTime,
    String? category,
    int? reviewsCount,
    bool? isFavorite,
    int? likesCount,
    String? address,
    String? description,
    double? latitude,
    double? longitude,
    bool? isActive,
    String? phone,
    String? openingTime,
    String? closingTime,
    String? coverImageUrl,
    String? status,
    List<String>? promos,
    List<BranchMenuSectionModel>? menu,
  }) {
    return BranchDetailModel(
      id: id ?? this.id,
      name: name ?? this.name,
      imageUrl: imageUrl ?? this.imageUrl,
      rating: rating ?? this.rating,
      distance: distance ?? this.distance,
      deliveryTime: deliveryTime ?? this.deliveryTime,
      category: category ?? this.category,
      reviewsCount: reviewsCount ?? this.reviewsCount,
      isFavorite: isFavorite ?? this.isFavorite,
      likesCount: likesCount ?? this.likesCount,
      address: address ?? this.address,
      description: description ?? this.description,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      isActive: isActive ?? this.isActive,
      phone: phone ?? this.phone,
      openingTime: openingTime ?? this.openingTime,
      closingTime: closingTime ?? this.closingTime,
      coverImageUrl: coverImageUrl ?? this.coverImageUrl,
      status: status ?? this.status,
      promos: promos ?? this.promos,
      menu: menu ?? this.menu,
    );
  }
}
