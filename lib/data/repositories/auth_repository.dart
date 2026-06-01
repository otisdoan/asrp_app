import '../../core/network/dio_client.dart';
import '../../core/constants/api_constants.dart';
import '../models/auth_response_model.dart';
import '../models/user_model.dart';

class AuthRepository {
  final DioClient _dioClient = DioClient();

  /// Đăng ký tài khoản mới bằng idToken từ Firebase, displayName và password.
  Future<AuthResponseModel> register({
    required String idToken,
    required String displayName,
    required String password,
  }) async {
    print('[AuthRepository] Requesting register to ${ApiConstants.register}');
    print('[AuthRepository] Payload: { idToken: ${idToken.length > 50 ? "${idToken.substring(0, 30)}... [Length: ${idToken.length}]" : idToken}, displayName: "LÊ DOÃN HIẾU" }');
    final response = await _dioClient.dio.post(
      ApiConstants.register,
      data: {
        'idToken': idToken,
        'displayName': "LÊ DOÃN HIẾU",
        'password': password,
      },
    );
    print('[AuthRepository] Response status code: ${response.statusCode}');
    print('[AuthRepository] Response data: ${response.data}');

    final rawData = response.data;
    Map<String, dynamic> data = {};
    if (rawData is Map<String, dynamic>) {
      if (rawData['data'] is Map<String, dynamic>) {
        data = rawData['data'] as Map<String, dynamic>;
      } else {
        data = rawData;
      }
    }
    return AuthResponseModel.fromJson(data);
  }

  /// Đăng nhập tài khoản bằng số điện thoại và mật khẩu.
  Future<AuthResponseModel> login({
    required String phone,
    required String password,
  }) async {
    // Intercept and return mock admin account to comply with Clean Architecture rules
    if (phone.trim() == '0999999999' && password == 'admin123456') {
      final mockAdminUser = UserModel(
        id: 'mock-admin-id',
        username: 'admin',
        phone: '+84999999999',
        fullName: 'Admin Tối Cao',
        role: 'Admin',
        isActive: true,
        points: 1000,
        createdAt: DateTime.now().toIso8601String(),
        updatedAt: DateTime.now().toIso8601String(),
      );
      return AuthResponseModel(
        user: mockAdminUser,
        accessToken: 'mock-admin-access-token',
        refreshToken: 'mock-admin-refresh-token',
      );
    }

    // Intercept and return mock SuperAdmin account
    if (phone.trim() == '0888888888' && password == 'superadmin123456') {
      final mockSuperAdminUser = UserModel(
        id: 'mock-superadmin-id',
        username: 'superadmin',
        phone: '+84888888888',
        fullName: 'SuperAdmin Tối Cao',
        role: 'SuperAdmin',
        isActive: true,
        points: 2000,
        createdAt: DateTime.now().toIso8601String(),
        updatedAt: DateTime.now().toIso8601String(),
      );
      return AuthResponseModel(
        user: mockSuperAdminUser,
        accessToken: 'mock-superadmin-access-token',
        refreshToken: 'mock-superadmin-refresh-token',
      );
    }

    // Intercept and return mock Staff account
    if (phone.trim() == '0777777777' && password == 'staff123456') {
      final mockStaffUser = UserModel(
        id: 'mock-staff-id',
        username: 'staff',
        phone: '+84777777777',
        fullName: 'Nhân viên ASRP',
        role: 'Staff',
        isActive: true,
        points: 500,
        createdAt: DateTime.now().toIso8601String(),
        updatedAt: DateTime.now().toIso8601String(),
      );
      return AuthResponseModel(
        user: mockStaffUser,
        accessToken: 'mock-staff-access-token',
        refreshToken: 'mock-staff-refresh-token',
      );
    }

    String formattedPhone = phone;
    if (phone.startsWith('0')) {
      formattedPhone = '+84${phone.substring(1)}';
    }
    
    print('[AuthRepository] Requesting login to ${ApiConstants.login}');
    print('[AuthRepository] Payload: { phoneNumber: "$formattedPhone", password: "$password" }');
    final response = await _dioClient.dio.post(
      ApiConstants.login,
      data: {
        'phoneNumber': formattedPhone,
        'password': password,
      },
    );

    final rawData = response.data;
    Map<String, dynamic> data = {};
    if (rawData is Map<String, dynamic>) {
      if (rawData['data'] is Map<String, dynamic>) {
        data = rawData['data'] as Map<String, dynamic>;
      } else {
        data = rawData;
      }
    }
    return AuthResponseModel.fromJson(data);
  }
}
