import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
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

  /// Kiểm tra số điện thoại có tồn tại trong hệ thống chưa
  Future<Map<String, dynamic>?> checkPhoneExists(String phone) async {
    try {
      final response = await _dioClient.dio.get('/users/check-phone/$phone');
      final data = response.data;
      if (data['exists'] == true) {
        return data;
      }
      return null;
    } catch (e) {
      print('[StaffManagementNotifier] Error checking phone: $e');
      return null;
    }
  }

  /// Helper to fetch employees for a specific branch as a list
  Future<List<StaffMemberModel>> getStaffListForBranch(String branchId) async {
    try {
      final response = await _dioClient.dio.get('/branches/$branchId/employees?pageSize=100&isActive=true');
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
  Future<void> addStaffMember(StaffMemberModel member, {String? targetBranchId, String? password, String? existingUserId}) async {
    final branchId = targetBranchId ?? _branchId ?? member.branchName;
    if (branchId.isEmpty) return;
    
    try {
      if (existingUserId != null && existingUserId.isNotEmpty) {
        // Luồng Bổ nhiệm (Assign)
        try {
          if (member.role == 'Manager') {
            await _dioClient.dio.post(
              '/branches/$branchId/managers/assign',
              data: {
                'userId': existingUserId,
              },
            );
          } else {
            await _dioClient.dio.post(
              '/branches/$branchId/staff/assign',
              data: {
                'userId': existingUserId,
              },
            );
          }
        } catch (e) {
          // Chỉ tự động kích hoạt lại nếu lỗi thực sự là do tài khoản đang bị vô hiệu hóa
          bool isInactiveError = false;
          if (e is DioException) {
            final data = e.response?.data;
            if (data is Map<String, dynamic>) {
              final detail = (data['detail'] ?? data['Detail'] ?? data['message'] ?? '').toString();
              if (detail.contains('Inactive users cannot be assigned')) {
                isInactiveError = true;
              }
            }
          }

          if (!isInactiveError) {
            rethrow; // Rethrow lỗi gốc (ví dụ: lỗi Admin/SuperAdmin không được bổ nhiệm)
          }

          try {
            await _dioClient.dio.patch(
              '/branches/$branchId/employees/$existingUserId/status',
              data: {
                'isActive': true,
              },
            );
            // Thử lại luồng bổ nhiệm
            if (member.role == 'Manager') {
              await _dioClient.dio.post(
                '/branches/$branchId/managers/assign',
                data: {
                  'userId': existingUserId,
                },
              );
            } else {
              await _dioClient.dio.post(
                '/branches/$branchId/staff/assign',
                data: {
                  'userId': existingUserId,
                },
              );
            }
          } catch (_) {
            rethrow;
          }
        }
      } else {
        // Luồng Tạo mới (Không còn dùng trực tiếp nhưng giữ tương thích cấu trúc)
        final resolvedPassword = (password != null && password.isNotEmpty) ? password : 'Staff@123456';
        if (member.role == 'Manager') {
          await _dioClient.dio.post(
            '/branches/$branchId/managers',
            data: {
              'fullName': member.fullName,
              'phoneNumber': member.phone,
              'password': resolvedPassword,
            },
          );
        } else {
          await _dioClient.dio.post(
            '/branches/$branchId/staff',
            data: {
              'branchId': branchId,
              'fullName': member.fullName,
              'phoneNumber': member.phone,
              'password': resolvedPassword,
            },
          );
        }
      }
      final refreshId = _branchId ?? branchId;
      await fetchStaffMembers(refreshId);
    } catch (e) {
      print('[StaffManagementNotifier] Error adding staff: $e');
      rethrow;
    }
  }

  /// Cập nhật nhân viên
  Future<void> updateStaffMember(
    StaffMemberModel updatedMember, {
    required String originalBranchId,
    required String targetBranchId,
    required String originalRole,
  }) async {
    if (originalBranchId.isEmpty || targetBranchId.isEmpty) return;

    try {
      // 1. Cập nhật thông tin cơ bản (Họ tên, SĐT) tại chi nhánh cũ
      await _dioClient.dio.put(
        '/branches/$originalBranchId/employees/${updatedMember.id}',
        data: {
          'fullName': updatedMember.fullName,
          'phoneNumber': updatedMember.phone,
        },
      );

      // 2. Nếu thay đổi Chi nhánh hoặc Vai trò: tiến hành bổ nhiệm sang vai trò/chi nhánh mới
      if (originalBranchId != targetBranchId || originalRole != updatedMember.role) {
        if (updatedMember.role == 'Manager') {
          await _dioClient.dio.post(
            '/branches/$targetBranchId/managers/assign',
            data: {
              'userId': updatedMember.id,
            },
          );
        } else {
          await _dioClient.dio.post(
            '/branches/$targetBranchId/staff/assign',
            data: {
              'userId': updatedMember.id,
            },
          );
        }
      }

      // 3. Làm mới danh sách nhân sự của chi nhánh hiện tại
      final refreshId = _branchId ?? targetBranchId;
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
