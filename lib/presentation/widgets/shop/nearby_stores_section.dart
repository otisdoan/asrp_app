import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../pages/shop/store_detail_page.dart';

/// Section "Gần bạn" — horizontal scroll of nearby store cards.
class NearbyStoresSection extends StatelessWidget {
  const NearbyStoresSection({super.key});

  static const _stores = [
    {
      'name': 'Cơm Tấm Bụi Sài Gòn',
      'rating': 4.5,
      'distance': '0.3 km',
      'time': '15 phút',
      'promo': 'Freeship',
      'icon': Icons.rice_bowl,
    },
    {
      'name': 'Bún Đậu Mắm Tôm Hà Nội',
      'rating': 4.3,
      'distance': '0.5 km',
      'time': '18 phút',
      'promo': 'Giảm 20%',
      'icon': Icons.set_meal,
    },
    {
      'name': 'Trà Sữa ToCoToCo',
      'rating': 4.6,
      'distance': '0.7 km',
      'time': '20 phút',
      'promo': 'Mua 1 tặng 1',
      'icon': Icons.local_drink,
    },
    {
      'name': 'Pizza Hut - Nguyễn Trãi',
      'rating': 4.4,
      'distance': '1.0 km',
      'time': '25 phút',
      'promo': 'Giảm 50K',
      'icon': Icons.local_pizza,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: [
              const Text('', style: TextStyle(fontSize: 18)),
              const SizedBox(width: 6),
              const Expanded(
                child: Text(
                  'Gần bạn',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              GestureDetector(
                onTap: () {},
                child: const Text(
                  'Xem thêm',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        // Store cards
        SizedBox(
          height: 200,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: _stores.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final store = _stores[index];
              return _NearbyStoreCard(
                name: store['name'] as String,
                rating: store['rating'] as double,
                distance: store['distance'] as String,
                time: store['time'] as String,
                promo: store['promo'] as String,
                icon: store['icon'] as IconData,
              );
            },
          ),
        ),
      ],
    );
  }
}

class _NearbyStoreCard extends StatelessWidget {
  final String name;
  final double rating;
  final String distance;
  final String time;
  final String promo;
  final IconData icon;

  const _NearbyStoreCard({
    required this.name,
    required this.rating,
    required this.distance,
    required this.time,
    required this.promo,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(
          builder: (_) => StoreDetailPage(
            storeName: name,
            category: 'Đồ ăn · Đồ uống',
            rating: rating,
            reviews: 100,
            deliveryTime: time,
            distance: distance,
            icon: icon,
          ),
        ));
      },
      child: Container(
        width: 150,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0F000000),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image area
          Container(
            height: 95,
            width: double.infinity,
            color: AppColors.bgSoft,
            child: Icon(icon, size: 40, color: AppColors.textTertiary),
          ),
          // Info area
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Store name
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                      height: 1.2,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const Spacer(),
                  // Rating + distance
                  Row(
                    children: [
                      const Icon(Icons.star, size: 12, color: AppColors.star),
                      const SizedBox(width: 2),
                      Text(
                        rating.toString(),
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const Text(' · ', style: TextStyle(fontSize: 11, color: AppColors.textTertiary)),
                      Flexible(
                        child: Text(
                          '$time · $distance',
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  // Promo
                  if (promo.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.badgeHotBg,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        promo,
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: AppColors.badgeHotText,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
      ),
    );
  }
}
