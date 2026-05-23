class ProductToppingModel {
  final String name;
  final int price;

  const ProductToppingModel({required this.name, required this.price});

  factory ProductToppingModel.fromJson(Map<String, dynamic> json) {
    return ProductToppingModel(
      name: (json['name'] ?? json['label']) as String? ?? '',
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

class ProductSizeModel {
  final String name;
  final int price;

  const ProductSizeModel({required this.name, required this.price});

  factory ProductSizeModel.fromJson(Map<String, dynamic> json) {
    return ProductSizeModel(
      name: (json['name'] ?? json['label']) as String? ?? '',
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

class ProductReviewModel {
  final String user;
  final int rating;
  final String date;
  final String content;
  final int imageCount;
  final List<String> tags;
  final String? reply;

  const ProductReviewModel({
    required this.user,
    required this.rating,
    required this.date,
    required this.content,
    required this.imageCount,
    required this.tags,
    this.reply,
  });

  factory ProductReviewModel.fromJson(Map<String, dynamic> json) {
    return ProductReviewModel(
      user: (json['user'] ?? json['name']) as String? ?? '',
      rating: json['rating'] as int? ?? 5,
      date: json['date'] as String? ?? '',
      content: json['content'] as String? ?? '',
      imageCount: (json['imageCount'] ?? json['helpful'] ?? 0) as int,
      tags:
          (json['tags'] as List<dynamic>?)?.map((e) => e as String).toList() ??
              [],
      reply: json['reply'] as String?,
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

class ProductDetailModel {
  final String? slug;
  final String name;
  final String imageUrl;
  final String priceDisplay;
  final int priceAmount;
  final String? description;
  final String soldCount;
  final int likesCount;
  final List<ProductToppingModel> toppings;
  final List<ProductSizeModel> sizes;
  final List<ProductReviewModel> reviews;

  const ProductDetailModel({
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

  factory ProductDetailModel.fromJson(Map<String, dynamic> json) {
    return ProductDetailModel(
      slug: json['slug'] as String?,
      name: json['name'] as String? ?? '',
      imageUrl: (json['imageUrl'] ?? json['image']) as String? ?? '',
      priceDisplay: (json['priceDisplay'] ?? json['price'])?.toString() ?? '',
      priceAmount: (json['priceAmount'] ?? json['price']) as int? ?? 0,
      description: json['description'] as String?,
      soldCount: (json['soldCountText'] ?? json['sold'])?.toString() ?? '',
      likesCount: json['likesCount'] as int? ?? json['likes'] as int? ?? 0,
      toppings: (json['toppings'] as List<dynamic>?)
              ?.map((e) =>
                  ProductToppingModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      sizes: (json['sizes'] as List<dynamic>?)
              ?.map((e) => ProductSizeModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      reviews: (json['reviews'] as List<dynamic>?)
              ?.map(
                  (e) => ProductReviewModel.fromJson(e as Map<String, dynamic>))
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
