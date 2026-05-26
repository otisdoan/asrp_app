import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/branch_model.dart';
import '../data/repositories/branch_repository.dart';

final branchRepositoryProvider = Provider<BranchRepository>((ref) {
  return BranchRepository();
});

final branchesFutureProvider =
    FutureProvider<List<BranchListItemModel>>((ref) async {
  final branches = await ref.read(branchRepositoryProvider).getBranches();
  print(
      '[Audit Branch] 5. FutureProvider đã nhận được ${branches.length} chi nhánh.');
  return branches;
});
