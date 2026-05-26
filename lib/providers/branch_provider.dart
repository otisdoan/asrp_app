import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import '../data/models/branch_model.dart';
import '../data/repositories/branch_repository.dart';

final branchRepositoryProvider = Provider<BranchRepository>((ref) {
  return BranchRepository();
});

final branchesFutureProvider = FutureProvider<List<BranchListItemModel>>((ref) async {
  final repository = ref.watch(branchRepositoryProvider);
  return repository.getBranches();
});

final branchDetailFutureProvider = FutureProvider.family<BranchDetailModel, String>((ref, id) async {
  final repository = ref.watch(branchRepositoryProvider);
  return repository.getBranchDetail(id);
});

final userLocationProvider = StateProvider<Position?>((ref) => null);
