import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../providers/chat_cart_provider.dart';
import '../../../../../providers/branch_provider.dart';
import '../../../../../data/models/branch_model.dart';
import '../../../../../core/services/location_service.dart';

/// Card gợi ý chi nhánh/món ăn từ AI.
/// Bao gồm ảnh, thông tin quán, nút xem chi tiết và điều chỉnh số lượng.
class RecommendationCard extends ConsumerWidget {
  final Map<String, dynamic> rec;
  final void Function(Map<String, dynamic>) onOpenStore;
  final void Function(String message, Color color, IconData icon)
      onNotification;

  const RecommendationCard({
    super.key,
    required this.rec,
    required this.onOpenStore,
    required this.onNotification,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userLocation = ref.watch(userLocationProvider);
    final branchesAsync = ref.watch(branchesFutureProvider);
    final List<BranchListItemModel> branches = branchesAsync.asData?.value ?? [];

    final String bId = rec['branchId']?.toString() ?? rec['branch_id']?.toString() ?? '';
    final String storeName = rec['storeName']?.toString() ?? rec['branchName']?.toString() ?? rec['name']?.toString() ?? 'Cửa hàng';

    BranchListItemModel? matchedBranch;
    if (bId.isNotEmpty) {
      for (final b in branches) {
        if (b.id == bId) {
          matchedBranch = b;
          break;
        }
      }
    }
    if (matchedBranch == null && storeName.isNotEmpty) {
      for (final b in branches) {
        final bName = b.name.toLowerCase();
        final sName = storeName.toLowerCase();
        if (bName.contains(sName) || sName.contains(bName)) {
          matchedBranch = b;
          break;
        }
      }
    }

    final double? lat = matchedBranch?.latitude ?? (rec['latitude'] as num?)?.toDouble() ?? (rec['lat'] as num?)?.toDouble();
    final double? lon = matchedBranch?.longitude ?? (rec['longitude'] as num?)?.toDouble() ?? (rec['lng'] as num?)?.toDouble();
    final String dishName = rec['dishName']?.toString() ?? rec['name']?.toString() ?? 'Món ăn';
    final String priceText = rec['priceText']?.toString() ??
        (rec['priceAmount'] != null
            ? '${(rec['priceAmount'] as num).toInt()}đ'
            : (rec['price'] != null ? '${(rec['price'] as num).toInt()}đ' : '0đ'));
    final String imageUrl = rec['imageUrl']?.toString() ?? rec['image']?.toString() ?? matchedBranch?.imageUrl ?? '';
    final String address = matchedBranch?.address ?? rec['address']?.toString() ?? rec['branchAddress']?.toString() ?? '';
    final String realStoreName = matchedBranch?.name ?? storeName;

    final String displayDistance = LocationService.calculateBranchDistance(
      userLocation: userLocation,
      branchLat: lat,
      branchLng: lon,
      branchAddress: address,
      branchName: realStoreName,
    );

    final String tag = rec['tag'] as String? ?? '';

    Color tagBgColor;
    Color tagTextColor;
    if (tag == 'Rẻ nhất') {
      tagBgColor = const Color(0xFFDCFCE7);
      tagTextColor = const Color(0xFF15803D);
    } else if (tag == 'Yêu thích') {
      tagBgColor = const Color(0xFFFEE2E2);
      tagTextColor = const Color(0xFFB91C1C);
    } else if (tag == 'Bán chạy') {
      tagBgColor = const Color(0xFFFEF3C7);
      tagTextColor = const Color(0xFFB45309);
    } else {
      tagBgColor = const Color(0xFFDBEAFE);
      tagTextColor = const Color(0xFF1D4ED8);
    }

    return GestureDetector(
      onTap: () => onOpenStore(rec),
      child: Container(
        padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFFF4F0), width: 1.0),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFD84315).withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ────────────────────────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(5),
                      decoration: const BoxDecoration(
                        color: Color(0xFFFFF4F0),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.storefront_rounded,
                          color: Color(0xFFEA580C), size: 12),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        storeName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1F2937),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: tagBgColor,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  tag,
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    color: tagTextColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // ── Details ────────────────────────────────────────────────────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Thumbnail
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: const Color(0xFFFFEDD5), width: 1.0),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(11),
                  child: imageUrl.isNotEmpty
                      ? Image.network(
                          imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _placeholder(),
                        )
                      : _placeholder(),
                ),
              ),
              const SizedBox(width: 12),

              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      dishName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      priceText,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFFEA580C),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.star_rounded,
                            color: Color(0xFFF59E0B), size: 12),
                        const SizedBox(width: 2),
                        Text(
                          '${rec['rating']}',
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1F2937),
                          ),
                        ),
                        Text(
                          ' (${rec['reviews']})',
                          style: const TextStyle(
                              fontSize: 10,
                              color: Color(0xFF6B7280)),
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.location_on_outlined,
                            color: Color(0xFF9CA3AF), size: 11),
                        const SizedBox(width: 2),
                        Text(
                          displayDistance,
                          style: const TextStyle(
                              fontSize: 10,
                              color: Color(0xFF6B7280)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // ── Buttons ───────────────────────────────────────────────────────
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 38,
                  child: OutlinedButton(
                    onPressed: () => onOpenStore(rec),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(
                          color: Color(0xFFE2E8F0), width: 1.0),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      backgroundColor: Colors.white,
                      padding: EdgeInsets.zero,
                      elevation: 0,
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Xem chi tiết',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF4B5563),
                          ),
                        ),
                        SizedBox(width: 4),
                        Icon(Icons.arrow_forward_ios_rounded,
                            size: 8, color: Color(0xFF4B5563)),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Container(
                  height: 38,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFF97316), Color(0xFFEA580C)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFEA580C)
                            .withValues(alpha: 0.15),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: _QuantityControllerButton(rec: rec),
                ),
              ),
            ],
          ),
        ],
      ),
    ),
    );
  }

  Widget _placeholder() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFFFF7ED), Color(0xFFFFEDD5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: const Center(
        child: Icon(Icons.ramen_dining_rounded,
            color: Color(0xFFEA580C), size: 32),
      ),
    );
  }
}

