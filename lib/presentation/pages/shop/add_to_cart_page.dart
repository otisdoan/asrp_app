import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

/// Add to Cart Page — topping selection, size, notes, quantity.
/// Follows RULE: UI-only, uses AppColors, responsive.
class AddToCartPage extends StatefulWidget {
  final String name;
  final String price;
  final IconData icon;

  const AddToCartPage({
    super.key,
    required this.name,
    required this.price,
    required this.icon,
  });

  @override
  State<AddToCartPage> createState() => _AddToCartPageState();
}

class _AddToCartPageState extends State<AddToCartPage> {
  int _quantity = 1;
  final Set<int> _selectedToppings = {};
  int _selectedSize = -1; // -1 = none selected
  final TextEditingController _noteController = TextEditingController();

  // Mock toppings
  static const _toppings = [
    {'name': 'Kem trứng', 'price': 13000},
    {'name': 'Kem muối', 'price': 12000},
    {'name': 'Sữa tươi', 'price': 12000},
    {'name': 'Sữa đặc', 'price': 10000},
    {'name': 'Thêm Trà Đá', 'price': 8000},
    {'name': 'Thêm đá để riêng', 'price': 5000},
  ];

  // Mock sizes
  static const _sizes = [
    {'name': 'Lớn', 'price': 13000},
  ];

  int get _basePrice {
    final priceStr = widget.price.replaceAll(RegExp(r'[^\d]'), '');
    return int.tryParse(priceStr) ?? 0;
  }

  int get _toppingTotal {
    int total = 0;
    for (final i in _selectedToppings) {
      total += _toppings[i]['price'] as int;
    }
    return total;
  }

  int get _sizeExtra {
    if (_selectedSize < 0) return 0;
    return _sizes[_selectedSize]['price'] as int;
  }

  int get _totalPrice => (_basePrice + _toppingTotal + _sizeExtra) * _quantity;

