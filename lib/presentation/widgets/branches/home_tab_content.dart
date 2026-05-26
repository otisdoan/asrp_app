import 'package:flutter/material.dart';
import 'promo_banner_section.dart';
import 'categories_section.dart';
import 'deals_section.dart';
import 'top_stores_section.dart';
import 'nearby_branches_section.dart';
import 'all_branches_section.dart';

class HomeTabContent extends StatelessWidget {
  final void Function(String name) onItemTap;

  const HomeTabContent({
    super.key,
    required this.onItemTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Promo Banner
                const Padding(
                  padding: EdgeInsets.fromLTRB(12, 14, 12, 0),
                  child: PromoBannerSection(),
                ),
                const SizedBox(height: 12),
                // Categories
                const CategoriesSection(),
                const SizedBox(height: 20),
                // Deals / Promotions
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: DealsSection(onItemTap: onItemTap),
                ),
                const SizedBox(height: 20),
                // Top Stores
                const TopStoresSection(),
                const SizedBox(height: 20),
                // Nearby Stores
                const NearbyStoresSection(),
                const SizedBox(height: 20),
                // All Stores
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  child: AllStoresSection(),
                ),
                const SizedBox(height: 100),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
