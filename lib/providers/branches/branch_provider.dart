import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/branches/repositories/branch_repository.dart';
import '../../data/models/branch_model.dart';

// Provide BranchRepository instance
final branchRepositoryProvider = Provider<BranchRepository>((ref) {
  return BranchRepository();
});

// Provide list of all branches
final branchListProvider = FutureProvider<List<BranchListItemModel>>((ref) async {
  final repository = ref.read(branchRepositoryProvider);
  return repository.getBranches();
});

// Provide nearby branches (needs location in real app, hardcoded here for testing)
final nearbyBranchListProvider = FutureProvider<List<BranchListItemModel>>((ref) async {
  final repository = ref.read(branchRepositoryProvider);
  // Temporary hardcoded lat/lng for Hanoi, in a real app this comes from Geolocator
  return repository.getNearbyBranches(latitude: 21.028511, longitude: 105.804817);
});

// Provide branch detail by id
final branchDetailProvider = FutureProvider.family<BranchDetailModel, String>((ref, id) async {
  final repository = ref.read(branchRepositoryProvider);
  return repository.getBranchDetail(id);
});
