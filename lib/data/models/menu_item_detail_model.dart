class MenuItemToppingModel {
  final String name;
  final int price;

  const MenuItemToppingModel({required this.name, required this.price});

  factory MenuItemToppingModel.fromJson(Map<String, dynamic> json) {
    return MenuItemToppingModel(
      name: _stringFromJson(json['name'] ?? json['label']),
      price: json['price'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'price': price,
    };
  }
}

class MenuItemSizeModel {
  final String name;
  final int price;

  const MenuItemSizeModel({required this.name, required this.price});

  factory MenuItemSizeModel.fromJson(Map<String, dynamic> json) {
    return MenuItemSizeModel(
      name: _stringFromJson(json['name'] ?? json['label']),
      price: json['price'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'price': price,
    };
  }
}

class MenuItemReviewModel {
  final String user;
  final int rating;
  final String date;
  final String content;
  final int imageCount;
  final List<String> tags;
  final String? reply;

  const MenuItemReviewModel({
    required this.user,
    required this.rating,
    required this.date,
    required this.content,
    required this.imageCount,
    required this.tags,
    this.reply,
  });

  factory MenuItemReviewModel.fromJson(Map<String, dynamic> json) {
    return MenuItemReviewModel(
      user: _stringFromJson(json['user'] ?? json['name']),
      rating: json['rating'] as int? ?? 5,
      date: _stringFromJson(json['date']),
      content: _stringFromJson(json['content']),
      imageCount: (json['imageCount'] ?? json['helpful'] ?? 0) as int,
      tags: _stringListFromJson(json['tags']),
      reply: _nullableStringFromJson(json['reply']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user': user,
      'rating': rating,
      'date': date,
      'content': content,
      'imageCount': imageCount,
      'tags': tags,
      if (reply != null) 'reply': reply,
    };
  }
}

class MenuItemDetailModel {
  final String? slug;
  final String name;
  final String imageUrl;
  final String priceDisplay;
  final int priceAmount;
  final String? description;
  final String soldCount;
  final int likesCount;
  final List<MenuItemToppingModel> toppings;
  final List<MenuItemSizeModel> sizes;
  final List<MenuItemReviewModel> reviews;

  const MenuItemDetailModel({
    this.slug,
    required this.name,
    required this.imageUrl,
    required this.priceDisplay,
    required this.priceAmount,
    this.description,
    required this.soldCount,
    required this.likesCount,
    this.toppings = const [],
    this.sizes = const [],
    this.reviews = const [],
  });

  factory MenuItemDetailModel.fromJson(Map<String, dynamic> json) {
    return MenuItemDetailModel(
      slug: _nullableStringFromJson(json['slug']),
      name: _stringFromJson(json['name']),
      imageUrl: _stringFromJson(json['imageUrl'] ?? json['image']),
      priceDisplay: (json['priceDisplay'] ?? json['price'])?.toString() ?? '',
      priceAmount: _intFromJson(json['priceAmount'] ?? json['price']),
      description: _nullableStringFromJson(json['description']),
      soldCount: (json['soldCountText'] ?? json['sold'])?.toString() ?? '',
      likesCount: json['likesCount'] as int? ?? json['likes'] as int? ?? 0,
      toppings: (json['toppings'] as List<dynamic>?)
              ?.map((e) =>
                  MenuItemToppingModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      sizes: (json['sizes'] as List<dynamic>?)
              ?.map((e) => MenuItemSizeModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      reviews: (json['reviews'] as List<dynamic>?)
              ?.map(
                  (e) => MenuItemReviewModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (slug != null) 'slug': slug,
      'name': name,
      'imageUrl': imageUrl,
      'priceDisplay': priceDisplay,
      'priceAmount': priceAmount,
      if (description != null) 'description': description,
      'soldCountText': soldCount,
      'likesCount': likesCount,
      'toppings': toppings.map((e) => e.toJson()).toList(),
      'sizes': sizes.map((e) => e.toJson()).toList(),
      'reviews': reviews.map((e) => e.toJson()).toList(),
    };
  }
}

String _stringFromJson(Object? value) => value?.toString() ?? '';

String? _nullableStringFromJson(Object? value) => value?.toString();

List<String> _stringListFromJson(Object? value) {
  if (value is! List) return const [];
  return value.where((e) => e != null).map((e) => e.toString()).toList();
}

int _intFromJson(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString().replaceAll(RegExp(r'[^0-9]'), '') ?? '') ??
      0;
}
