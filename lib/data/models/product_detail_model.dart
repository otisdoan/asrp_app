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

class ReviewUserModel {
  final String name;
  final String? avatar;

  const ReviewUserModel({
    required this.name,
    this.avatar,
  });

  factory ReviewUserModel.fromJson(Map<String, dynamic> json) {
    return ReviewUserModel(
      name: (json['name'] ?? json['username'] ?? '') as String? ?? '',
      avatar: json['avatar'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      if (avatar != null) 'avatar': avatar,
    };
  }
}

class ProductReviewModel {
  final ReviewUserModel user;
  final int rating;
  final String date;
  final String content;
  final List<String> images;
  final String? reply;
  final int likes;

  const ProductReviewModel({
    required this.user,
    required this.rating,
    required this.date,
    required this.content,
    required this.images,
    this.reply,
    this.likes = 0,
  });

  int get imageCount => images.length;

  factory ProductReviewModel.fromJson(Map<String, dynamic> json) {
    final userVal = json['user'];
    final ReviewUserModel parsedUser;
    if (userVal is Map<String, dynamic>) {
      parsedUser = ReviewUserModel.fromJson(userVal);
    } else {
      parsedUser = ReviewUserModel(
        name: (userVal ?? json['userName'] ?? json['name']) as String? ?? '',
        avatar: json['userAvatar'] as String?,
      );
    }

    final imagesList = (json['images'] as List<dynamic>?)?.map((e) => e as String).toList() ??
        (json['image'] is List
            ? (json['image'] as List).map((e) => e as String).toList()
            : []);

    return ProductReviewModel(
      user: parsedUser,
      rating: json['rating'] as int? ?? 5,
      date: json['date'] as String? ?? '',
      content: json['content'] as String? ?? '',
      images: imagesList,
      reply: json['reply'] as String?,
      likes: json['likes'] as int? ?? json['helpful'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user': user.toJson(),
      'rating': rating,
      'date': date,
      'content': content,
      'images': images,
      if (reply != null) 'reply': reply,
      'likes': likes,
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
