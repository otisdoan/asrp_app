import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import 'checkout_page.dart';

/// Cart Page — shows list of stores with cart items.
/// Normal mode: view cart items per store.
/// Manage mode: checkboxes to select and delete items.
/// Follows RULE: UI-only, uses AppColors, responsive.
class CartPage extends StatefulWidget {
  const CartPage({super.key});

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  bool _isManaging = false;
  final Set<int> _selectedItems = {};

  // Mock cart data (stores with items)
  static const _cartStores = [
    {
      'name': 'Bếp Trọng - Nguyễn Thị Minh Khai',
      'items': 1,
      'time': '',
      'distance': '4,5 km',
      'closed': true,
      'closedNote': 'Đặt đơn giao sau hoặc giao vào 21 Thg 5, 10:00',
      'icon': Icons.restaurant,
    },
    {
      'name': 'Cơm Wang',
      'items': 2,
      'time': '39 phút trở lên',
      'distance': '6,5 km',
      'closed': false,
      'closedNote': '',
      'icon': Icons.rice_bowl,
    },
    {
      'name': 'Cơm Chiên Thổ - Cơm Gà 1995',
      'items': 1,
      'time': '37 phút trở lên',
      'distance': '6,9 km',
      'closed': false,
      'closedNote': '',
      'icon': Icons.lunch_dining,
    },
    {
      'name': 'CƠM GÀ 1995VB',
      'items': 1,
      'time': '39 phút trở lên',
      'distance': '6,8 km',
      'closed': false,
      'closedNote': '',
      'icon': Icons.fastfood,
    },
    {
      'name': 'MÌ TRỘN SIÊU CAY - CHÂN GÀ TRỨNG...',
      'items': 1,
      'time': '39 phút trở lên',
      'distance': '6,9 km',
      'closed': false,
      'closedNote': '',
      'icon': Icons.ramen_dining,
    },
    {
      'name': 'Bánh Cuốn 77',
      'items': 1,
      'time': '33 phút trở lên',
      'distance': '5,3 km',
      'closed': false,
      'closedNote': '',
      'icon': Icons.dinner_dining,
    },
    {
      'name': 'Cơm Tấm Sài Gòn - A Vũ',
      'items': 2,
      'time': '33 phút trở lên',
      'distance': '5,2 km',
      'closed': false,
      'closedNote': '',
      'icon': Icons.rice_bowl,
    },
    {
      'name': 'Linh Linh - Cơm Tấm, Bún, Phở - Mì...',
      'items': 2,
      'time': '37 phút trở lên',
      'distance': '6,3 km',
      'closed': false,
      'closedNote': '',
      'icon': Icons.soup_kitchen,
    },
  ];

  bool get _allSelected => _selectedItems.length == _cartStores.length;

  void _toggleSelectAll() {
    setState(() {
      if (_allSelected) {
        _selectedItems.clear();
      } else {
        _selectedItems.addAll(List.generate(_cartStores.length, (i) => i));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
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
      body: ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: _cartStores.length,
        separatorBuilder: (_, __) => const Divider(height: 1, color: AppColors.outlineVariant),
        itemBuilder: (context, index) => _buildCartItem(index),
      ),
      // Bottom bar in manage mode
      bottomNavigationBar: _isManaging ? _buildManageBar() : null,
    );
  }

  // ─── Cart Item ─────────────────────────────────────────────────────────
  Widget _buildCartItem(int index) {
    final store = _cartStores[index];
    final isClosed = store['closed'] as bool;
    final isSelected = _selectedItems.contains(index);

    return GestureDetector(
      onTap: _isManaging ? null : () {
        Navigator.push(context, MaterialPageRoute(
          builder: (_) => CheckoutPage(storeId: '00000000-0000-0000-0000-000000000000',
            storeName: store['name'] as String,
            itemCount: store['items'] as int,
            distance: store['distance'] as String,
            icon: store['icon'] as IconData,
          ),
        ));
      },
      child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Checkbox (only in manage mode)
          if (_isManaging) ...[
            GestureDetector(
              onTap: () {
                setState(() {
                  if (isSelected) {
                    _selectedItems.remove(index);
                  } else {
                    _selectedItems.add(index);
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
                // Store name
                Text(
                  store['name'] as String,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                // Items + time + distance
                Row(
                  children: [
                    Text(
                      '${store['items']} món',
                      style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                    ),
                    if ((store['time'] as String).isNotEmpty) ...[
                      const Text(' • ', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                      Text(
                        store['time'] as String,
                        style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                      ),
                    ],
                    const Text(' • ', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                    Text(
                      store['distance'] as String,
                      style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                    ),
                  ],
                ),
                // Closed status
                if (isClosed) ...[
                  const SizedBox(height: 6),
                  RichText(
                    text: TextSpan(
                      children: [
                        const TextSpan(
                          text: 'Đóng cửa',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.error,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        TextSpan(
                          text: ' · ${store['closedNote']}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
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
            child: Icon(
              store['icon'] as IconData,
              size: 24,
              color: AppColors.textTertiary,
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
