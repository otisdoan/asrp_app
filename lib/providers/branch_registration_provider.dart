import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/repositories/merchant_repository.dart';

class BranchRegistrationData {
  final String status; // 'none' | 'pending' | 'approved'
  final String brandName;
  final String category;
  final String branchName;
  final String phone;
  final String address;
  final String gps;
  final String taxCode;
  final String bankName;
  final String bankAccount;
  final String bankOwner;
  final List<Map<String, String>> registeredBranches;

  const BranchRegistrationData({
    this.status = 'none',
    this.brandName = '',
    this.category = '',
    this.branchName = '',
    this.phone = '',
    this.address = '',
    this.gps = '',
    this.taxCode = '',
    this.bankName = '',
    this.bankAccount = '',
    this.bankOwner = '',
    this.registeredBranches = const [],
  });

  BranchRegistrationData copyWith({
    String? status,
    String? brandName,
    String? category,
    String? branchName,
    String? phone,
    String? address,
    String? gps,
    String? taxCode,
    String? bankName,
    String? bankAccount,
    String? bankOwner,
    List<Map<String, String>>? registeredBranches,
  }) {
    return BranchRegistrationData(
      status: status ?? this.status,
      brandName: brandName ?? this.brandName,
      category: category ?? this.category,
      branchName: branchName ?? this.branchName,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      gps: gps ?? this.gps,
      taxCode: taxCode ?? this.taxCode,
      bankName: bankName ?? this.bankName,
      bankAccount: bankAccount ?? this.bankAccount,
      bankOwner: bankOwner ?? this.bankOwner,
      registeredBranches: registeredBranches ?? this.registeredBranches,
    );
  }
}

class BranchRegistrationNotifier extends StateNotifier<BranchRegistrationData> {
  final MerchantRepository _merchantRepository = MerchantRepository();

  BranchRegistrationNotifier() : super(const BranchRegistrationData());

  /// Đăng ký thương hiệu và chi nhánh đầu tiên (Chuyển sang trạng thái chờ duyệt)
  Future<void> submitFirstBranch({
    required String brandName,
    required String category,
    required String branchName,
    required String phone,
    required String address,
    required String gps,
    required String taxCode,
    required String bankName,
    required String bankAccount,
    required String bankOwner,
  }) async {
    try {
      await _merchantRepository.submitMerchantApplication(
        brandName: brandName,
        category: category,
        taxCode: taxCode,
        bankName: bankName,
        bankAccount: bankAccount,
        bankOwner: bankOwner,
        branchName: branchName,
        phone: phone,
        address: address,
      );

      state = state.copyWith(
        status: 'pending',
        brandName: brandName,
        category: category,
        branchName: branchName,
        phone: phone,
        address: address,
        gps: gps,
        taxCode: taxCode,
        bankName: bankName,
        bankAccount: bankAccount,
        bankOwner: bankOwner,
        registeredBranches: [
          {
            'branchName': branchName,
            'phone': phone,
            'address': address,
            'gps': gps,
          }
        ],
      );
    } catch (e) {
      print('[BranchRegistrationNotifier] Error submitting branch application: $e');
      rethrow;
    }
  }

  /// Đăng ký thêm một chi nhánh mới (khi thương hiệu đã được duyệt)
  void registerNewBranch({
    required String branchName,
    required String phone,
    required String address,
    required String gps,
  }) {
    final updatedBranches = List<Map<String, String>>.from(state.registeredBranches)
      ..add({
        'branchName': branchName,
        'phone': phone,
        'address': address,
        'gps': gps,
      });

    state = state.copyWith(
      registeredBranches: updatedBranches,
    );
  }

  /// Mock phê duyệt hồ sơ từ Admin (chuyển trạng thái sang approved)
  void approveBrand() {
    state = state.copyWith(status: 'approved');
  }

  /// Reset trạng thái đăng ký (để phục vụ test lại từ đầu)
  void reset() {
    state = const BranchRegistrationData();
  }
}

final branchRegistrationProvider =
    StateNotifierProvider<BranchRegistrationNotifier, BranchRegistrationData>(
  (ref) => BranchRegistrationNotifier(),
);
