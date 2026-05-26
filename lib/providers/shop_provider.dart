import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/branch_model.dart';
import 'branch_provider.dart';

// ===== Branch Provider =====
// Keep this provider simple to avoid circular initialization.
final selectedBranchProvider = StateProvider<String>(
  (ref) => '',
);

final branchSelectionSyncProvider = Provider<void>((ref) {
  ref.listen<AsyncValue<List<BranchListItemModel>>>(
    branchesFutureProvider,
    (previous, next) {
      next.whenData((branches) {
        if (branches.isEmpty) {
          return;
        }

        final currentBranchId = ref.read(selectedBranchProvider);
        if (currentBranchId.isNotEmpty) {
          final hasCurrentBranch = branches.any(
            (branch) =>
                branch.id == currentBranchId ||
                branch.branchId == currentBranchId,
          );
          if (hasCurrentBranch) {
            return;
          }
        }

        final defaultBranchId = branches.first.branchId ?? branches.first.id;
        ref.read(selectedBranchProvider.notifier).state = defaultBranchId;
      });
    },
    fireImmediately: true,
  );
});

// ===== Category Provider =====
final selectedCategoryProvider = StateProvider<String>(
  (ref) => 'Tất cả',
);

// ===== Search Provider =====
final searchQueryProvider = StateProvider<String>(
  (ref) => '',
);

// ===== Menu Sort Provider =====
final menuSortProvider = StateProvider<String>(
  (ref) => 'Phổ biến nhất',
);

// ===== Menu Page Provider =====
final menuCurrentPageProvider = StateProvider<int>(
  (ref) => 1,
);

// ===== Product Detail Provider =====
// Holds the slug of the currently opened product (null = closed)
final selectedProductSlugProvider = StateProvider<String?>(
  (ref) => null,
);
