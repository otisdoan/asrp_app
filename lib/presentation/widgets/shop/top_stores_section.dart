import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../pages/shop/store_detail_page.dart';

/// Section "Top quán đỉnh trên 4.5" — horizontal scroll of store cards.
/// Inspired by GrabFood/ShopeeFood store listing design.
class TopStoresSection extends StatelessWidget {
  const TopStoresSection({super.key});

  static const _stores = [
    {
      'name': 'Tiệm Trà Mơ - 52 Nguyễn Huệ',
      'tag': 'Quán Ngon',
      'rating': 4.8,
      'distance': '1.2 km',
      'time': '30 phút',
      'promo': 'Giảm 10.000đ · Giảm 8...',
      'discount': '56K',
      'image': 'assets/images/tra_sua.jpg',
      'adLabel': 'Quảng cáo',
    },
    {
      'name': 'Jollibee - Trần Hưng Đạo',
      'tag': '',
      'rating': 4.6,
      'distance': '4.6 km',
      'time': '34 phút trở lên',
      'promo': 'Giảm 10.000đ · Giảm 1...',
      'discount': '',
      'image': 'assets/images/com.webp',
      'adLabel': '',
    },
    {
      'name': 'Trà Sữa Happy Tea',
      'tag': '',
      'rating': 4.7,
      'distance': '2.1 km',
      'time': '27 phút',
      'promo': 'Giảm 11.000đ',
      'discount': '56K',
      'image': 'assets/images/tra_sua.jpg',
      'adLabel': 'Quảng cáo',
    },
    {
      'name': 'Phở Hà Nội - Lý Tự Trọng',
      'tag': 'Yêu thích',
      'rating': 4.9,
      'distance': '0.8 km',
      'time': '20 phút',
      'promo': 'Giảm 15.000đ · Freeship',
      'discount': '30K',
      'image': 'assets/images/pho.jpg',
      'adLabel': '',
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
              const Text('', style: TextStyle(fontSize: 20)),
              const SizedBox(width: 6),
              const Expanded(
                child: Text(
                  'Top quán đỉnh trên 4.5',
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
          height: 230,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: _stores.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final store = _stores[index];
              return _StoreCard(
                name: store['name'] as String,
                tag: store['tag'] as String,
                rating: store['rating'] as double,
                distance: store['distance'] as String,
                time: store['time'] as String,
                promo: store['promo'] as String,
                discount: store['discount'] as String,
                image: store['image'] as String,
                adLabel: store['adLabel'] as String,
              );
            },
          ),
        ),
      ],
    );
  }
}

class _StoreCard extends StatelessWidget {
  final String name;
  final String tag;
  final double rating;
  final String distance;
  final String time;
  final String promo;
  final String discount;
  final String image;
  final String adLabel;

  const _StoreCard({
    required this.name,
    required this.tag,
    required this.rating,
    required this.distance,
    required this.time,
    required this.promo,
    required this.discount,
    required this.image,
    required this.adLabel,
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
            icon: Icons.store,
          ),
        ));
      },
      child: Container(
        width: 160,
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
          Stack(
            children: [
              Container(
                height: 110,
                width: double.infinity,
                color: AppColors.bgWarm,
                child: Image.asset(image, fit: BoxFit.cover, width: double.infinity, height: 110),
              ),
              // Tag badge (top-left)
              if (tag.isNotEmpty)
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.success,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      tag,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              // Discount badge (bottom-right)
              if (discount.isNotEmpty)
                Positioned(
                  bottom: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Ưu đãi\n',
                          style: TextStyle(fontSize: 8, color: Colors.white, height: 1),
                        ),
                        Text(
                          discount,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          // Info area
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Promo line
                  if (promo.isNotEmpty)
                    Row(
                      children: [
                        const Icon(Icons.local_offer, size: 12, color: AppColors.primary),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            promo,
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                              color: AppColors.primary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  const SizedBox(height: 4),
                  // Store name
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                      height: 1.2,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const Spacer(),
                  // Bottom info: ad label · time · distance
                  Row(
                    children: [
                      if (adLabel.isNotEmpty) ...[
                        Text(
                          adLabel,
                          style: const TextStyle(
                            fontSize: 10,
                            color: AppColors.textTertiary,
                          ),
                        ),
                        const Text(' · ', style: TextStyle(fontSize: 10, color: AppColors.textTertiary)),
                      ],
                      Flexible(
                        child: Text(
                          '$time · $distance',
                          style: const TextStyle(
                            fontSize: 10,
                            color: AppColors.textSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
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
