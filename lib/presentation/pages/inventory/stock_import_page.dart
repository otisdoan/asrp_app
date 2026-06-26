import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../providers/inventory_provider.dart';
import '../../../core/utils/top_notification.dart';

class StockImportPage extends ConsumerStatefulWidget {
  const StockImportPage({super.key});

  @override
  ConsumerState<StockImportPage> createState() => _StockImportPageState();
}

class _StockImportPageState extends ConsumerState<StockImportPage> {
  String _selectedSupplier = 'Đầu mối Loan';
  final TextEditingController _invoiceController = TextEditingController();

  final List<Map<String, dynamic>> _importItems = [];

  final List<String> _suppliers = [
    'Đầu mối Loan',
    'Thực Phẩm Vissan',
    'Rau Sạch Đà Lạt',
    'Gia vị Kim Biên',
    'Hải sản Bình Điền',
    'Tường An Oil',
  ];

  String _formatPrice(int price) {
    return price.toString().replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]}.',
    );
  }

  int get _totalAmount {
    int total = 0;
    for (var item in _importItems) {
      final double qty = double.tryParse(item['quantityController'].text) ?? 0;
      final int price = int.tryParse(item['priceController'].text.replaceAll('.', '')) ?? 0;
      total += (qty * price).toInt();
    }
    return total;
  }

  void _addImportRow(InventoryIngredient ing) {
    if (_importItems.any((e) => e['ingredientId'] == ing.id)) {
      TopNotification.show(context, message: '${ing.name} đã được chọn', isError: true);
      return;
    }

    final qtyController = TextEditingController(text: '10');
    final priceController = TextEditingController();

    // Default prices based on ingredient name
    if (ing.name.contains('Mì')) {
      priceController.text = '32.000';
    } else if (ing.name.contains('Bò')) priceController.text = '210.000';
    else if (ing.name.contains('Hành')) priceController.text = '18.000';
    else if (ing.name.contains('Gia')) priceController.text = '15.000';
    else if (ing.name.contains('Tôm')) priceController.text = '120.000';
    else if (ing.name.contains('Dầu')) priceController.text = '24.000';
    else priceController.text = '10.000';

    setState(() {
      _importItems.add({
        'ingredientId': ing.id,
        'name': ing.name,
        'unit': ing.unit,
        'quantityController': qtyController,
        'priceController': priceController,
      });
    });
  }

  void _removeImportRow(int index) {
    setState(() {
      _importItems.removeAt(index);
    });
  }

  void _showIngredientSelector(List<InventoryIngredient> ingredients) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Chọn nguyên liệu nhập',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 12),
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.4,
                ),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: ingredients.length,
                  itemBuilder: (context, index) {
                    final ing = ingredients[index];
                    return ListTile(
                      title: Text(ing.name, style: const TextStyle(color: AppColors.textPrimary)),
                      subtitle: Text('Đơn vị: ${ing.unit}', style: const TextStyle(color: AppColors.textSecondary)),
                      trailing: const Icon(Icons.add_circle_outline, color: AppColors.primary),
                      onTap: () {
                        Navigator.pop(ctx);
                        _addImportRow(ing);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _submitImport() {
    if (_importItems.isEmpty) {
      TopNotification.show(context, message: 'Vui lòng chọn ít nhất một nguyên liệu', isError: true);
      return;
    }

    final List<Map<String, dynamic>> itemsPayload = [];
    for (var item in _importItems) {
      final double qty = double.tryParse(item['quantityController'].text) ?? 0;
      if (qty <= 0) {
        TopNotification.show(context, message: 'Số lượng nhập của ${item['name']} phải lớn hơn 0', isError: true);
        return;
      }
      itemsPayload.add({
        'ingredientId': item['ingredientId'],
        'quantity': qty,
      });
    }

    ref.read(inventoryProvider.notifier).importStock(
      supplier: _selectedSupplier,
      items: itemsPayload,
    );

    TopNotification.show(context, message: 'Đã hoàn tất nhập kho và cập nhật số lượng tồn');
    Navigator.pop(context);
  }

  @override
  void dispose() {
    _invoiceController.dispose();
    for (var item in _importItems) {
      item['quantityController'].dispose();
      item['priceController'].dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(inventoryProvider);

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      behavior: HitTestBehavior.opaque,
      child: Scaffold(
        backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppColors.onPrimary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Phiếu nhập kho',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.onPrimary),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ===== SUPPLIER & INVOICE METADATA =====
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.outlineVariant),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x06000000),
                          blurRadius: 8,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'THÔNG TIN PHIẾU NHẬP',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            const Expanded(
                              flex: 3,
                              child: Text(
                                'Nhà cung cấp:',
                                style: TextStyle(fontSize: 14, color: AppColors.textPrimary),
                              ),
                            ),
                            Expanded(
                              flex: 5,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10),
                                decoration: BoxDecoration(
                                  color: AppColors.background,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: AppColors.outlineVariant),
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<String>(
                                    value: _selectedSupplier,
                                    dropdownColor: Colors.white,
                                    isExpanded: true,
                                    style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
                                    items: _suppliers.map((sup) {
                                      return DropdownMenuItem<String>(
                                        value: sup,
                                        child: Text(sup),
                                      );
                                    }).toList(),
                                    onChanged: (val) {
                                      if (val != null) {
                                        setState(() {
                                          _selectedSupplier = val;
                                        });
                                      }
                                    },
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            const Expanded(
                              flex: 3,
                              child: Text(
                                'Số hóa đơn:',
                                style: TextStyle(fontSize: 14, color: AppColors.textPrimary),
                              ),
                            ),
                            Expanded(
                              flex: 5,
                              child: Container(
                                height: 40,
                                padding: const EdgeInsets.symmetric(horizontal: 10),
                                decoration: BoxDecoration(
                                  color: AppColors.background,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: AppColors.outlineVariant),
                                ),
                                child: TextField(
                                  controller: _invoiceController,
                                  style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
                                  decoration: const InputDecoration(
                                    hintText: 'Nhập số hóa đơn',
                                    hintStyle: TextStyle(color: AppColors.textPlaceholder, fontSize: 13),
                                    border: InputBorder.none,
                                    enabledBorder: InputBorder.none,
                                    focusedBorder: InputBorder.none,
                                    errorBorder: InputBorder.none,
                                    disabledBorder: InputBorder.none,
                                    isDense: true,
                                    contentPadding: EdgeInsets.symmetric(vertical: 10),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ===== INGREDIENT LIST HEADER =====
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'NGUYÊN LIỆU NHẬP',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
                      ),
                      TextButton.icon(
                        icon: const Icon(Icons.add, size: 16, color: AppColors.primary),
                        label: const Text(
                          'Thêm nguyên liệu',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.primary),
                        ),
                        onPressed: () => _showIngredientSelector(state.ingredients),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  // ===== IMPORT ROW ITEMS =====
                  if (_importItems.isEmpty)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32.0),
                        child: Column(
                          children: [
                            Icon(Icons.add_shopping_cart, size: 40, color: AppColors.textPlaceholder),
                            SizedBox(height: 12),
                            Text(
                              'Chưa có nguyên liệu nào được chọn\nBấm nút ở trên để thêm',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.4),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _importItems.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final item = _importItems[index];
                        return _buildImportItemRow(item, index);
                      },
                    ),
                ],
              ),
            ),
          ),

          // ===== TOTAL SUMMARY & CONFIRM BAR =====
          Container(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(
                top: BorderSide(color: AppColors.outlineVariant),
              ),
              boxShadow: [
                BoxShadow(
                  color: Color(0x08000000),
                  blurRadius: 8,
                  offset: Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'TỔNG PHIẾU NHẬP:',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                      ),
                      Text(
                        '${_formatPrice(_totalAmount)}đ',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.primary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: AppColors.textSecondary,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: const BorderSide(color: AppColors.outlineVariant),
                            ),
                            elevation: 0,
                          ),
                          child: const Text('Huỷ', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _submitImport,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            elevation: 0,
                          ),
                          child: const Text('Hoàn tất nhập kho', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ),
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

  Widget _buildImportItemRow(Map<String, dynamic> item, int index) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.outlineVariant),
        boxShadow: const [
          BoxShadow(
            color: Color(0x04000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                item['name'],
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: const Icon(Icons.close, color: AppColors.textPlaceholder, size: 18),
                onPressed: () => _removeImportRow(index),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              // Quantity
              Expanded(
                flex: 4,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Số lượng nhập', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                    const SizedBox(height: 4),
                    Container(
                      height: 38,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.outlineVariant),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: item['quantityController'],
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
                              onChanged: (val) {
                                setState(() {});
                              },
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                                errorBorder: InputBorder.none,
                                disabledBorder: InputBorder.none,
                                isDense: true,
                                contentPadding: EdgeInsets.symmetric(vertical: 10),
                              ),
                            ),
                          ),
                          Text(
                            item['unit'],
                            style: const TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // Price
              Expanded(
                flex: 5,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Đơn giá nhập (đ)', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                    const SizedBox(height: 4),
                    Container(
                      height: 38,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.outlineVariant),
                      ),
                      child: TextField(
                        controller: item['priceController'],
                        keyboardType: TextInputType.number,
                        style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
                        onChanged: (val) {
                          setState(() {});
                        },
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          errorBorder: InputBorder.none,
                          disabledBorder: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(vertical: 10),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
