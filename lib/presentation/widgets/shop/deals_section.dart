import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/branch_model.dart';
import '../../../providers/branch_provider.dart';
import '../../pages/shop/store_detail_page.dart';

/// Section "Quán Mới Deal Hời" — horizontal scroll of new stores with hot discounts.
/// Replaces the old grid-style "Trùm Deal Ngon" section.
class DealsSection extends ConsumerWidget {
  final Function(String) onItemTap;

  const DealsSection({super.key, required this.onItemTap});

  static const _mockDeals = [
    {
      'id': 'mock-1',
      'name': 'Bếp Nhà Thái Hạ - Trà Sữa, Chè Thái & Ăn Vặt',
      'promo': 'Mã giảm 40k',
      'image': 'assets/images/com.webp',
    },
    {
      'id': 'mock-2',
      'name': 'UMê Café - Tiệm Trà Sữa - 797 Hùng Vương',
      'promo': 'Mã giảm 11%',
      'image': 'assets/images/tra_sua.jpg',
    },
    {
      'id': 'mock-3',
      'name': 'Bánh Xèo Giòn A Tốt - Bánh Xèo Hoài Nhơn',
      'promo': 'Mã giảm 11%',
      'image': 'assets/images/pho.jpg',
    },
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final branchesAsync = ref.watch(branchesFutureProvider);

    return branchesAsync.when(
      data: (branches) {
        if (branches.isEmpty) {
          return _buildContent(context, _getMockBranches());
        }
        return _buildContent(context, branches);
      },
      loading: () => _buildLoadingState(),
      error: (err, stack) {
        print('[DealsSection] Lỗi tải chi nhánh: $err');
        return _buildContent(context, _getMockBranches());
      },
    );
  }

  List<BranchListItemModel> _getMockBranches() {
    return _mockDeals
        .map((m) => BranchListItemModel(
              id: m['id']!,
              name: m['name']!,
              imageUrl: m['image']!,
              rating: 4.8,
              distance: '1.2 km',
              deliveryTime: '20 phút',
              promo: m['promo'],
            ))
        .toList();
  }

  Widget _buildLoadingState() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 200,
          height: 16,
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: 300,
          height: 12,
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 195,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: 3,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (_, __) => Container(
              width: 135,
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildContent(
      BuildContext context, List<BranchListItemModel> branches) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ─── Header ─────────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Quán Deal Hời, Giảm mạnh',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFFE55333), // ShopeeFood Orange-Red
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 3),
                    Text(
                      'DineX gợi ý quán ngon cho bộ sưu tập của bạn',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.textTertiary,
                        fontWeight: FontWeight.w400,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => context.push('/section-detail?type=deals&title=Quán Mới Lên Sàn, Giảm 50.000Đ'),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Xem thêm',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    Icon(Icons.chevron_right,
                        color: AppColors.textTertiary, size: 16),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // ─── Row of cards ───────────────────────────────────
          SizedBox(
            height: 195,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: branches.length > 6 ? 6 : branches.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final branch = branches[index];

                // Dynamic promo label formatting
                String promoTag = 'Mã giảm 10%';
                if (branch.discount != null && branch.discount!.isNotEmpty) {
                  final rawDiscount = branch.discount!;
                  if (rawDiscount.contains('%') ||
                      rawDiscount.toLowerCase().contains('k')) {
                    promoTag = 'Mã giảm $rawDiscount';
                  } else {
                    promoTag = 'Mã giảm $rawDiscount';
                  }
                } else if (branch.promo != null && branch.promo!.isNotEmpty) {
                  promoTag = branch.promo!;
                  if (!promoTag.toLowerCase().contains('giảm') &&
                      !promoTag.toLowerCase().contains('freeship')) {
                    promoTag = 'Mã giảm $promoTag';
                  }
                } else {
                  final fallbacks = [
                    'Mã giảm 40k',
                    'Mã giảm 11%',
                    'Mã giảm 15%'
                  ];
                  promoTag = fallbacks[index % fallbacks.length];
                }

                return _DealCard(
                  branch: branch,
                  promoTag: promoTag,
                  onItemTap: onItemTap,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _DealCard extends StatelessWidget {
  final BranchListItemModel branch;
  final String promoTag;
  final Function(String) onItemTap;

  const _DealCard({
    required this.branch,
    required this.promoTag,
    required this.onItemTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => StoreDetailPage(
              storeName: branch.name,
              category: 'Đồ ăn · Đồ uống',
              rating: branch.rating,
              reviews: branch.reviewsCount ?? 120,
              deliveryTime: branch.deliveryTime.isNotEmpty
                  ? branch.deliveryTime
                  : '25 phút',
              distance: branch.distance.isNotEmpty ? branch.distance : '1.5 km',
              icon: Icons.store,
              branchId: branch.id.startsWith('mock') ? null : branch.id,
            ),
          ),
        );
      },
      child: SizedBox(
        width: 135,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Container(
                width: 135,
                height: 120, // Square image
                color: AppColors.bgSoft,
                child: branch.imageUrl.startsWith('http')
                    ? Image.network(
                        branch.imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Center(
                          child: Icon(Icons.store,
                              color: AppColors.textTertiary, size: 28),
                        ),
                      )
                    : Image.asset(
                        branch.imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Center(
                          child: Icon(Icons.store,
                              color: AppColors.textTertiary, size: 28),
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 6),
            // Verified Badge + Name
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 2.0),
                  child: Icon(
                    Icons.verified,
                    size: 13,
                    color: Color(0xFFF2994A), // Orange/Amber verified badge
                  ),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    branch.name,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                      height: 1.2,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const Spacer(),
            // Promo Tag
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF5F5), // Light pink/red background
                border: Border.all(
                    color: const Color(0xFFFFCCCC), width: 0.8), // Red border
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                promoTag,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFFE55333), // ShopeeFood Orange-Red text
                ),
              ),
            ),
            const SizedBox(height: 2),
          ],
        ),
      ),
    );
  }
}
