import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../pages/branches/branch_detail_view_data.dart';

class BranchMenuSectionSlivers extends StatelessWidget {
  final List<BranchMenuSectionViewData> sections;
  final List<GlobalKey> sectionKeys;
  final String? highlightedItemName;
  final GlobalKey highlightedItemKey;
  final ValueChanged<BranchMenuItemViewData> onItemTap;

  const BranchMenuSectionSlivers({
    super.key,
    required this.sections,
    required this.sectionKeys,
    required this.highlightedItemName,
    required this.highlightedItemKey,
    required this.onItemTap,
  });

  @override
  Widget build(BuildContext context) {
    final entries = <_MenuEntry>[];

    for (var sectionIndex = 0; sectionIndex < sections.length; sectionIndex++) {
      entries.add(_MenuEntry.header(sectionIndex));
      for (final item in sections[sectionIndex].items) {
        entries.add(_MenuEntry.item(sectionIndex, item));
      }
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final entry = entries[index];
          final section = sections[entry.sectionIndex];

          if (entry.item == null) {
            return Padding(
              key: sectionKeys[entry.sectionIndex],
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
              child: Text(
                '${section.name} (${section.items.length})',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            );
          }

          final item = entry.item!;
          final isHighlighted = highlightedItemName != null &&
              item.name.toLowerCase() == highlightedItemName!.toLowerCase();

          return BranchMenuItemTile(
            key: isHighlighted ? highlightedItemKey : null,
            item: item,
            isHighlighted: isHighlighted,
            onTap: () => onItemTap(item),
          );
        },
        childCount: entries.length,
      ),
    );
  }
}

class _MenuEntry {
  final int sectionIndex;
  final BranchMenuItemViewData? item;

  const _MenuEntry.header(this.sectionIndex) : item = null;

  const _MenuEntry.item(this.sectionIndex, this.item);
}

class BranchMenuItemTile extends StatelessWidget {
  final BranchMenuItemViewData item;
  final bool isHighlighted;
  final VoidCallback onTap;

  const BranchMenuItemTile({
    super.key,
    required this.item,
    required this.isHighlighted,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isHighlighted ? AppColors.bgSoft : Colors.transparent,
          border: isHighlighted
              ? Border.all(
                  color: AppColors.secondary.withValues(alpha: 0.5),
                  width: 1.5,
                )
              : null,
          borderRadius: isHighlighted ? BorderRadius.circular(12) : null,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _MenuImage(item: item, size: 70),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        '${item.sold} đã bán',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${item.likes} lượt thích',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    item.price,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
            const Align(
              alignment: Alignment.bottomRight,
              child: _AddButton(size: 28, iconSize: 18),
            ),
          ],
        ),
      ),
    );
  }
}

class BranchPopularItems extends StatelessWidget {
  final List<BranchMenuItemViewData> items;
  final ValueChanged<BranchMenuItemViewData> onItemTap;

  const BranchPopularItems({
    super.key,
    required this.items,
    required this.onItemTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Món phổ biến',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 160,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (_, index) {
                final item = items[index];
                return _PopularItemCard(
                  item: item,
                  onTap: () => onItemTap(item),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _PopularItemCard extends StatelessWidget {
  final BranchMenuItemViewData item;
  final VoidCallback onTap;

  const _PopularItemCard({
    required this.item,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 130,
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
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
              child: Stack(
                children: [
                  _MenuImage(item: item, height: 80),
                  Positioned(
                    top: 6,
                    left: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '${item.sold} đã bán',
                        style: const TextStyle(
                          fontSize: 9,
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            item.price,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const _AddButton(size: 24, iconSize: 16),
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

class _MenuImage extends StatelessWidget {
  final BranchMenuItemViewData item;
  final double? size;
  final double? height;

  const _MenuImage({
    required this.item,
    this.size,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    final image = item.imageUrl.isEmpty
        ? Icon(item.icon, size: 28, color: AppColors.textTertiary)
        : item.imageUrl.startsWith('http')
        ? Image.network(
            item.imageUrl,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Icon(
              item.icon,
              size: 28,
              color: AppColors.textTertiary,
            ),
          )
        : Image.asset(
            item.imageUrl,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Icon(
              item.icon,
              size: 28,
              color: AppColors.textTertiary,
            ),
          );

    return Container(
      width: size ?? double.infinity,
      height: size ?? height,
      decoration: BoxDecoration(
        color: AppColors.bgWarm,
        borderRadius: BorderRadius.circular(size == null ? 0 : 8),
      ),
      clipBehavior: Clip.hardEdge,
      child: image,
    );
  }
}

class _AddButton extends StatelessWidget {
  final double size;
  final double iconSize;

  const _AddButton({
    required this.size,
    required this.iconSize,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        color: AppColors.primary,
        shape: BoxShape.circle,
      ),
      child: Icon(Icons.add, size: iconSize, color: Colors.white),
    );
  }
}
