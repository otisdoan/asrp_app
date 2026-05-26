import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../data/models/branch_model.dart';
import '../../../../providers/favorite_shops_provider.dart';

class BranchStoreInfo extends ConsumerWidget {
  final BranchDetailModel branch;
  final String storeName;
  final double rating;
  final int reviews;

  const BranchStoreInfo({
    super.key,
    required this.branch,
    required this.storeName,
    required this.rating,
    required this.reviews,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isFavorite = ref.watch(favoriteShopsProvider).contains(storeName);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'Yêu thích',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.verified, color: AppColors.success, size: 18),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  branch.name,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                    height: 1.3,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 6,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ...List.generate(5, (index) {
                    if (index < rating.floor()) {
                      return const Icon(
                        Icons.star,
                        size: 14,
                        color: AppColors.star,
                      );
                    }
                    if (index < rating) {
                      return const Icon(
                        Icons.star_half,
                        size: 14,
                        color: AppColors.star,
                      );
                    }
                    return const Icon(
                      Icons.star_border,
                      size: 14,
                      color: AppColors.star,
                    );
                  }),
                  const SizedBox(width: 4),
                  Text(
                    '${rating.toStringAsFixed(1)} ($reviews+ Bình luận) >',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              _InfoDivider(),
              _MetaIconText(
                icon: Icons.access_time,
                text: branch.deliveryTime.isNotEmpty
                    ? branch.deliveryTime
                    : '15-20 phút',
              ),
              _MetaIconText(
                icon: Icons.location_on_outlined,
                text:
                    'Cách bạn ${branch.distance.isNotEmpty ? branch.distance : '3.0 km'} - 15k phí giao',
              ),
              GestureDetector(
                onTap: () {
                  ref
                      .read(favoriteShopsProvider.notifier)
                      .toggleFavorite(storeName);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        isFavorite
                            ? 'Đã xóa "$storeName" khỏi yêu thích'
                            : 'Đã thêm "$storeName" vào yêu thích',
                      ),
                      duration: const Duration(seconds: 1),
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  );
                },
                child: Icon(
                  isFavorite ? Icons.favorite : Icons.favorite_border,
                  size: 20,
                  color: isFavorite
                      ? const Color(0xFFFF2A55)
                      : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(width: 1, height: 14, color: AppColors.outlineVariant);
  }
}

class _MetaIconText extends StatelessWidget {
  final IconData icon;
  final String text;

  const _MetaIconText({
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: AppColors.textSecondary),
        const SizedBox(width: 3),
        Text(
          text,
          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
      ],
    );
  }
}