// ── Quantity controller inlined trong recommendation card ──────────────────

class _QuantityControllerButton extends ConsumerWidget {
  final Map<String, dynamic> rec;

  const _QuantityControllerButton({required this.rec});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cart = ref.watch(chatCartProvider);
    final menuItemId = rec['menuItemId']?.toString() ?? rec['id']?.toString() ?? rec['dishId']?.toString();
    final branchId = rec['branchId']?.toString() ?? rec['branch_id']?.toString() ?? '';
    final name = rec['dishName']?.toString() ?? rec['name']?.toString() ?? '';
    
    double parsePrice(dynamic val) {
      if (val is num) return val.toDouble();
      if (val is String) return double.tryParse(val) ?? 0.0;
      return 0.0;
    }

    final price = parsePrice(rec['priceAmount'] ?? rec['price'] ?? rec['basePrice']);

    if (menuItemId == null || menuItemId.isEmpty) return const SizedBox.shrink();

    final cartItem = cart.firstWhere(
      (item) =>
          item.menuItemId == menuItemId && item.branchId == branchId,
      orElse: () => const ChatCartItem(
        menuItemId: '',
        branchId: '',
        name: '',
        basePrice: 0,
        quantity: 0,
        selectedSizeId: '',
      ),
    );

    void update(int delta) {
      try {
        final sizesJson = rec['sizes'] as List<dynamic>?;
        List<MenuItemSize> availableSizes = [];
        if (sizesJson != null) {
          for (final s in sizesJson) {
            if (s is Map) {
              availableSizes.add(MenuItemSize.fromJson(Map<String, dynamic>.from(s)));
            }
          }
        }

        ref.read(chatCartProvider.notifier).updateItem(
              menuItemId,
              branchId,
              name,
              price,
              delta,
              imageUrl: rec['imageUrl']?.toString(),
              availableSizes: availableSizes,
            );
      } catch (e) {
        if (e.toString().contains('DIFFERENT_BRANCH')) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                  'Bạn chỉ có thể đặt món từ 1 chi nhánh trong cùng 1 đơn!'),
              backgroundColor: Colors.redAccent,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }

    if (cartItem.quantity == 0) {
      return ElevatedButton(
        onPressed: () => update(1),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          shadowColor: Colors.transparent,
          elevation: 0,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
          padding: EdgeInsets.zero,
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.shopping_bag_outlined,
                size: 13, color: Colors.white),
            SizedBox(width: 4),
            Text(
              'Chọn món',
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Colors.white),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            padding: EdgeInsets.zero,
            constraints:
                const BoxConstraints(minWidth: 28, minHeight: 28),
            icon: const Icon(Icons.remove, color: Colors.white, size: 14),
            onPressed: () => update(-1),
          ),
          Text(
            '${cartItem.quantity}',
            style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 12,
                color: Colors.white),
          ),
          IconButton(
            padding: EdgeInsets.zero,
            constraints:
                const BoxConstraints(minWidth: 28, minHeight: 28),
            icon: const Icon(Icons.add, color: Colors.white, size: 14),
            onPressed: () => update(1),
          ),
        ],
      ),
    );
  }
}

/// Danh sách các card gợi ý — wrapper widget.
class RecommendationsList extends ConsumerWidget {
  final List<dynamic> recommendations;
  final void Function(Map<String, dynamic>) onOpenStore;
  final void Function(String message, Color color, IconData icon)
      onNotification;

  const RecommendationsList({
    super.key,
    required this.recommendations,
    required this.onOpenStore,
    required this.onNotification,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (recommendations.isEmpty) return const SizedBox.shrink();
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: recommendations.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final raw = recommendations[index];
        final Map<String, dynamic> rec = raw is Map ? Map<String, dynamic>.from(raw) : {};
        if (rec.isEmpty) return const SizedBox.shrink();
        return RecommendationCard(
          rec: rec,
          onOpenStore: onOpenStore,
          onNotification: onNotification,
        );
      },
    );
  }
}
