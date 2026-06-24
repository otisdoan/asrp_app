import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/staff_member_model.dart';
import '../core/network/dio_client.dart';

class StaffManagementNotifier extends StateNotifier<List<StaffMemberModel>> {
  final DioClient _dioClient = DioClient();
  String? _branchId;

  StaffManagementNotifier() : super([]);

  String? get activeBranchId => _branchId;

  void setStaffList(List<StaffMemberModel> list) {
    state = list;
  }

  /// Helper to fetch employees for a specific branch as a list
  Future<List<StaffMemberModel>> getStaffListForBranch(String branchId) async {
    try {
      final response = await _dioClient.dio.get('/branches/$branchId/employees?pageSize=100');
      final rawData = response.data;
      final payload = rawData['data'] ?? rawData;
      final listData = payload['items'] as List<dynamic>? ?? payload as List<dynamic>? ?? [];
      
      return listData
          .map((item) => StaffMemberModel.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('[StaffManagementNotifier] Error getting staff for branch $branchId: $e');
      return [];
    }
  }

  /// Tải danh sách nhân viên của chi nhánh và lưu vào state
  Future<void> fetchStaffMembers(String branchId) async {
    _branchId = branchId;
    try {
      final list = await getStaffListForBranch(branchId);
      state = list;
    } catch (e) {
      print('[StaffManagementNotifier] Error fetching staff: $e');
      rethrow;
    }
  }

  /// Thêm nhân viên mới
  Future<void> addStaffMember(StaffMemberModel member, {String? targetBranchId}) async {
    final branchId = targetBranchId ?? _branchId ?? member.branchName;
    if (branchId.isEmpty) return;
    
    try {
      if (member.role == 'Manager') {
        await _dioClient.dio.post(
          '/branches/$branchId/managers',
          data: {
            'fullName': member.fullName,
            'phoneNumber': member.phone,
            'password': 'Staff@123456', // default password since UI does not have password field
          },
        );
      } else {
        await _dioClient.dio.post(
          '/branches/$branchId/staff',
          data: {
            'branchId': branchId,
            'fullName': member.fullName,
            'phoneNumber': member.phone,
            'password': 'Staff@123456', // default password
          },
        );
      }
      final refreshId = _branchId ?? branchId;
      await fetchStaffMembers(refreshId);
    } catch (e) {
      print('[StaffManagementNotifier] Error adding staff: $e');
      rethrow;
    }
  }

  /// Cập nhật nhân viên
  Future<void> updateStaffMember(StaffMemberModel updatedMember, {String? targetBranchId}) async {
    final branchId = targetBranchId ?? _branchId ?? updatedMember.branchName;
    if (branchId.isEmpty) return;
    
    try {
      await _dioClient.dio.put(
        '/branches/$branchId/employees/${updatedMember.id}',
        data: {
          'fullName': updatedMember.fullName,
          'phoneNumber': updatedMember.phone,
        },
      );
      final refreshId = _branchId ?? branchId;
      await fetchStaffMembers(refreshId);
    } catch (e) {
      print('[StaffManagementNotifier] Error updating staff: $e');
      rethrow;
    }
  }

  /// Toggle trạng thái hoạt động (Active/Inactive) của nhân viên
  Future<void> toggleStaffStatus(String userId, bool isActive) async {
    if (_branchId == null) return;
    try {
      await _dioClient.dio.patch(
        '/branches/$_branchId/employees/$userId/status',
        data: {
          'isActive': isActive,
        },
      );
      await fetchStaffMembers(_branchId!);
    } catch (e) {
      print('[StaffManagementNotifier] Error toggling staff status: $e');
      rethrow;
    }
  }

  /// Vô hiệu hóa nhân viên (tương đương Xóa trên UI FE)
  Future<void> deleteStaffMember(String id) async {
    await toggleStaffStatus(id, false);
  }
}

// Riverpod Provider
final staffManagementProvider =
    StateNotifierProvider<StaffManagementNotifier, List<StaffMemberModel>>(
  (ref) => StaffManagementNotifier(),
);
