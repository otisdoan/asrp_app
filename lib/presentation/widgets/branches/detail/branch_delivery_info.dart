import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

class BranchDeliveryInfo extends StatelessWidget {
  const BranchDeliveryInfo({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: const Column(
        children: [
          _DeliveryInfoRow(
            icon: Icons.delivery_dining,
            iconColor: AppColors.success,
            title: 'Giao ngay',
            subtitle: 'Dự kiến giao lúc 16:05',
            action: 'Thay đổi >',
          ),
          SizedBox(height: 10),
          _DeliveryInfoRow(
            icon: Icons.local_offer,
            iconColor: AppColors.accent,
            title: 'Ưu đãi dành cho bạn',
            action: 'Xem thêm >',
          ),
        ],
      ),
    );
  }
}

class _DeliveryInfoRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String? subtitle;
  final String action;

  const _DeliveryInfoRow({
    required this.icon,
    required this.iconColor,
    required this.title,
    this.subtitle,
    required this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: iconColor),
        const SizedBox(width: 8),
        Expanded(
          child: Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: subtitle == null ? title : '$title  ',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                if (subtitle != null)
                  TextSpan(
                    text: subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
              ],
            ),
          ),
        ),
        Text(
          action,
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.primary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
