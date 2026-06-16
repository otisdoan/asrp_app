import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../providers/cart_provider.dart';
import 'checkout_page.dart';

/// Cart Page — shows list of stores with cart items.
/// Normal mode: view cart items per store.
/// Manage mode: checkboxes to select and delete items.
/// Follows RULE: UI-only, uses AppColors, responsive.
class CartPage extends ConsumerStatefulWidget {
  const CartPage({super.key});

  @override
  ConsumerState<CartPage> createState() => _CartPageState();
}

class _CartPageState extends ConsumerState<CartPage> {
  bool _isManaging = false;
  final Set<int> _selectedItems = {};

  /// Total entries = active cart (if non-empty)
  int _totalEntries(CartState cart) {
    return cart.items.isNotEmpty ? 1 : 0;
  }

  bool get _allSelected => _selectedItems.length == _totalEntries(ref.read(cartProvider));

  void _toggleSelectAll() {
    final total = _totalEntries(ref.read(cartProvider));
    setState(() {
      if (_allSelected) {
        _selectedItems.clear();
      } else {
        _selectedItems.addAll(List.generate(total, (i) => i));
      }
    });
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.shopping_bag_outlined,
            size: 64,
            color: AppColors.textTertiary,
          ),
          const SizedBox(height: 16),
          const Text(
            'Giỏ hàng của bạn đang trống',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Hãy thêm món ăn ngon vào giỏ hàng nhé!',
            style: TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cart = ref.watch(cartProvider);
    final totalCount = _totalEntries(cart);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.onPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Giỏ hàng của tôi',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: AppColors.onPrimary,
          ),
        ),
        centerTitle: true,
        actions: [
          if (totalCount > 0)
            TextButton(
              onPressed: () {
                setState(() {
                  _isManaging = !_isManaging;
                  if (!_isManaging) _selectedItems.clear();
                });
              },
              child: Text(
                _isManaging ? 'Huỷ' : 'Quản lý',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: _isManaging ? AppColors.onPrimary.withValues(alpha: 0.7) : AppColors.onPrimary,
                ),
              ),
            ),
        ],
      ),
      body: totalCount == 0
          ? _buildEmptyState()
          : ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: totalCount,
              separatorBuilder: (_, __) => const Divider(height: 1, color: AppColors.outlineVariant),
              itemBuilder: (context, index) {
                return _buildActiveCartItem(cart);
              },
            ),
      // Bottom bar in manage mode
      bottomNavigationBar: _isManaging && totalCount > 0 ? _buildManageBar() : null,
    );
  }

  // ─── Active Cart Item (real data) ─────────────────────────────────────
  Widget _buildActiveCartItem(CartState cart) {
    final isSelected = _selectedItems.contains(0);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _isManaging ? null : () {
        Navigator.push(context, MaterialPageRoute(
          builder: (_) => CheckoutPage(
            storeName: cart.storeName ?? 'Cửa hàng',
            itemCount: cart.totalItems,
            distance: cart.distance ?? '0 km',
            icon: cart.icon ?? Icons.restaurant,
            branchId: cart.branchId,
          ),
        ));
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Checkbox (only in manage mode)
            if (_isManaging) ...[
              GestureDetector(
                onTap: () {
                  setState(() {
                    if (isSelected) {
                      _selectedItems.remove(0);
                    } else {
                      _selectedItems.add(0);
                    }
                  });
                },
                child: Container(
                  width: 22,
                  height: 22,
                  margin: const EdgeInsets.only(right: 12, top: 4),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primary : Colors.transparent,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: isSelected ? AppColors.primary : AppColors.textTertiary,
                      width: 1.5,
                    ),
                  ),
                  child: isSelected
                      ? const Icon(Icons.check, size: 16, color: AppColors.onPrimary)
                      : null,
                ),
              ),
            ],
            // Store info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    cart.storeName ?? 'Cửa hàng',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        '${cart.totalItems} món',
                        style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                      ),
                      if (cart.deliveryTime != null && cart.deliveryTime!.isNotEmpty) ...[
                        const Text(' • ', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                        Text(
                          cart.deliveryTime!,
                          style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                        ),
                      ],
                      if (cart.distance != null && cart.distance!.isNotEmpty) ...[
                        const Text(' • ', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                        Text(
                          cart.distance!,
                          style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            // Store image
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppColors.bgWarm,
                borderRadius: BorderRadius.circular(8),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: (cart.storeImageUrl != null && cart.storeImageUrl!.isNotEmpty)
                    ? (cart.storeImageUrl!.startsWith('http')
                        ? Image.network(
                            cart.storeImageUrl!,
                            fit: BoxFit.cover,
                            width: 56,
                            height: 56,
                            errorBuilder: (_, __, ___) => Icon(
                              cart.icon ?? Icons.restaurant,
                              size: 24,
                              color: AppColors.textTertiary,
                            ),
                          )
                        : Image.asset(
                            cart.storeImageUrl!,
                            fit: BoxFit.cover,
                            width: 56,
                            height: 56,
                            errorBuilder: (_, __, ___) => Icon(
                              cart.icon ?? Icons.restaurant,
                              size: 24,
                              color: AppColors.textTertiary,
                            ),
                          ))
                    : Icon(
                        cart.icon ?? Icons.restaurant,
                        size: 24,
                        color: AppColors.textTertiary,
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Manage Bottom Bar ─────────────────────────────────────────────────
  Widget _buildManageBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: const BoxDecoration(
        color: AppColors.background,
        border: Border(top: BorderSide(color: AppColors.outlineVariant)),
      ),
      child: SafeArea(
        child: Row(
          children: [
            // Select all checkbox
            GestureDetector(
              onTap: _toggleSelectAll,
              behavior: HitTestBehavior.opaque,
              child: Row(
                children: [
                  Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      color: _allSelected ? AppColors.primary : Colors.transparent,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: _allSelected ? AppColors.primary : AppColors.textTertiary,
                        width: 1.5,
                      ),
                    ),
                    child: _allSelected
                        ? const Icon(Icons.check, size: 16, color: AppColors.onPrimary)
                        : null,
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'Chọn tất cả',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
            const Spacer(),
            // Delete button
            TextButton(
              onPressed: _selectedItems.isNotEmpty ? () {
                // If index 0 (active cart) is selected, clear the real cart
                if (_selectedItems.contains(0) && ref.read(cartProvider).items.isNotEmpty) {
                  ref.read(cartProvider.notifier).clearCart();
                }
                setState(() {
                  _selectedItems.clear();
                  _isManaging = false;
                });
              } : null,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(
                    color: _selectedItems.isNotEmpty
                        ? AppColors.textSecondary
                        : AppColors.outlineVariant,
                  ),
                ),
              ),
              child: Text(
                'Xoá',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: _selectedItems.isNotEmpty
                      ? AppColors.textPrimary
                      : AppColors.textTertiary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
