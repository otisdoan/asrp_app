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
  final Set<String> _selectedBranchIds = {};

  /// Total entries = active branch carts count
  int _totalEntries(CartState cart) {
    return cart.carts.length;
  }

  bool get _allSelected {
    final cart = ref.read(cartProvider);
    return cart.carts.isNotEmpty && _selectedBranchIds.length == cart.carts.length;
  }

  void _toggleSelectAll() {
    final cart = ref.read(cartProvider);
    setState(() {
      if (_allSelected) {
        _selectedBranchIds.clear();
      } else {
        _selectedBranchIds.addAll(cart.carts.keys);
      }
    });
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.shopping_bag_outlined,
            size: 64,
            color: AppColors.textTertiary,
          ),
          SizedBox(height: 16),
          Text(
            'Giỏ hàng của bạn đang trống',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: 8),
          Text(
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
                  if (!_isManaging) _selectedBranchIds.clear();
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
                final branchCarts = cart.carts.values.toList();
                final branchCart = branchCarts[index];
                return _buildActiveCartItem(branchCart);
              },
            ),
      // Bottom bar in manage mode
      bottomNavigationBar: _isManaging && totalCount > 0 ? _buildManageBar() : null,
    );
  }

  // ─── Active Cart Item (real data) ─────────────────────────────────────
  Widget _buildActiveCartItem(BranchCart branchCart) {
    final bid = branchCart.branchId ?? 'default_branch';
    final isSelected = _selectedBranchIds.contains(bid);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _isManaging ? null : () {
        Navigator.push(context, MaterialPageRoute(
          builder: (_) => CheckoutPage(
            storeName: branchCart.storeName ?? 'Cửa hàng',
            itemCount: branchCart.totalItems,
            distance: branchCart.distance ?? '0 km',
            icon: branchCart.icon ?? Icons.restaurant,
            branchId: branchCart.branchId,
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
                      _selectedBranchIds.remove(bid);
                    } else {
                      _selectedBranchIds.add(bid);
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
                    branchCart.storeName ?? 'Cửa hàng',
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
                        '${branchCart.totalItems} món',
                        style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                      ),
                      if (branchCart.deliveryTime != null && branchCart.deliveryTime!.isNotEmpty) ...[
                        const Text(' • ', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                        Text(
                          branchCart.deliveryTime!,
                          style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                        ),
                      ],
                      if (branchCart.distance != null && branchCart.distance!.isNotEmpty) ...[
                        const Text(' • ', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                        Text(
                          branchCart.distance!,
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
                child: (branchCart.storeImageUrl != null && branchCart.storeImageUrl!.isNotEmpty)
                    ? (branchCart.storeImageUrl!.startsWith('http')
                        ? Image.network(
                            branchCart.storeImageUrl!,
                            fit: BoxFit.cover,
                            width: 56,
                            height: 56,
                            errorBuilder: (_, __, ___) => Icon(
                              branchCart.icon ?? Icons.restaurant,
                              size: 24,
                              color: AppColors.textTertiary,
                            ),
                          )
                        : Image.asset(
                            branchCart.storeImageUrl!,
                            fit: BoxFit.cover,
                            width: 56,
                            height: 56,
                            errorBuilder: (_, __, ___) => Icon(
                              branchCart.icon ?? Icons.restaurant,
                              size: 24,
                              color: AppColors.textTertiary,
                            ),
                          ))
                    : Icon(
                        branchCart.icon ?? Icons.restaurant,
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
              onPressed: _selectedBranchIds.isNotEmpty ? () {
                final notifier = ref.read(cartProvider.notifier);
                for (final branchId in _selectedBranchIds) {
                  notifier.clearBranchCart(branchId);
                }
                setState(() {
                  _selectedBranchIds.clear();
                  _isManaging = false;
                });
              } : null,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(
                    color: _selectedBranchIds.isNotEmpty
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
                  color: _selectedBranchIds.isNotEmpty
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
