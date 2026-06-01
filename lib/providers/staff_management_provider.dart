import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/staff_member_model.dart';

class StaffManagementNotifier extends StateNotifier<List<StaffMemberModel>> {
  StaffManagementNotifier() : super(_initialStaff);

  // Initial rich mock staff datasets (prefilled high-fidelity)
  static final List<StaffMemberModel> _initialStaff = [
    StaffMemberModel(
      id: 'staff-4',
      fullName: 'Quản lý Nguyễn Văn C',
      phone: '0933333333',
      role: 'Admin',
      branchName: 'Quận 3',
      createdAt: DateTime.now().subtract(const Duration(days: 15)).toIso8601String(),
    ),
  ];

  /// Thêm nhân viên mới
  void addStaffMember(StaffMemberModel member) {
    state = [...state, member];
  }

  /// Cập nhật nhân viên
  void updateStaffMember(StaffMemberModel updatedMember) {
    state = [
      for (final member in state)
        if (member.id == updatedMember.id) updatedMember else member
    ];
  }

  /// Xóa nhân viên
  void deleteStaffMember(String id) {
    state = state.where((member) => member.id != id).toList();
  }
}

// Riverpod Provider
final staffManagementProvider =
    StateNotifierProvider<StaffManagementNotifier, List<StaffMemberModel>>(
  (ref) => StaffManagementNotifier(),
);
