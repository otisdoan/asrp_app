import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../providers/inventory_provider.dart';

class InventoryLedgerPage extends ConsumerStatefulWidget {
  const InventoryLedgerPage({super.key});

  @override
  ConsumerState<InventoryLedgerPage> createState() => _InventoryLedgerPageState();
}

class _InventoryLedgerPageState extends ConsumerState<InventoryLedgerPage> {
  String _selectedType = 'Tất cả';

  final List<String> _types = ['Tất cả', 'Import', 'Deduction', 'Adjustment'];

  String _formatTime(DateTime dt) {
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  String _formatDate(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(inventoryProvider);

    final filteredTransactions = state.transactions.where((tx) {
      if (_selectedType == 'Tất cả') return true;
      return tx.type == _selectedType;
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppColors.onPrimary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Lịch sử biến động kho',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.onPrimary),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // ===== HORIZONTAL TYPE FILTER =====
          Container(
            height: 54,
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              itemCount: _types.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final type = _types[index];
                final isSelected = type == _selectedType;
                
                String displayName = 'Tất cả';
                if (type == 'Import') displayName = 'Nhập kho';
                else if (type == 'Deduction') displayName = 'Bán hàng';
                else if (type == 'Adjustment') displayName = 'Kiểm kê';

                return ChoiceChip(
                  label: Text(displayName),
                  selected: isSelected,
                  showCheckmark: false,
                  onSelected: (val) {
                    if (val) {
                      setState(() {
                        _selectedType = type;
                      });
                    }
                  },
                  selectedColor: AppColors.primary,
                  backgroundColor: Colors.white,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : AppColors.textSecondary,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    fontSize: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(
                      color: isSelected ? AppColors.primary : AppColors.outlineVariant,
                    ),
                  ),
                );
              },
            ),
          ),

          // ===== LIST VIEWS =====
          Expanded(
            child: filteredTransactions.isEmpty
                ? const Center(
                    child: Text(
                      'Không tìm thấy giao dịch nào',
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: filteredTransactions.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final tx = filteredTransactions[index];
                      return _buildTransactionRow(tx);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionRow(InventoryTransaction tx) {
    Color typeColor = AppColors.textSecondary;
    String typeLabel = 'Khác';
    
    if (tx.type == 'Import') {
      typeColor = AppColors.success;
      typeLabel = 'Nhập hàng';
    } else if (tx.type == 'Deduction') {
      typeColor = const Color(0xFF1976D2);
      typeLabel = 'Trừ kho';
    } else if (tx.type == 'Adjustment') {
      typeColor = AppColors.primary;
      typeLabel = 'Kiểm kê';
    }

    final isPositive = tx.quantityChange > 0;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.outlineVariant),
        boxShadow: const [
          BoxShadow(
            color: Color(0x04000000),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Time column
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _formatTime(tx.timestamp),
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 4),
              Text(
                _formatDate(tx.timestamp),
                style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
              ),
            ],
          ),
          const SizedBox(width: 20),
          // Info column
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tx.ingredientName,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                ),
                const SizedBox(height: 6),
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: typeColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: typeColor.withValues(alpha: 0.3)),
                      ),
                      child: Text(
                        typeLabel,
                        style: TextStyle(color: typeColor, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ),
                    Text(
                      tx.reference,
                      style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.bold),
                    ),
                    if (tx.reason.isNotEmpty && tx.reason != 'Bán hàng' && tx.reason != 'Nhập hàng') ...[
                      const Text('•', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                      Text(
                        tx.reason,
                        style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Quantity change
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${isPositive ? '+' : ''}${tx.quantityChange.toStringAsFixed(tx.quantityChange % 1 == 0 ? 0 : 1)} ${tx.unit}',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  color: isPositive ? AppColors.success : AppColors.error,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Tồn: ${tx.afterStock.toStringAsFixed(tx.afterStock % 1 == 0 ? 0 : 1)} ${tx.unit}',
                style: const TextStyle(fontSize: 10, color: AppColors.textSecondary, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
