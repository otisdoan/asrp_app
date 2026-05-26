import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/branch_model.dart';
import '../../../data/models/menu_item_model.dart';
import '../../../providers/branches/branch_provider.dart';

final _topSoldDealsProvider = FutureProvider<List<_DealItem>>((ref) async {
  final branches = await ref.watch(branchListProvider.future);
  final repository = ref.read(branchRepositoryProvider);

  final branchDetails = await Future.wait(
    branches.map((branch) async {
      try {
        return await repository.getBranchDetail(branch.id);
      } catch (_) {
        return null;
      }
    }),
  );

  final deals = <_DealItem>[];
  for (final branch in branchDetails.whereType<BranchDetailModel>()) {
    for (final section in branch.menu ?? const <BranchMenuSectionModel>[]) {
      for (final item in section.items) {
        deals.add(_DealItem.fromMenuItem(branch.name, item));
      }
    }
  }

  deals.sort((a, b) => b.soldCount.compareTo(a.soldCount));
  return deals.take(3).toList();
});

class _DealItem {
  final String shopName;
  final String menuItemName;
  final String price;
  final String oldPrice;
  final String discount;
  final String imagePath;
  final int soldCount;

  const _DealItem({
    required this.shopName,
    required this.menuItemName,
    required this.price,
    required this.oldPrice,
    required this.discount,
    required this.imagePath,
    required this.soldCount,
  });

  factory _DealItem.fromMenuItem(String shopName, MenuItemModel item) {
    final price = _safeString(item.price);

    return _DealItem(
      shopName: _safeString(shopName),
      menuItemName: _safeString(item.name),
      price: _formatPrice(price),
      oldPrice: _oldPriceFromDiscount(price, item.badge?.label),
      discount: _normalizeDiscount(item.badge?.label),
      imagePath: _safeString(item.imageUrl),
      soldCount: item.soldCount ?? 0,
    );
  }
}

String _safeString(Object? value) => value?.toString() ?? '';

String _normalizeDiscount(String? value) {
  final label = value?.trim() ?? '';
  if (label.isEmpty) return '';

  final percentMatch = RegExp(r'(\d+(?:[.,]\d+)?)%').firstMatch(label);
  if (percentMatch != null) {
    return '-${percentMatch.group(1)!.replaceAll(',', '.')}%';
  }

  return label;
}

String _oldPriceFromDiscount(String price, String? discountLabel) {
  final percentMatch = RegExp(r'(\d+(?:[.,]\d+)?)%').firstMatch(
    discountLabel ?? '',
  );
  if (percentMatch == null) return '';

  final percent = double.tryParse(
    percentMatch.group(1)!.replaceAll(',', '.'),
  );
  final currentPrice = _priceAmount(price);
  if (percent == null || percent <= 0 || percent >= 100 || currentPrice <= 0) {
    return '';
  }

  final oldPrice = currentPrice / (1 - percent / 100);
  return _formatPrice(oldPrice.round().toString());
}

