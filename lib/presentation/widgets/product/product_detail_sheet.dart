import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/product_detail_model.dart';
import '../../../data/repositories/mock_data.dart';
import '../../../providers/cart_provider.dart';
import '../../../data/models/cart_item_model.dart';

class ProductDetailSheet extends ConsumerStatefulWidget {
  final String productName;
  const ProductDetailSheet({super.key, required this.productName});

  @override
  ConsumerState<ProductDetailSheet> createState() => _ProductDetailSheetState();
}

class _ProductDetailSheetState extends ConsumerState<ProductDetailSheet> {
  late ProductDetailModel _product;
  int _selectedSizeIndex = 1; // default 'Vua'
  final Set<int> _selectedToppings = {};
  final List<int> _customizationSelections = [];
  int _quantity = 1;
  bool _isFavorite = false;
  bool _showFullDesc = false;
  int _selectedGallery = 0;
  final TextEditingController _noteController = TextEditingController();
  bool _toppingMaxReached = false;

  @override
  void initState() {
    super.initState();
    _product = MockData.getProductDetail(widget.productName);
    for (var c in _product.customizations) {
      _customizationSelections.add(c.defaultIndex);
    }
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  int get _totalPrice => (_product.sizes[_selectedSizeIndex].price + _selectedToppings.fold<int>(0, (sum, i) => sum + _product.toppings[i].price)) * _quantity;

  String _fmt(int amount) {
    final s = amount.toString();
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
      buf.write(s[i]);
    }
    return buf.toString();
  }

