import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../data/models/branch_model.dart';
import '../../../../providers/favorite_shops_provider.dart';

class BranchDetailAppBar extends ConsumerWidget {
  final BranchDetailModel branch;
  final String storeName;
  final IconData fallbackIcon;
  final bool showSearch;
  final TextEditingController searchController;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<String> onSearchSubmitted;
  final VoidCallback onSearchTap;
  final VoidCallback onClearSearch;

  const BranchDetailAppBar({
    super.key,
    required this.branch,
    required this.storeName,
    required this.fallbackIcon,
    required this.showSearch,
    required this.searchController,
    required this.onSearchChanged,
    required this.onSearchSubmitted,
    required this.onSearchTap,
    required this.onClearSearch,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favorites = ref.watch(favoriteShopsProvider);
    final isFavorite = favorites.contains(storeName);

    return SliverAppBar(
      expandedHeight: 200,
      pinned: true,
      backgroundColor: AppColors.primary,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
      title: showSearch
          ? _SearchField(
              controller: searchController,
              onChanged: onSearchChanged,
              onSubmitted: onSearchSubmitted,
              onClear: onClearSearch,
            )
          : null,
      actions: [
        if (!showSearch)
          IconButton(
            icon: const Icon(Icons.search, color: Colors.white),
            onPressed: onSearchTap,
          ),
        IconButton(
          icon: Icon(
            isFavorite ? Icons.favorite : Icons.favorite_border,
            color: isFavorite ? const Color(0xFFFF2A55) : Colors.white,
          ),
          onPressed: () {
            ref.read(favoriteShopsProvider.notifier).toggleFavorite(storeName);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  isFavorite
                      ? 'Đã xóa "$storeName" khỏi cửa hàng yêu thích'
                      : 'Đã thêm "$storeName" vào cửa hàng yêu thích',
                ),
                duration: const Duration(seconds: 1),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            );
          },
        ),
        IconButton(
          icon: const Icon(Icons.share_outlined, color: Colors.white),
          onPressed: () {},
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: branch.imageUrl.isNotEmpty
            ? Image.network(branch.imageUrl, fit: BoxFit.cover)
            : Container(
                color: AppColors.bgWarm,
                child: Icon(
                  fallbackIcon,
                  size: 80,
                  color: AppColors.textTertiary,
                ),
              ),
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final ValueChanged<String> onSubmitted;
  final VoidCallback onClear;

  const _SearchField({
    required this.controller,
    required this.onChanged,
    required this.onSubmitted,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 36,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          const SizedBox(width: 12),
          const Icon(Icons.search, size: 18, color: Colors.white70),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              onSubmitted: onSubmitted,
              style: const TextStyle(fontSize: 13, color: Colors.white),
              cursorColor: Colors.white,
              decoration: const InputDecoration(
                filled: false,
                fillColor: Colors.transparent,
                hintText: 'Tìm món trong quán',
                hintStyle: TextStyle(
                  fontSize: 13,
                  color: Colors.white70,
                  fontWeight: FontWeight.w400,
                ),
                border: InputBorder.none,
                focusedBorder: InputBorder.none,
                enabledBorder: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
          if (controller.text.isNotEmpty) ...[
            GestureDetector(
              onTap: onClear,
              child: const Icon(Icons.close, size: 18, color: Colors.white70),
            ),
            const SizedBox(width: 12),
          ],
        ],
      ),
    );
  }
}