  String _formatPrice(int price) {
    return price.toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.');
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // ─── Image Header ───────────────────────────────────
          _buildImageHeader(context),

          // ─── Food Name + Price ──────────────────────────────
          SliverToBoxAdapter(child: _buildFoodHeader()),

          // ─── Toppings Section ───────────────────────────────
          SliverToBoxAdapter(child: _buildToppingsSection()),

          // ─── Size Section ───────────────────────────────────
          SliverToBoxAdapter(child: _buildSizeSection()),

          // ─── Note Section ───────────────────────────────────
          SliverToBoxAdapter(child: _buildNoteSection()),

          // ─── Quantity Section ───────────────────────────────
          SliverToBoxAdapter(child: _buildQuantitySection()),

          // Bottom spacing
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
      // ─── Bottom Add to Cart Button ──────────────────────────
      bottomNavigationBar: _buildBottomButton(),
    );
  }

  // ─── Image Header ──────────────────────────────────────────────────────
  Widget _buildImageHeader(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 220,
      pinned: true,
      backgroundColor: AppColors.background,
      leading: IconButton(
        icon: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: AppColors.inverseSurface.withValues(alpha: 0.26),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.close, color: AppColors.onPrimary, size: 20),
        ),
        onPressed: () => Navigator.pop(context),
      ),
      title: null,
      actions: [
        IconButton(
          icon: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppColors.inverseSurface.withValues(alpha: 0.26),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.share_outlined, color: AppColors.onPrimary, size: 20),
          ),
          onPressed: () {},
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          color: AppColors.bgWarm,
          child: Icon(widget.icon, size: 80, color: AppColors.textTertiary),
        ),
      ),
    );
  }

  // ─── Food Name + Price Header ──────────────────────────────────────────
  Widget _buildFoodHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 20, 12, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Name + Price row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  widget.name,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _formatPrice(_basePrice),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const Text(
                    'Giá gốc',
                    style: TextStyle(fontSize: 12, color: AppColors.textTertiary),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Description
          const Text(
            'Món ăn thơm ngon, được chế biến từ nguyên liệu tươi sạch mỗi ngày.',
            style: TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          const Divider(height: 1, color: AppColors.outlineVariant),
        ],
      ),
    );
  }

  // ─── Toppings Section ──────────────────────────────────────────────────
  Widget _buildToppingsSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              const Text(
                'Topping drink',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.bgSoft,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Không bắt buộc, tối đa 6',
                  style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Topping items
          ...List.generate(_toppings.length, (index) {
            final topping = _toppings[index];
            final isSelected = _selectedToppings.contains(index);
            return _buildCheckboxItem(
              name: topping['name'] as String,
              price: '+${_formatPrice(topping['price'] as int)}',
              isSelected: isSelected,
              onTap: () {
                setState(() {
                  if (isSelected) {
                    _selectedToppings.remove(index);
                  } else {
                    _selectedToppings.add(index);
                  }
                });
              },
            );
          }),
          const SizedBox(height: 8),
          const Divider(height: 1, color: AppColors.outlineVariant),
        ],
      ),
    );
  }

  // ─── Size Section ──────────────────────────────────────────────────────
  Widget _buildSizeSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 16, 12, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              const Text(
                'Size L',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.bgSoft,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Không bắt buộc, tối đa 1',
                  style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Size items
          ...List.generate(_sizes.length, (index) {
            final size = _sizes[index];
            final isSelected = _selectedSize == index;
            return _buildCheckboxItem(
              name: size['name'] as String,
              price: '+${_formatPrice(size['price'] as int)}',
              isSelected: isSelected,
              onTap: () {
                setState(() {
                  _selectedSize = isSelected ? -1 : index;
                });
              },
            );
          }),
          const SizedBox(height: 8),
          const Divider(height: 1, color: AppColors.outlineVariant),
        ],
      ),
    );
  }

  // ─── Note Section ──────────────────────────────────────────────────────
  Widget _buildNoteSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 16, 12, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              const Text(
                'Thêm lưu ý cho quán',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.bgSoft,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Không bắt buộc',
                  style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Text field
          Container(
            decoration: BoxDecoration(
              color: AppColors.bgSoft,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.outlineVariant),
            ),
            child: TextField(
              controller: _noteController,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Việc thực hiện yêu cầu còn tùy thuộc vào khả năng của quán.',
                hintStyle: TextStyle(fontSize: 13, color: AppColors.textTertiary),
                border: InputBorder.none,
                contentPadding: EdgeInsets.all(12),
              ),
              style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  // ─── Quantity Section ──────────────────────────────────────────────────
  Widget _buildQuantitySection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Minus button
          GestureDetector(
            onTap: () {
              if (_quantity > 1) setState(() => _quantity--);
            },
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: _quantity > 1 ? AppColors.primary : AppColors.bgSoft,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.remove,
                size: 20,
                color: _quantity > 1 ? AppColors.onPrimary : AppColors.textTertiary,
              ),
            ),
          ),
          // Quantity
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              '$_quantity',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          // Plus button
          GestureDetector(
            onTap: () => setState(() => _quantity++),
            child: Container(
              width: 36,
              height: 36,
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.add, size: 20, color: AppColors.onPrimary),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Checkbox Item ─────────────────────────────────────────────────────
  Widget _buildCheckboxItem({
    required String name,
    required String price,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            // Checkbox
            Container(
              width: 22,
              height: 22,
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
            const SizedBox(width: 14),
            // Name
            Expanded(
              child: Text(
                name,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            // Price
            Text(
              price,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Bottom Add to Cart Button ─────────────────────────────────────────
  Widget _buildBottomButton() {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      decoration: const BoxDecoration(
        color: AppColors.onPrimary,
        boxShadow: [
          BoxShadow(color: Color(0x0F000000), blurRadius: 8, offset: Offset(0, -2)),
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () {
              Navigator.pop(context, {
                'quantity': _quantity,
                'total': _totalPrice,
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.onPrimary,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              elevation: 0,
            ),
            child: Text(
              'Thêm vào giỏ hàng - ${_formatPrice(_totalPrice)}',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
          ),
        ),
      ),
    );
  }
}
