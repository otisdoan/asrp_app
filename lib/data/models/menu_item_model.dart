enum BadgeType { hot, newItem, best, sale }

class BadgeModel {
  final String label;
  final BadgeType type;

  const BadgeModel({required this.label, required this.type});
}

class MenuItemModel {
  final String? slug;
  final String imageUrl;
  final String name;
  final String? description;
  final String price;
  final BadgeModel? badge;
  final double? rating;

  const MenuItemModel({
    this.slug,
    this.imageUrl = '',
    required this.name,
    this.description,
    required this.price,
    this.badge,
    this.rating,
  });
}
