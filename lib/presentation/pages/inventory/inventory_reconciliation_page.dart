import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../providers/inventory_provider.dart';
import '../../../core/utils/top_notification.dart';

class InventoryReconciliationPage extends ConsumerStatefulWidget {
  const InventoryReconciliationPage({super.key});

  @override
  ConsumerState<InventoryReconciliationPage> createState() => _InventoryReconciliationPageState();
}

class _InventoryReconciliationPageState extends ConsumerState<InventoryReconciliationPage> {
  final List<Map<String, dynamic>> _auditRows = [];

  final List<String> _reconciliationReasons = [
    'Hao hụt chế biến',
    'Hết hạn/Hỏng',
    'Thất thoát',
    'Nhập sai số liệu',
    'Khác',
  ];

  void _initializeAudits(List<InventoryIngredient> ingredients) {
    if (_auditRows.isNotEmpty) return;

    for (var ing in ingredients) {
      _auditRows.add({
        'ingredientId': ing.id,
        'name': ing.name,
        'unit': ing.unit,
        'theoreticalStock': ing.currentStock,
        'actualController': TextEditingController(text: ing.currentStock.toStringAsFixed(1)),
        'reason': 'Hao hụt chế biến',
      });
    }
  }

  void _submitReconciliation() {
    final List<Map<String, dynamic>> auditsPayload = [];

    for (var row in _auditRows) {
      final double theoretical = row['theoreticalStock'] as double;
      final double actual = double.tryParse(row['actualController'].text) ?? 0;
      final diff = actual - theoretical;

      if (diff != 0) {
        if (actual < 0) {
          TopNotification.show(context, message: 'Số lượng tồn thực tế của ${row['name']} không được nhỏ hơn 0', isError: true);
          return;
        }

        auditsPayload.add({
          'ingredientId': row['ingredientId'],
          'actualStock': actual,
          'reason': row['reason'],
        });
      }
    }

    if (auditsPayload.isEmpty) {
      TopNotification.show(context, message: 'Không có thay đổi chênh lệch nào được phát hiện', isError: true);
      return;
    }

    ref.read(inventoryProvider.notifier).reconcileStock(auditsPayload);
    TopNotification.show(context, message: 'Đã thực hiện cân đối tồn kho thành công');
    Navigator.pop(context);
  }

  @override
  void dispose() {
    for (var row in _auditRows) {
      row['actualController'].dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(inventoryProvider);
    _initializeAudits(state.ingredients);

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
          'Phiếu kiểm kho',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.onPrimary),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // ===== AUDITOR HEADER =====
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Container(
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
              child: const Row(
                children: [
                  Icon(Icons.person_outline, color: AppColors.textSecondary, size: 20),
                  SizedBox(width: 10),
                  Text(
                    'Người kiểm kê: Nguyễn Văn A',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                  ),
                ],
              ),
            ),
          ),

          // ===== LIST HEADER =====
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'ĐỐI CHIẾU SỐ LIỆU TỒN KHO',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),

          // ===== AUDIT LIST TABLE =====
          Expanded(
            child: ListView.separated(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: const EdgeInsets.all(16),
              itemCount: _auditRows.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final row = _auditRows[index];
                return _buildAuditItemRow(row);
              },
            ),
          ),

          // ===== CONFIRM BAR =====
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
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.textSecondary,
                        side: const BorderSide(color: AppColors.outlineVariant),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      child: const Text('Huỷ', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _submitReconciliation,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      child: const Text('Cân đối & cập nhật kho', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
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

  Widget _buildAuditItemRow(Map<String, dynamic> row) {
    final double theoretical = row['theoreticalStock'] as double;
    final double actual = double.tryParse(row['actualController'].text) ?? theoretical;
    final double diff = actual - theoretical;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.outlineVariant),
        boxShadow: const [
          BoxShadow(
            color: Color(0x04000000),
            blurRadius: 6,
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
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      row['name'],
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Sổ sách: ${theoretical.toStringAsFixed(1)} ${row['unit']}',
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // Actual input field
              SizedBox(
                width: 100,
                height: 38,
                child: Container(
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
                          controller: row['actualController'],
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          style: const TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.bold),
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
                            contentPadding: EdgeInsets.symmetric(vertical: 8),
                          ),
                        ),
                      ),
                      Text(
                        row['unit'],
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          if (diff != 0) ...[
            const SizedBox(height: 10),
            const Divider(height: 1, color: AppColors.outlineVariant),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Difference showcase
                Row(
                  children: [
                    const Text('Lệch: ', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                    Text(
                      '${diff > 0 ? '+' : ''}${diff.toStringAsFixed(1)} ${row['unit']}',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: diff > 0 ? AppColors.success : AppColors.error,
                      ),
                    ),
                  ],
                ),
                // Reason dropdown
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  height: 30,
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppColors.outlineVariant),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: row['reason'],
                      dropdownColor: Colors.white,
                      style: const TextStyle(color: AppColors.textPrimary, fontSize: 12),
                      items: _reconciliationReasons.map((reason) {
                        return DropdownMenuItem<String>(
                          value: reason,
                          child: Text(reason),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() {
                            row['reason'] = val;
                          });
                        }
                      },
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
