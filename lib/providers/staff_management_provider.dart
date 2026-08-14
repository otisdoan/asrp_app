import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../data/models/staff_member_model.dart';
import '../core/network/dio_client.dart';
import 'auth_provider.dart';

class StaffManagementNotifier extends StateNotifier<List<StaffMemberModel>> {
  final DioClient _dioClient = DioClient();
  final String? _currentUserRole;
  final String? _currentUserBranchId;
  String? _branchId;

  StaffManagementNotifier({
    String? currentUserRole,
    String? currentUserBranchId,
  })  : _currentUserRole = currentUserRole?.toLowerCase(),
        _currentUserBranchId = currentUserBranchId,
        super([]);

  String? get activeBranchId => _branchId;

  bool get _canManageManagers =>
      _currentUserRole == 'superadmin' || _currentUserRole == 'admin';
  bool get _canManageStaff =>
      _canManageManagers || _currentUserRole == 'manager';
  bool get _isManager => _currentUserRole == 'manager';

  String _authorizedBranchId(String branchId) {
    if (!_canManageStaff) {
      throw StateError('Current user is not authorized to manage branch staff.');
    }
    if (_isManager) {
      final managerBranchId = _currentUserBranchId;
      if (managerBranchId == null || managerBranchId.isEmpty) {
        throw StateError('Manager branch scope is missing.');
      }
      if (branchId.isNotEmpty && branchId != managerBranchId) {
        throw StateError('Manager can only manage staff in their own branch.');
      }
      return managerBranchId;
    }
    return branchId;
  }

  void _ensureRoleAllowed(String role) {
    final normalizedRole = role.trim().toLowerCase();
    if (normalizedRole == 'manager' && !_canManageManagers) {
      throw StateError('Current user cannot manage managers.');
    }
    if (normalizedRole != 'staff' && normalizedRole != 'manager') {
      throw StateError('Only Manager and Staff branch roles can be managed.');
    }
  }

  bool _isManagerRole(String role) => role.trim().toLowerCase() == 'manager';

  List<StaffMemberModel> _visibleStaff(List<StaffMemberModel> list) {
    if (_isManager) {
      return list
          .where((item) => item.role.trim().toLowerCase() == 'staff')
          .toList();
    }
    return list;
  }

  void setStaffList(List<StaffMemberModel> list) {
    state = _visibleStaff(list);
  }

  /// Kiểm tra số điện thoại có tồn tại trong hệ thống chưa
  Future<Map<String, dynamic>?> checkPhoneExists(String phone) async {
    try {
      final response = await _dioClient.dio.get('/users/check-phone/$phone');
      final data = response.data;
      if (data is Map<String, dynamic>) {
        if (data['exists'] == true) {
          return data;
        }
        if (data['exists'] == false) {
          return null;
        }
      }
      return null;
    } catch (e) {
      print('[StaffManagementNotifier] Error checking phone: $e');
      rethrow;
    }
  }

  /// Helper to fetch employees for a specific branch as a list
  Future<List<StaffMemberModel>> getStaffListForBranch(String branchId) async {
    final authorizedBranchId = _authorizedBranchId(branchId);
    try {
      final response = await _dioClient.dio.get('/branches/$authorizedBranchId/employees?pageSize=100&isActive=true');
      final rawData = response.data;
      final payload = rawData['data'] ?? rawData;
      final listData = payload['items'] as List<dynamic>? ?? payload as List<dynamic>? ?? [];
      
      return _visibleStaff(listData
          .map((item) => StaffMemberModel.fromJson(item as Map<String, dynamic>))
          .toList());
    } catch (e) {
      print('[StaffManagementNotifier] Error getting staff for branch $authorizedBranchId: $e');
      return [];
    }
  }

  /// Tải danh sách nhân viên của chi nhánh và lưu vào state
  Future<void> fetchStaffMembers(String branchId) async {
    final authorizedBranchId = _authorizedBranchId(branchId);
    _branchId = authorizedBranchId;
    try {
      final list = await getStaffListForBranch(authorizedBranchId);
      state = list;
    } catch (e) {
      print('[StaffManagementNotifier] Error fetching staff: $e');
      rethrow;
    }
  }

  /// Thêm nhân viên mới
  Future<void> addStaffMember(StaffMemberModel member, {String? targetBranchId, String? password, String? existingUserId}) async {
    _ensureRoleAllowed(member.role);
    final branchId = _authorizedBranchId(targetBranchId ?? _branchId ?? member.branchName);
    if (branchId.isEmpty) return;
    
    try {
      if (existingUserId != null && existingUserId.isNotEmpty) {
        // Luồng Bổ nhiệm (Assign)
        try {
          if (_isManagerRole(member.role)) {
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
            if (_isManagerRole(member.role)) {
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
        if (_isManagerRole(member.role)) {
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
    _ensureRoleAllowed(originalRole);
    _ensureRoleAllowed(updatedMember.role);
    final authorizedOriginalBranchId = _authorizedBranchId(originalBranchId);
    final authorizedTargetBranchId = _authorizedBranchId(targetBranchId);
    if (authorizedOriginalBranchId.isEmpty || authorizedTargetBranchId.isEmpty) return;

    try {
      // 1. Cập nhật thông tin cơ bản (Họ tên, SĐT) tại chi nhánh cũ
      await _dioClient.dio.put(
        '/branches/$authorizedOriginalBranchId/employees/${updatedMember.id}',
        data: {
          'fullName': updatedMember.fullName,
          'phoneNumber': updatedMember.phone,
        },
      );

      // 2. Nếu thay đổi Chi nhánh hoặc Vai trò: tiến hành bổ nhiệm sang vai trò/chi nhánh mới
      if (authorizedOriginalBranchId != authorizedTargetBranchId || originalRole != updatedMember.role) {
        if (_isManagerRole(updatedMember.role)) {
          await _dioClient.dio.post(
            '/branches/$authorizedTargetBranchId/managers/assign',
            data: {
              'userId': updatedMember.id,
            },
          );
        } else {
          await _dioClient.dio.post(
            '/branches/$authorizedTargetBranchId/staff/assign',
            data: {
              'userId': updatedMember.id,
            },
          );
        }
      }

      // 3. Làm mới danh sách nhân sự của chi nhánh hiện tại
      final refreshId = _branchId ?? authorizedTargetBranchId;
      await fetchStaffMembers(refreshId);
    } catch (e) {
      print('[StaffManagementNotifier] Error updating staff: $e');
      rethrow;
    }
  }

  /// Toggle trạng thái hoạt động (Active/Inactive) của nhân viên
  Future<void> toggleStaffStatus(String userId, bool isActive,
      {String? targetBranchId}) async {
    final branchId = _authorizedBranchId(targetBranchId ?? _branchId ?? '');
    if (branchId.isEmpty) return;
    if (_isManager) {
      final target = state.where((item) => item.id == userId).toList();
      if (target.isEmpty ||
          target.first.role.trim().toLowerCase() != 'staff') {
        throw StateError(
            'Manager can only update visible staff in their own branch.');
      }
    }
    try {
      await _dioClient.dio.patch(
        '/branches/$branchId/employees/$userId/status',
        data: {
          'isActive': isActive,
        },
      );
      await fetchStaffMembers(branchId);
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
  (ref) {
    final user = ref.watch(currentUserProvider);
    return StaffManagementNotifier(
      currentUserRole: user?.role,
      currentUserBranchId: user?.branchId,
    );
  },
);
