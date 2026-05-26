import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/menu_item_model.dart';
import '../data/repositories/menu_repository.dart';
import 'shop_provider.dart';

final menuRepositoryProvider = Provider<MenuRepository>((ref) {
  return MenuRepository();
});

final branchMenuItemsProvider =
    FutureProvider<List<MenuItemModel>>((ref) async {
  final branchId = ref.watch(selectedBranchProvider);

  if (branchId.isEmpty) {
    print('[Audit Menu] Chưa có branchId, bỏ qua gọi API Menu');
    return [];
  }

  print(
      '[Audit Menu] Phát hiện đổi Chi nhánh thành $branchId. Bắt đầu fetch Menu...');
  return ref.read(menuRepositoryProvider).getMenuItems(branchId);
});
