import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  bool _isLoading = false;

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

  Future<void> _fetchAndShowIngredientSelector() async {
    try {
      final List<InventoryIngredient> branchIngredients = ref.read(inventoryProvider).ingredients;

      if (mounted) {
        _showIngredientSelector(branchIngredients);
      }
    } catch (e) {
      if (mounted) {
        TopNotification.show(context, message: 'Không thể tải danh sách nguyên liệu', isError: true);
      }
    }
  }

  void _showIngredientSelector(List<InventoryIngredient> ingredients) {
    final searchController = TextEditingController();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final query = searchController.text.toLowerCase();
            final filtered = query.isEmpty
                ? ingredients
                : ingredients.where((e) => e.name.toLowerCase().contains(query)).toList();

            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Container(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Chọn nguyên liệu nhập',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                        ),
                        TextButton.icon(
                          icon: const Icon(Icons.add, size: 18, color: AppColors.primary),
                          label: const Text('Tạo mới', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.primary)),
                          onPressed: () {
                            Navigator.pop(ctx);
                            _showCreateIngredientDialog();
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: searchController,
                      decoration: InputDecoration(
                        hintText: 'Tìm nguyên liệu...',
                        hintStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
                        prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary, size: 20),
                        filled: true,
                        fillColor: const Color(0xFFF5F5F5),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                      ),
                      onChanged: (_) => setModalState(() {}),
                    ),
                    const SizedBox(height: 8),
                    ConstrainedBox(
                      constraints: BoxConstraints(
                        maxHeight: MediaQuery.of(context).size.height * 0.35,
                      ),
                      child: filtered.isEmpty
                          ? Center(
                              child: Padding(
                                padding: const EdgeInsets.all(24),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.search_off, size: 40, color: AppColors.textSecondary),
                                    const SizedBox(height: 8),
                                    const Text('Không tìm thấy nguyên liệu', style: TextStyle(color: AppColors.textSecondary)),
                                    const SizedBox(height: 12),
                                    ElevatedButton.icon(
                                      icon: const Icon(Icons.add, size: 18),
                                      label: const Text('Tạo nguyên liệu mới'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.primary,
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                      ),
                                      onPressed: () {
                                        Navigator.pop(ctx);
                                        _showCreateIngredientDialog(initialName: searchController.text);
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            )
                          : ListView.builder(
                              shrinkWrap: true,
                              itemCount: filtered.length,
                              itemBuilder: (context, index) {
                                final ing = filtered[index];
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
              ),
            );
          },
        );
      },
    );
  }

  void _showCreateIngredientDialog({String? initialName}) {
    final nameController = TextEditingController(text: initialName ?? '');
    String selectedUnit = 'kg';
    final units = ['kg', 'g', 'litre', 'ml', 'cái', 'gói', 'hộp', 'chai', 'lon', 'bó', 'quả'];

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: const Text('Tạo nguyên liệu mới', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    autofocus: true,
                    decoration: InputDecoration(
                      labelText: 'Tên nguyên liệu',
                      labelStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                    ),
                  ),
                  const SizedBox(height: 14),
                  DropdownButtonFormField<String>(
                    initialValue: selectedUnit,
                    decoration: InputDecoration(
                      labelText: 'Đơn vị',
                      labelStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                    ),
                    items: units.map((u) => DropdownMenuItem(value: u, child: Text(u))).toList(),
                    onChanged: (v) {
                      if (v != null) setDialogState(() => selectedUnit = v);
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Hủy', style: TextStyle(color: AppColors.textSecondary)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () async {
                    final name = nameController.text.trim();
                    if (name.isEmpty) {
                      TopNotification.show(context, message: 'Vui lòng nhập tên nguyên liệu', isError: true);
                      return;
                    }
                    try {
                      final newIng = await ref.read(inventoryProvider.notifier).createIngredient(
                        name: name,
                        unit: selectedUnit,
                      );
                      if (mounted) {
                        Navigator.pop(ctx);
                        TopNotification.show(context, message: 'Đã tạo nguyên liệu "$name" thành công');
                        _addImportRow(newIng);
                      }
                    } catch (e) {
                      if (mounted) {
                        TopNotification.show(context, message: 'Lỗi tạo nguyên liệu: $e', isError: true);
                      }
                    }
                  },
                  child: const Text('Tạo'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _submitImport() async {
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

    setState(() {
      _isLoading = true;
    });

    try {
      await ref.read(inventoryProvider.notifier).importStock(
        supplier: _selectedSupplier,
        items: itemsPayload,
      );
      if (mounted) {
        TopNotification.show(context, message: 'Đã hoàn tất nhập kho và cập nhật số lượng tồn');
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        TopNotification.show(context, message: 'Nhập kho thất bại: $e', isError: true);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
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
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      behavior: HitTestBehavior.opaque,
      child: Stack(
        children: [
          Scaffold(
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
                                    items: [
                                      ..._suppliers.map((sup) {
                                        return DropdownMenuItem<String>(
                                          value: sup,
                                          child: Text(sup),
                                        );
                                      }),
                                      const DropdownMenuItem<String>(
                                        value: '__ADD_NEW__',
                                        child: Row(
                                          children: [
                                            Icon(Icons.add_circle_outline, color: AppColors.primary, size: 18),
                                            SizedBox(width: 8),
                                            Text(
                                              'Thêm đầu mối mới...',
                                              style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                    onChanged: (val) {
                                      if (val == '__ADD_NEW__') {
                                        _showAddSupplierDialog();
                                      } else if (val != null) {
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
                        onPressed: () => _fetchAndShowIngredientSelector(),
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
    if (_isLoading)
      Positioned.fill(
        child: Container(
          color: Colors.black.withValues(alpha: 0.3),
          child: const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          ),
        ),
      ),
  ],
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
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          ThousandsSeparatorInputFormatter(),
                        ],
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

  void _showAddSupplierDialog() {
    final TextEditingController controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Thêm đầu mối mới',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
        ),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'Nhập tên nhà cung cấp / đầu mối...',
            hintStyle: TextStyle(fontSize: 14, color: AppColors.textSecondary),
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: AppColors.primary),
            ),
          ),
          autofocus: true,
          style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () {
              final name = controller.text.trim();
              if (name.isNotEmpty) {
                setState(() {
                  if (!_suppliers.contains(name)) {
                    _suppliers.add(name);
                  }
                  _selectedSupplier = name;
                });
              }
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Thêm', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

class ThousandsSeparatorInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    if (newValue.text.isEmpty) {
      return newValue.copyWith(text: '');
    }

    final int selectionOffset = newValue.selection.end;
    int digitsBeforeCursor = 0;
    for (int i = 0; i < selectionOffset && i < newValue.text.length; i++) {
      if (RegExp(r'\d').hasMatch(newValue.text[i])) {
        digitsBeforeCursor++;
      }
    }

    final String cleanText = newValue.text.replaceAll(RegExp(r'\D'), '');
    if (cleanText.isEmpty) {
      return newValue.copyWith(text: '', selection: const TextSelection.collapsed(offset: 0));
    }

    final buffer = StringBuffer();
    int newSelectionOffset = 0;
    int digitCount = 0;

    for (int i = 0; i < cleanText.length; i++) {
      if (i > 0 && (cleanText.length - i) % 3 == 0) {
        buffer.write('.');
        if (digitCount == digitsBeforeCursor) {
          newSelectionOffset++;
        }
      }
      buffer.write(cleanText[i]);
      digitCount++;
      if (digitCount == digitsBeforeCursor) {
        newSelectionOffset = buffer.length;
      }
    }

    final formatted = buffer.toString();
    if (digitsBeforeCursor == 0) {
      newSelectionOffset = 0;
    } else if (digitsBeforeCursor == cleanText.length) {
      newSelectionOffset = formatted.length;
    }

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: newSelectionOffset),
    );
  }
}

