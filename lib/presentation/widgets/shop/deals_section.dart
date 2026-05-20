import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

/// Section "Trùm Deal Ngon" — grid layout: 1 large left card + 2 small right cards.
/// Matches the ShopeeFood-style design reference.
class DealsSection extends StatelessWidget {
  final Function(String) onItemTap;

  const DealsSection({super.key, required this.onItemTap});

  @override
  Widget build(BuildContext context) {
    // Fixed height for the cards area to prevent overflow
    const double smallCardHeight = 105.0;
    const double gap = 10.0;
    const double totalHeight = smallCardHeight * 2 + gap;

    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.secondary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ─── Header ─────────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Flexible(
                child: Text(
                  'TRÙM DEAL NGON BMC PHỞ',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: 0.2,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              GestureDetector(
                onTap: () {},
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Xem thêm',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(width: 2),
                    Icon(Icons.chevron_right, color: Colors.white, size: 18),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // ─── Cards Grid ─────────────────────────────────────
          SizedBox(
            height: totalHeight,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // LEFT — Large vertical card
                Expanded(
                  flex: 5,
                  child: _LargeCard(
                    discount: '-30%',
                    shopName: 'Bánh Mì Khói - 120...',
                    productName: 'BÁNH MÌ ỐP LA',
                    price: '17.500đ',
                    oldPrice: '25.000đ',
                    icon: Icons.lunch_dining,
                    onTap: () => onItemTap('BÁNH MÌ ỐP LA'),
                  ),
                ),
                const SizedBox(width: gap),
                // RIGHT — Two horizontal cards stacked
                Expanded(
                  flex: 6,
                  child: Column(
                    children: [
                      Expanded(
                        child: _SmallCard(
                          discount: '-30%',
                          shopName: 'Nhà Cô Thanh - Bún Thịt Nư...',
                          productName: 'BÚN MẮM NÊM\nDEALNGON',
                          price: '32.900đ',
                          oldPrice: '47.000đ',
                          icon: Icons.ramen_dining,
                          onTap: () => onItemTap('BÚN MẮM NÊM DEALNGON'),
                        ),
                      ),
                      const SizedBox(height: gap),
                      Expanded(
                        child: _SmallCard(
                          discount: '-30%',
                          shopName: 'Quán Ăn Hà Nội Phở - Bánh...',
                          productName: 'BÁNH CUỐN CHẢ\nHÀ NỘI + NƯỚC ĐẬ...',
                          price: '38.500đ',
                          oldPrice: '55.000đ',
                          icon: Icons.set_meal,
                          onTap: () => onItemTap('BÁNH CUỐN CHẢ HÀ NỘI'),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Large Card (left side — image top, info bottom) ───────────────────────
class _LargeCard extends StatelessWidget {
  final String discount;
  final String shopName;
  final String productName;
  final String price;
  final String oldPrice;
  final IconData icon;
  final VoidCallback onTap;

  const _LargeCard({
    required this.discount,
    required this.shopName,
    required this.productName,
    required this.price,
    required this.oldPrice,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0A000000),
              blurRadius: 6,
              offset: Offset(0, 2),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image area
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Container(
                    color: AppColors.bgWarm,
                    child: Icon(icon, size: 48, color: AppColors.textTertiary),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: _DiscountBadge(label: discount),
                  ),
                ],
              ),
            ),
            // Info area
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    shopName,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    productName,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                      height: 1.2,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        price,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          oldPrice,
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w400,
                            color: AppColors.textTertiary,
                            decoration: TextDecoration.lineThrough,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Small Card (right side — image left, info right) ──────────────────────
class _SmallCard extends StatelessWidget {
  final String discount;
  final String shopName;
  final String productName;
  final String price;
  final String oldPrice;
  final IconData icon;
  final VoidCallback onTap;

  const _SmallCard({
    required this.discount,
    required this.shopName,
    required this.productName,
    required this.price,
    required this.oldPrice,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0A000000),
              blurRadius: 6,
              offset: Offset(0, 2),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Image area (square)
            AspectRatio(
              aspectRatio: 1,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Container(
                    color: AppColors.bgWarm,
                    child: Icon(icon, size: 32, color: AppColors.textTertiary),
                  ),
                  Positioned(
                    top: 6,
                    left: 6,
                    child: _DiscountBadge(label: discount, small: true),
                  ),
                ],
              ),
            ),
            // Info area
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      shopName,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      productName,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                        height: 1.2,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          price,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            oldPrice,
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w400,
                              color: AppColors.textTertiary,
                              decoration: TextDecoration.lineThrough,
                            ),
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

// ─── Discount Badge ────────────────────────────────────────────────────────
class _DiscountBadge extends StatelessWidget {
  final String label;
  final bool small;

  const _DiscountBadge({required this.label, this.small = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: small ? 5 : 7,
        vertical: small ? 2 : 3,
      ),
      decoration: BoxDecoration(
        color: AppColors.accent,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: small ? 10 : 12,
          fontWeight: FontWeight.w800,
          color: Colors.white,
        ),
      ),
    );
  }
}