int _priceAmount(String value) {
  return int.tryParse(value.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
}

String _formatPrice(String value) {
  final trimmed = value.trim();
  if (trimmed.isEmpty) return '';
  if (trimmed.contains('đ')) return trimmed;

  final amount = int.tryParse(trimmed.replaceAll(RegExp(r'[^0-9]'), ''));
  if (amount == null) return trimmed;

  final formatted = amount.toString().replaceAllMapped(
        RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
        (match) => '${match[1]}.',
      );
  return '${formatted}đ';
}

/// Section "Trùm Deal Ngon" — grid layout: 1 large left card + 2 small right cards.
/// Matches the ShopeeFood-style design reference.
class DealsSection extends ConsumerWidget {
  final Function(String) onItemTap;

  const DealsSection({super.key, required this.onItemTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final topDeals = ref.watch(_topSoldDealsProvider);

    return topDeals.when(
      data: (deals) {
        if (deals.length < 3) {
          return const SizedBox.shrink();
        }
        return _DealsContent(deals: deals, onItemTap: onItemTap);
      },
      loading: () => const SizedBox.shrink(),
      error: (e, st) => const SizedBox.shrink(),
    );
  }
}

class _DealsContent extends StatelessWidget {
  final List<_DealItem> deals;
  final Function(String) onItemTap;

  const _DealsContent({
    required this.deals,
    required this.onItemTap,
  });

  @override
  Widget build(BuildContext context) {
    // Fixed height for the cards area to prevent overflow
    const double smallCardHeight = 105.0;
    const double gap = 10.0;
    const double totalHeight = smallCardHeight * 2 + gap;
    final mainDeal = deals[0];
    final secondDeal = deals[1];
    final thirdDeal = deals[2];

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
                // LEFT — Large vertical card (narrower)
                Expanded(
                  flex: 4,
                  child: _LargeCard(
                    discount: mainDeal.discount,
                    shopName: mainDeal.shopName,
                    menuItemName: mainDeal.menuItemName,
                    price: mainDeal.price,
                    oldPrice: mainDeal.oldPrice,
                    imagePath: mainDeal.imagePath,
                    onTap: () => onItemTap(mainDeal.menuItemName),
                  ),
                ),
                const SizedBox(width: gap),
                // RIGHT — Two horizontal cards stacked (wider for clear content)
                Expanded(
                  flex: 7,
                  child: Column(
                    children: [
                      Expanded(
                        child: _SmallCard(
                          discount: secondDeal.discount,
                          shopName: secondDeal.shopName,
                          menuItemName: secondDeal.menuItemName,
                          price: secondDeal.price,
                          oldPrice: secondDeal.oldPrice,
                          imagePath: secondDeal.imagePath,
                          onTap: () => onItemTap(secondDeal.menuItemName),
                        ),
                      ),
                      const SizedBox(height: gap),
                      Expanded(
                        child: _SmallCard(
                          discount: thirdDeal.discount,
                          shopName: thirdDeal.shopName,
                          menuItemName: thirdDeal.menuItemName,
                          price: thirdDeal.price,
                          oldPrice: thirdDeal.oldPrice,
                          imagePath: thirdDeal.imagePath,
                          onTap: () => onItemTap(thirdDeal.menuItemName),
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
  final String menuItemName;
  final String price;
  final String oldPrice;
  final String imagePath;
  final VoidCallback onTap;

  const _LargeCard({
    required this.discount,
    required this.shopName,
    required this.menuItemName,
    required this.price,
    required this.oldPrice,
    required this.imagePath,
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image area
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(8),
                  topRight: Radius.circular(8),
                ),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Container(
                      color: AppColors.bgWarm,
                      child: _DealImage(imagePath: imagePath),
                    ),
                    if (discount.isNotEmpty)
                      Positioned(
                        top: 8,
                        right: 8,
                        child: _DiscountBadge(label: discount),
                      ),
                  ],
                ),
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
                    menuItemName,
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
                      if (oldPrice.isNotEmpty)
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
  final String menuItemName;
  final String price;
  final String oldPrice;
  final String imagePath;
  final VoidCallback onTap;

  const _SmallCard({
    required this.discount,
    required this.shopName,
    required this.menuItemName,
    required this.price,
    required this.oldPrice,
    required this.imagePath,
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
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Image area (square)
            AspectRatio(
              aspectRatio: 1,
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(8),
                  bottomLeft: Radius.circular(8),
                ),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Container(
                      color: AppColors.bgWarm,
                      child: _DealImage(imagePath: imagePath),
                    ),
                    if (discount.isNotEmpty)
                      Positioned(
                        top: 6,
                        left: 6,
                        child: _DiscountBadge(label: discount, small: true),
                      ),
                  ],
                ),
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
                      menuItemName,
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
                        if (oldPrice.isNotEmpty)
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
class _DealImage extends StatelessWidget {
  final String imagePath;

  const _DealImage({required this.imagePath});

  @override
  Widget build(BuildContext context) {
    if (imagePath.isEmpty) {
      return const Icon(
        Icons.fastfood,
        size: 32,
        color: AppColors.textTertiary,
      );
    }

    if (imagePath.startsWith('http')) {
      return Image.network(
        imagePath,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => const Icon(
          Icons.fastfood,
          size: 32,
          color: AppColors.textTertiary,
        ),
      );
    }

    return Image.asset(
      imagePath,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => const Icon(
        Icons.fastfood,
        size: 32,
        color: AppColors.textTertiary,
      ),
    );
  }
}

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
