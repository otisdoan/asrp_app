import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/menu_item_model.dart';

class MenuItemCard extends StatelessWidget {
  final MenuItemModel item;
  final VoidCallback? onTap;
  final VoidCallback? onAdd;

  const MenuItemCard({super.key, required this.item, this.onTap, this.onAdd});

  Color _badgeBg(BadgeType t) {
    switch (t) {
      case BadgeType.hot: return AppColors.badgeHotBg;
      case BadgeType.newItem: return AppColors.badgeNewBg;
      case BadgeType.best: return AppColors.badgeBestBg;
      case BadgeType.sale: return AppColors.badgeSaleBg;
    }
  }

  Color _badgeText(BadgeType t) {
    switch (t) {
      case BadgeType.hot: return AppColors.badgeHotText;
      case BadgeType.newItem: return AppColors.badgeNewText;
      case BadgeType.best: return AppColors.badgeBestText;
      case BadgeType.sale: return AppColors.badgeSaleText;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.outlineVariant),
          boxShadow: const [BoxShadow(color: Color(0x0F000000), blurRadius: 3, offset: Offset(0, 1))],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Image area
          SizedBox(
            height: 80,
            child: Stack(children: [
              Container(
                width: double.infinity,
                decoration: const BoxDecoration(color: AppColors.surfaceContainer, borderRadius: BorderRadius.vertical(top: Radius.circular(8))),
                child: Center(child: Text(item.emoji, style: const TextStyle(fontSize: 32))),
              ),
              if (item.badge != null)
                Positioned(top: 6, left: 6, child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(color: _badgeBg(item.badge!.type), borderRadius: BorderRadius.circular(4)),
                  child: Text(item.badge!.label, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: _badgeText(item.badge!.type))),
                )),
            ]),
          ),
          // Body
          Expanded(child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 6, 8, 8),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              if (item.rating != null) Text('★' * item.rating!.round() + '☆' * (5 - item.rating!.round()), style: const TextStyle(fontSize: 9, color: AppColors.star)),
              Text(item.name, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, height: 1.3)),
              const Spacer(),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, crossAxisAlignment: CrossAxisAlignment.center, children: [
                Expanded(
                  child: Text(
                    item.price,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.primary),
                  ),
                ),
                const SizedBox(width: 4),
                GestureDetector(
                  onTap: onAdd,
                  child: Container(
                    width: 24, height: 24,
                    decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                    child: const Icon(Icons.add, color: Colors.white, size: 16),
                  ),
                ),
              ]),
            ]),
          )),
        ]),
      ),
    );
  }
}
