import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Widget chọn kích cỡ món ăn dùng ChoiceChip.
///
/// [sizeOptions]: danh sách `[{'id': String, 'name': String}]`
/// [selectedSizeId]: id size đang được chọn
/// [onSizeSelected]: callback trả về id size mới khi user chọn
class SizeSelector extends ConsumerWidget {
  final String? selectedSizeId;
  final List<Map<String, String>> sizeOptions;
  final void Function(String sizeId) onSizeSelected;

  const SizeSelector({
    super.key,
    required this.selectedSizeId,
    required this.sizeOptions,
    required this.onSizeSelected,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Chọn size:',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Color(0xFF6B7280),
          ),
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 8,
          runSpacing: 6,
          children: sizeOptions.map((opt) {
            final bool isSelected = opt['id'] == selectedSizeId;
            return GestureDetector(
              onTap: () => onSizeSelected(opt['id'] ?? ''),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFFEA580C)
                      : const Color(0xFFF9FAFB),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected
                        ? const Color(0xFFEA580C)
                        : const Color(0xFFE5E7EB),
                    width: 1.2,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: const Color(0xFFEA580C)
                                .withValues(alpha: 0.25),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          )
                        ]
                      : null,
                ),
                child: Text(
                  opt['name'] ?? '',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isSelected
                        ? Colors.white
                        : const Color(0xFF374151),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