  void _addToCart() {
    final item = CartItemModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      emoji: _product.emoji,
      name: _product.name,
      priceAmount: _totalPrice ~/ _quantity,
      priceDisplay: '${_fmt(_totalPrice ~/ _quantity)}d',
      quantity: _quantity,
      note: _noteController.text.isNotEmpty ? _noteController.text : null,
    );
    ref.read(cartProvider.notifier).addItem(item);
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('Da them ${_product.name} vao gio hang!'),
      duration: const Duration(seconds: 2),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.92,
      decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      child: Column(children: [
        // Handle bar
        Container(margin: const EdgeInsets.only(top: 8, bottom: 4), width: 40, height: 4, decoration: BoxDecoration(color: AppColors.outlineVariant, borderRadius: BorderRadius.circular(2))),
        // Scrollable content
        Expanded(child: SingleChildScrollView(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Image section
          _buildImageSection(),
          Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // Header info
            _buildHeaderInfo(),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),
            // Description
            _buildDescription(),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),
            // Sizes
            _buildSizes(),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),
            // Toppings
            _buildToppings(),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),
            // Customizations
            _buildCustomizations(),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),
            // Nutrition
            _buildNutrition(),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),
            // Reviews
            _buildReviews(),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),
            // Note
            const Text('Ghi chu', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            TextField(
              controller: _noteController,
              maxLines: 2,
              maxLength: 150,
              style: const TextStyle(fontSize: 13),
              decoration: InputDecoration(
                hintText: 'VD: Khong hanh, it muoi...',
                hintStyle: const TextStyle(fontSize: 12, color: AppColors.textPlaceholder),
                filled: true, fillColor: AppColors.surfaceContainer,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.all(10),
              ),
            ),
            const SizedBox(height: 100),
          ])),
        ]))),
        // Add to cart bar
        _buildAddToCartBar(),
        SizedBox(height: MediaQuery.of(context).padding.bottom),
      ]),
    );
  }

  Widget _buildImageSection() {
    final gallery = _product.gallery;
    return Container(
      color: AppColors.surfaceContainer,
      child: Column(children: [
        Stack(children: [
          Container(
            height: 220,
            width: double.infinity,
            color: AppColors.surfaceContainerHigh,
            child: Center(child: Text(gallery[_selectedGallery], style: const TextStyle(fontSize: 80))),
          ),
          Positioned(top: 12, right: 12, child: GestureDetector(
            onTap: () => setState(() => _isFavorite = !_isFavorite),
            child: Container(
              width: 36, height: 36,
              decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 6)]),
              child: Icon(_isFavorite ? Icons.favorite : Icons.favorite_border, size: 20, color: _isFavorite ? Colors.red : AppColors.textSecondary),
            ),
          )),
          Positioned(top: 12, left: 12, child: Row(children: [
            ..._product.badges.map((b) {
              final bg = Color(int.parse(b.colorBg.replaceAll('#', '0xFF')));
              final text = Color(int.parse(b.colorText.replaceAll('#', '0xFF')));
              return Container(
                margin: const EdgeInsets.only(right: 6),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(4)),
                child: Text(b.label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: text)),
              );
            }),
          ])),
          Positioned(top: 12, left: 12, child: GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 36, height: 36,
              decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 6)]),
              child: const Icon(Icons.close, size: 18),
            ),
          )),
        ]),
        // Thumbnails
        if (gallery.length > 1) Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(children: gallery.asMap().entries.map((e) {
            final isSelected = _selectedGallery == e.key;
            return GestureDetector(
              onTap: () => setState(() => _selectedGallery = e.key),
              child: Container(
                width: 52, height: 52, margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: isSelected ? AppColors.primary : AppColors.outlineVariant, width: isSelected ? 2 : 1),
                ),
                child: Center(child: Text(e.value, style: const TextStyle(fontSize: 26))),
              ),
            );
          }).toList()),
        ),
      ]),
    );
  }

  Widget _buildHeaderInfo() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(_product.category, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.w500)),
      const SizedBox(height: 4),
      Text(_product.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, height: 1.2)),
      const SizedBox(height: 8),
      Row(children: [
        Text('${_fmt(_product.price)}d', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.primary)),
        if (_product.originalPrice != null) ...[const SizedBox(width: 8), Text('${_fmt(_product.originalPrice!)}d', style: const TextStyle(fontSize: 14, color: AppColors.textSecondary, decoration: TextDecoration.lineThrough))],
        if (_product.originalPrice != null) ...[const SizedBox(width: 8), Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: AppColors.successContainer, borderRadius: BorderRadius.circular(4)), child: Text('-${((_product.originalPrice! - _product.price) / _product.originalPrice! * 100).round()}%', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.success)))],
      ]),
      const SizedBox(height: 8),
      Row(children: [
        Text('★' * _product.rating.round() + '☆' * (5 - _product.rating.round()), style: const TextStyle(fontSize: 14, color: AppColors.star)),
        const SizedBox(width: 6),
        Text('${_product.rating} (${_product.reviewCount} danh gia)', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
        const SizedBox(width: 12),
        Text('Da ban ${_fmt(_product.soldCount)}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
      ]),
      const SizedBox(height: 6),
      Row(children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: _product.isAvailable ? AppColors.successBright : AppColors.error, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(_product.isAvailable ? 'Con hang' : 'Het hang', style: TextStyle(fontSize: 12, color: _product.isAvailable ? AppColors.success : AppColors.error)),
      ]),
    ]);
  }

  Widget _buildDescription() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Mo ta', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
      const SizedBox(height: 8),
      Text(_product.shortDescription, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.5)),
      const SizedBox(height: 6),
      GestureDetector(
        onTap: () => setState(() => _showFullDesc = !_showFullDesc),
        child: Text(_showFullDesc ? 'Thu gon' : 'Xem them', style: const TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w600)),
      ),
      if (_showFullDesc) ...[const SizedBox(height: 8), Text(_product.fullDescription, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.5))],
      const SizedBox(height: 8),
      Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(color: AppColors.surfaceContainer, borderRadius: BorderRadius.circular(8)),
        child: Row(children: [
          const Icon(Icons.location_on_outlined, size: 14, color: AppColors.textSecondary),
          const SizedBox(width: 6),
          Expanded(child: Text(_product.origin, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary))),
        ]),
      ),
    ]);
  }

  Widget _buildSizes() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Chon kich co', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
      const SizedBox(height: 10),
      ..._product.sizes.asMap().entries.map((e) {
        final isSelected = _selectedSizeIndex == e.key;
        return GestureDetector(
          onTap: () => setState(() => _selectedSizeIndex = e.key),
          child: Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: isSelected ? AppColors.primary : AppColors.outlineVariant, width: isSelected ? 1.5 : 1),
              color: isSelected ? AppColors.primaryContainer : Colors.white,
            ),
            child: Row(children: [
              Container(width: 16, height: 16, decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: isSelected ? AppColors.primary : AppColors.outline, width: 2)), child: isSelected ? Center(child: Container(width: 8, height: 8, decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle))) : null),
              const SizedBox(width: 10),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(e.value.label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: isSelected ? AppColors.primary : AppColors.textPrimary)),
                Text(e.value.description, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
              ])),
              Text('${_fmt(e.value.price)}d', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: isSelected ? AppColors.primary : AppColors.textPrimary)),
            ]),
          ),
        );
      }),
    ]);
  }

  Widget _buildToppings() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        const Expanded(child: Text('Toppings them', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700))),
        Text('${_selectedToppings.length}/5', style: TextStyle(fontSize: 12, color: _toppingMaxReached ? AppColors.error : AppColors.textSecondary)),
      ]),
      const SizedBox(height: 10),
      ..._product.toppings.asMap().entries.map((e) {
        final isSelected = _selectedToppings.contains(e.key);
        return GestureDetector(
          onTap: () {
            setState(() {
              if (isSelected) {
                _selectedToppings.remove(e.key);
                _toppingMaxReached = false;
              } else if (_selectedToppings.length < 5) {
                _selectedToppings.add(e.key);
                _toppingMaxReached = false;
              } else {
                _toppingMaxReached = true;
              }
            });
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: isSelected ? AppColors.primary : AppColors.outlineVariant, width: isSelected ? 1.5 : 1),
              color: isSelected ? AppColors.primaryContainer : Colors.white,
            ),
            child: Row(children: [
              Container(
                width: 18, height: 18,
                decoration: BoxDecoration(borderRadius: BorderRadius.circular(4), border: Border.all(color: isSelected ? AppColors.primary : AppColors.outline, width: 1.5), color: isSelected ? AppColors.primary : Colors.white),
                child: isSelected ? const Icon(Icons.check, size: 12, color: Colors.white) : null,
              ),
              const SizedBox(width: 10),
              Expanded(child: Text(e.value.label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: isSelected ? AppColors.primary : AppColors.textPrimary))),
              Text('+${_fmt(e.value.price)}d', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: isSelected ? AppColors.primary : AppColors.textSecondary)),
            ]),
          ),
        );
      }),
      if (_toppingMaxReached) const Text('Toi da 5 topping', style: TextStyle(fontSize: 11, color: AppColors.error)),
    ]);
  }

  Widget _buildCustomizations() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Tuy chinh', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
      const SizedBox(height: 10),
      ..._product.customizations.asMap().entries.map((custEntry) {
        final cust = custEntry.value;
        final selected = _customizationSelections[custEntry.key];
        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(cust.label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
          const SizedBox(height: 8),
          Wrap(spacing: 8, runSpacing: 8, children: cust.choices.asMap().entries.map((choiceEntry) {
            final isSelected = selected == choiceEntry.key;
            return GestureDetector(
              onTap: () => setState(() => _customizationSelections[custEntry.key] = choiceEntry.key),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: isSelected ? AppColors.primary : AppColors.outlineVariant, width: isSelected ? 1.5 : 1),
                  color: isSelected ? AppColors.primaryContainer : Colors.white,
                ),
                child: Text(choiceEntry.value, style: TextStyle(fontSize: 12, fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400, color: isSelected ? AppColors.primary : AppColors.textPrimary)),
              ),
            );
          }).toList()),
          const SizedBox(height: 14),
        ]);
      }),
    ]);
  }

  Widget _buildNutrition() {
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        tilePadding: EdgeInsets.zero,
        title: const Text('Dinh duong', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
        children: [
          const SizedBox(height: 8),
          ..._product.nutrition.map((n) => Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text(n.label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              Text('${n.value} ${n.unit}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
            ]),
          )),
          if (_product.dietTags.isNotEmpty) ...[const SizedBox(height: 8), Wrap(spacing: 8, children: _product.dietTags.map((t) => Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(color: AppColors.successContainer, borderRadius: BorderRadius.circular(12)),
            child: Text(t, style: const TextStyle(fontSize: 11, color: AppColors.success, fontWeight: FontWeight.w500)),
          )).toList())],
        ],
      ),
    );
  }

  Widget _buildReviews() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Danh gia (${_product.reviewCount})', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
      const SizedBox(height: 12),
      // Rating summary
      Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
        Column(children: [
          Text(_product.rating.toString(), style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w800, color: AppColors.primary)),
          Text('★' * _product.rating.round(), style: const TextStyle(fontSize: 14, color: AppColors.star)),
          Text('${_product.reviewCount} danh gia', style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
        ]),
        const SizedBox(width: 16),
        Expanded(child: Column(children: _product.reviewDistribution.map((d) => Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Row(children: [
            Text('${d.star}★', style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
            const SizedBox(width: 6),
            Expanded(child: ClipRRect(borderRadius: BorderRadius.circular(4), child: LinearProgressIndicator(
              value: d.percent / 100,
              backgroundColor: AppColors.surfaceContainerHigh,
              color: AppColors.star,
              minHeight: 6,
            ))),
            const SizedBox(width: 6),
            Text('${d.percent}%', style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
          ]),
        )).toList())),
      ]),
      const SizedBox(height: 14),
      // Review list
      ..._product.reviews.map((r) => _buildReviewCard(r)),
    ]);
  }

  Widget _buildReviewCard(ReviewModel r) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: AppColors.surfaceContainer, borderRadius: BorderRadius.circular(10)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          CircleAvatar(radius: 16, backgroundColor: AppColors.primaryContainer, child: Text(r.name[0], style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.primary))),
          const SizedBox(width: 8),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Text(r.name, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
              if (r.membership != null) ...[const SizedBox(width: 6), Container(padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1), decoration: BoxDecoration(color: AppColors.tertiaryContainer, borderRadius: BorderRadius.circular(3)), child: Text(r.membership!, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: AppColors.onTertiaryContainer)))],
            ]),
            Text(r.date, style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
          ]),
          const Spacer(),
          Text('★' * r.rating, style: const TextStyle(fontSize: 12, color: AppColors.star)),
        ]),
        const SizedBox(height: 8),
        Text(r.content, style: const TextStyle(fontSize: 12, color: AppColors.textPrimary, height: 1.5)),
        const SizedBox(height: 6),
        Row(children: [
          const Icon(Icons.thumb_up_outlined, size: 12, color: AppColors.textSecondary),
          const SizedBox(width: 4),
          Text('${r.helpful}', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
        ]),
        if (r.reply != null) ...[const SizedBox(height: 8), Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: AppColors.surfaceContainerHigh, borderRadius: BorderRadius.circular(8)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Phan hoi cua nha hang:', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.primary)),
            const SizedBox(height: 4),
            Text(r.reply!, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, height: 1.4)),
          ]),
        )],
      ]),
    );
  }

  Widget _buildAddToCartBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.outlineVariant)),
        boxShadow: [BoxShadow(color: Color(0x1A000000), blurRadius: 10, offset: Offset(0, -4))],
      ),
      child: Row(children: [
        // Quantity stepper
        Container(
          decoration: BoxDecoration(border: Border.all(color: AppColors.outlineVariant), borderRadius: BorderRadius.circular(8)),
          child: Row(children: [
            _qtyBtn('-', () { if (_quantity > 1) setState(() => _quantity--); }),
            Padding(padding: const EdgeInsets.symmetric(horizontal: 14), child: Text('$_quantity', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700))),
            _qtyBtn('+', () { if (_quantity < 20) setState(() => _quantity++); }),
          ]),
        ),
        const SizedBox(width: 12),
        Expanded(child: ElevatedButton(
          onPressed: _product.isAvailable ? _addToCart : null,
          style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
          child: Text(_product.isAvailable ? 'Them vao gio · ${_fmt(_totalPrice)}d' : 'Het hang', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
        )),
      ]),
    );
  }

  Widget _qtyBtn(String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8), child: Text(label, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary))),
    );
  }
}
