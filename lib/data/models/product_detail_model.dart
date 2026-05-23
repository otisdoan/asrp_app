class ProductSizeModel {
  final String label;
  final String description;
  final int price;

  const ProductSizeModel({
    required this.label,
    required this.description,
    required this.price,
  });
}

class ProductToppingModel {
  final String label;
  final int price;

  const ProductToppingModel({required this.label, required this.price});
}

class ProductCustomizationModel {
  final String label;
  final List<String> choices;
  final int defaultIndex;

  const ProductCustomizationModel({
    required this.label,
    required this.choices,
    required this.defaultIndex,
  });
}

class NutritionItemModel {
  final String label;
  final num value;
  final String unit;

  const NutritionItemModel({
    required this.label,
    required this.value,
    required this.unit,
  });
}

class AllergenModel {
  final String icon;
  final String name;

  const AllergenModel({required this.icon, required this.name});
}

class ReviewDistributionModel {
  final int star;
  final int percent;

  const ReviewDistributionModel({required this.star, required this.percent});
}

class ReviewModel {
  final String name;
  final String? membership;
  final int rating;
  final String date;
  final String content;
  final int helpful;
  final String? reply;

  const ReviewModel({
    required this.name,
    this.membership,
    required this.rating,
    required this.date,
    required this.content,
    required this.helpful,
    this.reply,
  });
}

class PairingItemModel {
  final String imageUrl;
  final String name;
  final String price;
  final bool isInCart;

  const PairingItemModel({
    required this.imageUrl,
    required this.name,
    required this.price,
    this.isInCart = false,
  });
}

class ProductBadgeModel {
  final String label;
  final String colorBg; // Hex color string like '#FAECE7'
  final String colorText;

  const ProductBadgeModel({
    required this.label,
    required this.colorBg,
    required this.colorText,
  });
}

class ProductDetailModel {
  final String slug;
  final String imageUrl;
  final String name;
  final String category;
  final int price;
  final int? originalPrice;
  final double rating;
  final int reviewCount;
  final int soldCount;
  final bool isAvailable;
  final List<ProductBadgeModel> badges;
  final List<String> gallery;
  final String shortDescription;
  final String fullDescription;
  final String origin;
  final List<ProductSizeModel> sizes;
  final List<ProductToppingModel> toppings;
  final List<ProductCustomizationModel> customizations;
  final List<NutritionItemModel> nutrition;
  final List<String> dietTags;
  final List<AllergenModel> allergenContains;
  final List<String> allergenDoesNotContain;
  final List<ReviewDistributionModel> reviewDistribution;
  final List<ReviewModel> reviews;
  final List<PairingItemModel> pairings;
  final List<String> similarSlugs;

  const ProductDetailModel({
    required this.slug,
    required this.imageUrl,
    required this.name,
    required this.category,
    required this.price,
    this.originalPrice,
    required this.rating,
    required this.reviewCount,
    required this.soldCount,
    required this.isAvailable,
    required this.badges,
    required this.gallery,
    required this.shortDescription,
    required this.fullDescription,
    required this.origin,
    required this.sizes,
    required this.toppings,
    required this.customizations,
    required this.nutrition,
    required this.dietTags,
    required this.allergenContains,
    required this.allergenDoesNotContain,
    required this.reviewDistribution,
    required this.reviews,
    required this.pairings,
    required this.similarSlugs,
  });
}
