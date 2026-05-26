import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/constants/app_constants.dart';

// ===== Branch Provider =====
final selectedBranchProvider = StateProvider<String>(
  (ref) => AppConstants.branches[0],
);

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

// ===== Menu Item Detail Provider =====
// Holds the slug of the currently opened menu item (null = closed)
final selectedMenuItemSlugProvider = StateProvider<String?>(
  (ref) => null,
);
