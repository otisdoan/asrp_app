import 'package:flutter/material.dart';

import '../../../data/models/branch_model.dart';

class BranchMenuItemViewData {
  final String id;
  final String name;
  final String price;
  final String sold;
  final int likes;
  final IconData icon;
  final String imageUrl;

  const BranchMenuItemViewData({
    required this.id,
    required this.name,
    required this.price,
    required this.sold,
    required this.likes,
    required this.icon,
    required this.imageUrl,
  });
}

class BranchMenuSectionViewData {
  final String name;
  final List<BranchMenuItemViewData> items;

  const BranchMenuSectionViewData({
    required this.name,
    required this.items,
  });
}

class BranchDetailViewData {
  final List<BranchMenuSectionViewData> menuSections;
  final List<String> promos;
  final List<BranchMenuItemViewData> popularItems;

  const BranchDetailViewData({
    required this.menuSections,
    required this.promos,
    required this.popularItems,
  });

  factory BranchDetailViewData.fromBranch(BranchDetailModel branch) {
    final menuSections = branch.menu
            ?.map(
              (section) => BranchMenuSectionViewData(
                name: section.name,
                items: section.items
                    .map(
                      (item) => BranchMenuItemViewData(
                        id: item.slug ?? item.name,
                        name: item.name,
                        price: '${item.price}đ',
                        sold: '${item.soldCount ?? 0}+',
                        likes: item.likesCount ?? 0,
                        icon: Icons.fastfood,
                        imageUrl: item.imageUrl,
                      ),
                    )
                    .toList(),
              ),
            )
            .toList() ??
        const <BranchMenuSectionViewData>[];

    return BranchDetailViewData(
      menuSections: menuSections,
      promos: branch.promos ?? const <String>[],
      popularItems: const <BranchMenuItemViewData>[],
    );
  }
}
