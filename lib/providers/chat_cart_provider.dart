import 'package:flutter_riverpod/flutter_riverpod.dart';

// ---------------------------------------------------------------------------
// Model
// ---------------------------------------------------------------------------

/// Đại diện cho một kích cỡ khả dụng của món ăn.
class MenuItemSize {
  final String id;
  final String name;
  final double price;
  final bool isDefault;

  const MenuItemSize({
    required this.id,
    required this.name,
    required this.price,
    this.isDefault = false,
  });

  factory MenuItemSize.fromJson(Map<String, dynamic> json) => MenuItemSize(
        id: json['id'] as String? ?? json['sizeId'] as String? ?? '',
        name: json['name'] as String? ?? json['sizeName'] as String? ?? '',
        price: (json['price'] as num?)?.toDouble() ?? 0.0,
        isDefault: json['isDefault'] as bool? ?? false,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'price': price,
        'isDefault': isDefault,
      };
}

/// Đại diện cho một món ăn trong giỏ hàng Chat AI.
///
/// Lưu trữ sẵn `availableSizes` để Bottom Sheet render ChoiceChip
/// mà không cần gọi API lại.
class ChatCartItem {
  final String menuItemId;
  final String branchId;
  final String name;
  final String imageUrl;

  /// Giá gốc (base price). Giá thực tế sẽ lấy từ size được chọn nếu có.
  final double basePrice;
  final int quantity;
  final String selectedSizeId;
  final String? selectedSizeName;

  /// Danh sách size khả dụng — được nạp cùng lúc khi thêm món vào giỏ.
  final List<MenuItemSize> availableSizes;

  const ChatCartItem({
    required this.menuItemId,
    required this.branchId,
    required this.name,
    this.imageUrl = '',
    required this.basePrice,
    this.quantity = 1,
    required this.selectedSizeId,
    this.selectedSizeName,
    this.availableSizes = const [],
  });

  /// Giá hiệu quả: nếu có size được chọn và size đó có price > 0 thì dùng price đó,
  /// ngược lại dùng basePrice.
  double get effectivePrice {
    if (selectedSizeId.isNotEmpty) {
      try {
        final size =
            availableSizes.firstWhere((s) => s.id == selectedSizeId);
        if (size.price > 0) return size.price;
      } catch (_) {}
    }
    return basePrice;
  }

  ChatCartItem copyWith({
    int? quantity,
    String? selectedSizeId,
    String? selectedSizeName,
    List<MenuItemSize>? availableSizes,
    String? imageUrl,
  }) {
    return ChatCartItem(
      menuItemId: menuItemId,
      branchId: branchId,
      name: name,
      imageUrl: imageUrl ?? this.imageUrl,
      basePrice: basePrice,
      quantity: quantity ?? this.quantity,
      selectedSizeId: selectedSizeId ?? this.selectedSizeId,
      selectedSizeName: selectedSizeName ?? this.selectedSizeName,
      availableSizes: availableSizes ?? this.availableSizes,
    );
  }
}

// ---------------------------------------------------------------------------
// Notifier
// ---------------------------------------------------------------------------

class ChatCartNotifier extends StateNotifier<List<ChatCartItem>> {
  ChatCartNotifier() : super([]);

  /// Helper xác định Size ID mặc định:
  /// 1. Nếu availableSizes rỗng -> ''
  /// 2. Size có isDefault == true
  /// 3. Size có name/label chứa "M" hoặc "Vừa" (case-insensitive)
  /// 4. Fallback: ID của phần tử đầu tiên
  String _determineDefaultSizeId(List<MenuItemSize> availableSizes) {
    if (availableSizes.isEmpty) return '';

    // 1. Tìm size có isDefault == true
    for (final size in availableSizes) {
      if (size.isDefault) return size.id;
    }

    // 2. Tìm size chứa "M" hoặc "Vừa" (không phân biệt hoa thường)
    for (final size in availableSizes) {
      final lower = size.name.toLowerCase();
      if (lower.contains('m') || lower.contains('vừa')) {
        return size.id;
      }
    }

    // 3. Fallback lấy phần tử đầu tiên
    return availableSizes.first.id;
  }

  String? _determineDefaultSizeName(List<MenuItemSize> availableSizes, String sizeId) {
    if (sizeId.isEmpty || availableSizes.isEmpty) return null;
    for (final size in availableSizes) {
      if (size.id == sizeId) return size.name;
    }
    return null;
  }

  // ── Core update (tăng/giảm/thêm) ──────────────────────────────────────────

