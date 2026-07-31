import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../providers/branch_provider.dart';
import '../../../data/models/branch_model.dart';
import 'order_detail_page.dart';
import 'store_detail_page.dart';

class OrderSuccessPage extends ConsumerWidget {
  final String orderId;

  const OrderSuccessPage({super.key, required this.orderId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.background, // Light background
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: const Text(
          'Đặt hàng thành công',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // ─── Scrollable Content ──────────────────────────────────────────
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    const SizedBox(height: 24),
                    // ─── Success Confirmation Card ───────────────────────────
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                      child: Column(
                        children: [
                          const Icon(
                            Icons.check_circle_rounded,
                            size: 68,
                            color: AppColors.success, // Brand green success checkmark
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Cảm ơn bạn đã đặt hàng!',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            'Bạn sẽ nhận cập nhật trong phần thông báo ở hộp thư đến.',
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 24),
                          // View Order Button
                          SizedBox(
                            width: 220,
                            height: 44,
                            child: ElevatedButton(
                              onPressed: () {
                                // Navigate directly to OrderDetailPage for this order
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => OrderDetailPage(orderId: orderId),
                                  ),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary, // Orange button
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(24),
                                ),
                                elevation: 0,
                              ),
                              child: const Text(
                                'Xem đơn hàng',
                                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Divider line
                    Container(
                      height: 1,
                      color: AppColors.outlineVariant,
                      margin: const EdgeInsets.symmetric(horizontal: 12),
                    ),
                    const SizedBox(height: 20),

                    // ─── "Có thể bạn cũng thích" Section ──────────────────────
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Có thể bạn cũng thích',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 30),

                          ref.watch(recommendedBranchesProvider).when(
                            data: (stores) {
                              if (stores.isEmpty) return const SizedBox.shrink();
                              final displayStores = stores.take(9).toList();

                              return GridView.builder(
                                padding: EdgeInsets.zero,
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: displayStores.length,
                                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 3,
                                  crossAxisSpacing: 12,
                                  mainAxisSpacing: 16,
                                  childAspectRatio: 0.62,
                                ),
                                itemBuilder: (context, index) {
                                  final store = displayStores[index];
                                  return _buildStoreCard(context, store);
                                },
                              );
                            },
                            loading: () => const Center(
                              child: Padding(
                                padding: EdgeInsets.all(16.0),
                                child: CircularProgressIndicator(color: AppColors.primary),
                              ),
                            ),
                            error: (_, __) => const SizedBox.shrink(),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStoreCard(BuildContext context, BranchListItemModel store) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => StoreDetailPage(
              storeName: store.name,
              category: store.category ?? 'Món ăn',
              rating: store.rating,
              reviews: store.reviewsCount ?? 0,
              deliveryTime: store.deliveryTime,
              distance: store.distance,
              icon: Icons.storefront,
              branchId: store.id,
              imageUrl: store.imageUrl,
            ),
          ),
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: 1,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Container(
                color: AppColors.bgWarm,
                child: store.imageUrl.isNotEmpty
                    ? Image.network(
                        store.imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Center(
                          child: Icon(Icons.storefront, size: 28, color: AppColors.textTertiary),
                        ),
                      )
                    : const Center(
                        child: Icon(Icons.storefront, size: 28, color: AppColors.textTertiary),
                      ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            store.name,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
              height: 1.3,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 3),
          Row(
            children: [
              Flexible(
                child: Text(
                  store.distance.isNotEmpty ? store.distance : '0.1km',
                  style: const TextStyle(fontSize: 11, color: AppColors.textTertiary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (store.rating > 0) ...[
                const Text(' · ', style: TextStyle(fontSize: 11, color: AppColors.textTertiary)),
                const Icon(Icons.star, size: 11, color: AppColors.star),
                const SizedBox(width: 1),
                Text(
                  store.rating.toStringAsFixed(1),
                  style: const TextStyle(fontSize: 11, color: AppColors.textTertiary),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
