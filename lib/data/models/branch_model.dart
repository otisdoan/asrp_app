import 'menu_item_model.dart';

String? _readString(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    final value = json[key];
    if (value != null) {
      return value.toString();
    }
  }
  return null;
}

double? _readDouble(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    final value = json[key];
    if (value is num) {
      return value.toDouble();
    }
    if (value != null) {
      return double.tryParse(value.toString());
    }
  }
  return null;
}

int? _readInt(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    final value = json[key];
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    if (value != null) {
      return int.tryParse(value.toString());
    }
  }
  return null;
}

bool? _readBool(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    final value = json[key];
    if (value is bool) {
      return value;
    }
    if (value is num) {
      return value != 0;
    }
    if (value != null) {
      final normalized = value.toString().toLowerCase();
      if (normalized == 'true' || normalized == '1') {
        return true;
      }
      if (normalized == 'false' || normalized == '0') {
        return false;
      }
    }
  }
  return null;
}

class BranchListItemModel {
  final String id;
  final String? branchId;
  final String name;
  final String imageUrl;
  final double rating;
  final String distance;
  final String deliveryTime;
  final String? address;
  final bool? isActive;
  final double? latitude;
  final double? longitude;
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
    this.branchId,
    required this.name,
    required this.imageUrl,
    required this.rating,
    required this.distance,
    required this.deliveryTime,
    this.address,
    this.isActive,
    this.latitude,
    this.longitude,
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
    print('[Audit Branch] 4. Đang parse Model cho: ${json['name']}');
    final resolvedId = _readString(json, ['id', 'branchId', 'branch_id']) ?? '';
    return BranchListItemModel(
      id: resolvedId,
      branchId: _readString(json, ['branchId', 'branch_id']) ?? resolvedId,
      name: _readString(json, ['name', 'branchName']) ?? '',
      imageUrl:
          _readString(json, ['imageUrl', 'image', 'thumbnail', 'coverImage']) ??
              '',
      rating: _readDouble(json, ['rating']) ?? 0.0,
      distance: _readString(json, ['distance']) ?? '',
      deliveryTime:
          _readString(json, ['deliveryTime', 'time', 'delivery_time']) ?? '',
      address: _readString(json, ['address', 'branchAddress']),
      isActive: _readBool(json, ['isActive', 'active']),
      latitude: _readDouble(json, ['latitude', 'lat']),
      longitude: _readDouble(json, ['longitude', 'lng']),
      category: _readString(json, ['category']),
      reviewsCount: _readInt(json, ['reviewsCount', 'reviews']),
      promo: _readString(json, ['promo']),
      discount: _readString(json, ['discount']),
      tag: _readString(json, ['tag']),
      adLabel: _readString(json, ['adLabel']),
      isFavorite: _readBool(json, ['isFavorite']),
      displayOrder: _readInt(json, ['displayOrder']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      if (branchId != null) 'branchId': branchId,
      'name': name,
      'imageUrl': imageUrl,
      'rating': rating,
      'distance': distance,
      'deliveryTime': deliveryTime,
      if (address != null) 'address': address,
      if (isActive != null) 'isActive': isActive,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
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
  final String? branchId;
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
    this.branchId,
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
    final resolvedId = _readString(json, ['id', 'branchId', 'branch_id']) ?? '';
    return BranchDetailModel(
      id: resolvedId,
      branchId: _readString(json, ['branchId', 'branch_id']) ?? resolvedId,
      name: _readString(json, ['name', 'branchName']) ?? '',
      imageUrl:
          _readString(json, ['imageUrl', 'image', 'thumbnail', 'coverImage']) ??
              '',
      rating: _readDouble(json, ['rating']) ?? 0.0,
      distance: _readString(json, ['distance']) ?? '',
      deliveryTime:
          _readString(json, ['deliveryTime', 'time', 'delivery_time']) ?? '',
      category: _readString(json, ['category']),
      reviewsCount: _readInt(json, ['reviewsCount', 'reviews']),
      isFavorite: _readBool(json, ['isFavorite']),
      likesCount: _readInt(json, ['likesCount', 'likes']),
      address: _readString(json, ['address', 'branchAddress']),
      description: _readString(json, ['description']),
      latitude: _readDouble(json, ['latitude', 'lat']),
      longitude: _readDouble(json, ['longitude', 'lng']),
      isActive: _readBool(json, ['isActive', 'active']),
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
      if (branchId != null) 'branchId': branchId,
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