  /// Thêm / bớt món theo [delta].
  /// Tự động xác định selectedSizeId mặc định nếu không được truyền vào.
  void updateItem(
    String menuItemId,
    String branchId,
    String name,
    double price,
    int delta, {
    String? sizeId,
    String? sizeName,
    String? imageUrl,
    List<MenuItemSize>? availableSizes,
  }) {
    // Đổi chi nhánh: Nếu thêm món từ chi nhánh khác -> tự động làm sạch giỏ hàng cũ và thêm món từ chi nhánh mới
    if (delta > 0 && state.isNotEmpty) {
      final currentBranchId = state.first.branchId;
      if (branchId != currentBranchId) {
        state = [];
      }
    }

    final sizes = availableSizes ?? [];
    final resolvedSizeId = (sizeId != null && sizeId.isNotEmpty)
        ? sizeId
        : _determineDefaultSizeId(sizes);
    final resolvedSizeName = sizeName ?? _determineDefaultSizeName(sizes, resolvedSizeId);

    final stateCopy = [...state];
    final index = stateCopy.indexWhere((item) =>
        item.menuItemId == menuItemId &&
        item.branchId == branchId &&
        item.selectedSizeId == resolvedSizeId);

    if (index != -1) {
      final newQuantity = stateCopy[index].quantity + delta;
      if (newQuantity <= 0) {
        stateCopy.removeAt(index);
      } else {
        stateCopy[index] = stateCopy[index].copyWith(quantity: newQuantity);
      }
    } else if (delta > 0) {
      stateCopy.add(ChatCartItem(
        menuItemId: menuItemId,
        branchId: branchId,
        name: name,
        imageUrl: imageUrl ?? '',
        basePrice: price,
        quantity: delta,
        selectedSizeId: resolvedSizeId,
        selectedSizeName: resolvedSizeName,
        availableSizes: sizes,
      ));
    }
    state = stateCopy;
  }

  // ── Thay đổi size (với merge logic) ───────────────────────────────────────

  /// Thay đổi size của một món.
  ///
  /// Nếu trong giỏ đã có item cùng menuItemId + branchId + **newSizeId** →
  /// cộng dồn số lượng rồi xóa item cũ.
  /// Nếu chưa có → cập nhật selectedSizeId của item hiện tại.
  void changeItemSize(
    String menuItemId,
    String branchId,
    String newSizeId,
    String? newSizeName,
  ) {
    final stateCopy = [...state];

    // Tìm item nguồn (item đang cần đổi size)
    final sourceIdx = stateCopy.indexWhere(
      (item) =>
          item.menuItemId == menuItemId && item.branchId == branchId,
    );
    if (sourceIdx == -1) return;

    // Kiểm tra đã có biến thể target size chưa
    final targetIdx = stateCopy.indexWhere(
      (item) =>
          item.menuItemId == menuItemId &&
          item.branchId == branchId &&
          item.selectedSizeId == newSizeId,
    );

    if (targetIdx != -1 && targetIdx != sourceIdx) {
      // Merge: cộng dồn số lượng vào target, xóa source
      final mergedQuantity =
          stateCopy[targetIdx].quantity + stateCopy[sourceIdx].quantity;
      stateCopy[targetIdx] =
          stateCopy[targetIdx].copyWith(quantity: mergedQuantity);
      stateCopy.removeAt(sourceIdx);
    } else if (targetIdx == -1) {
      // Chưa có biến thể này → cập nhật size trên source
      stateCopy[sourceIdx] = stateCopy[sourceIdx].copyWith(
        selectedSizeId: newSizeId,
        selectedSizeName: newSizeName,
      );
    }
    // Trường hợp targetIdx == sourceIdx: đã là size đó rồi, không làm gì
    state = stateCopy;
  }

  // ── Thay đổi số lượng theo size cụ thể ───────────────────────────────────

  /// Tăng/giảm số lượng cho biến thể (menuItemId + branchId + sizeId).
  void updateItemQuantity(
    String menuItemId,
    String branchId,
    String sizeId,
    int delta,
  ) {
    final stateCopy = [...state];
    final index = stateCopy.indexWhere((item) =>
        item.menuItemId == menuItemId &&
        item.branchId == branchId &&
        item.selectedSizeId == sizeId);

    if (index == -1) return;
    final newQty = stateCopy[index].quantity + delta;
    if (newQty <= 0) {
      stateCopy.removeAt(index);
    } else {
      stateCopy[index] = stateCopy[index].copyWith(quantity: newQty);
    }
    state = stateCopy;
  }

  // ── Utilities ─────────────────────────────────────────────────────────────

  void clearCart() => state = [];

  double get totalPrice =>
      state.fold(0.0, (sum, item) => sum + (item.effectivePrice * item.quantity));

  /// Alias cho totalPrice — tương thích với code snippet của DineX-AI
  double getTotalPrice() => totalPrice;

  int get totalItems =>
      state.fold(0, (sum, item) => sum + item.quantity);

  /// Trả về JSON list đính kèm vào payload gửi lên AI Backend.
  List<Map<String, dynamic>> toAiContextJson() {
    bool isValidGuid(String id) {
      return RegExp(r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$').hasMatch(id);
    }

    return state
        .map((item) => {
              'menuItemId': isValidGuid(item.menuItemId) ? item.menuItemId : '00000000-0000-0000-0000-000000000000',
              'branchId': isValidGuid(item.branchId) ? item.branchId : '00000000-0000-0000-0000-000000000000',
              'name': item.name,
              'quantity': item.quantity,
              'selectedSizeId': (item.selectedSizeId.isNotEmpty && isValidGuid(item.selectedSizeId)) ? item.selectedSizeId : null,
            })
        .toList();
  }
}

// ---------------------------------------------------------------------------
// Provider
// ---------------------------------------------------------------------------

final chatCartProvider =
    StateNotifierProvider<ChatCartNotifier, List<ChatCartItem>>((ref) {
  return ChatCartNotifier();
});
