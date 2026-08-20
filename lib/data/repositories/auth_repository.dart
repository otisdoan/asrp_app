import '../../core/network/dio_client.dart';
import '../../core/constants/api_constants.dart';
import '../models/auth_response_model.dart';
import '../models/user_model.dart';

class AuthRepository {
  final DioClient _dioClient = DioClient();

  /// Kiểm tra số điện thoại đã tồn tại trên hệ thống chưa
  Future<bool> checkPhoneExists(String phone) async {
    try {
      String formattedPhone = phone.trim();
      if (formattedPhone.startsWith('0')) {
        formattedPhone = '+84${formattedPhone.substring(1)}';
      }
      final response = await _dioClient.dio.get('/auth/check-phone/$formattedPhone');
      if (response.data is Map<String, dynamic>) {
        return response.data['exists'] == true;
      }
      return false;
    } catch (e) {
      print('[AuthRepository] checkPhoneExists error: $e');
      rethrow;
    }
  }

  /// Đăng ký tài khoản mới bằng idToken từ Firebase, displayName và password.
  Future<AuthResponseModel> register({
    required String idToken,
    required String displayName,
    required String password,
  }) async {
    print('[AuthRepository] Requesting register to ${ApiConstants.register}');
    final response = await _dioClient.dio.post(
      ApiConstants.register,
      data: {
        'idToken': idToken,
        'displayName': displayName.isEmpty ? 'Người dùng' : displayName,
        'password': password,
      },
    );
    print('[AuthRepository] Response status code: ${response.statusCode}');

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
    String formattedPhone = phone.trim();
    if (formattedPhone.startsWith('0')) {
      formattedPhone = '+84${formattedPhone.substring(1)}';
    }

    print('[AuthRepository] Requesting login to ${ApiConstants.login}');
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

  /// Tải thông tin hồ sơ cá nhân mới nhất từ Server
  Future<UserModel?> fetchProfile() async {
    try {
      print('[AuthRepository] Requesting fetchProfile to ${ApiConstants.profile}');
      final response = await _dioClient.dio.get(ApiConstants.profile);

      final rawData = response.data;
      Map<String, dynamic> data = {};
      if (rawData is Map<String, dynamic>) {
        if (rawData['data'] is Map<String, dynamic>) {
          data = rawData['data'] as Map<String, dynamic>;
        } else {
          data = rawData;
        }
      }
      return UserModel.fromJson(data);
    } catch (e) {
      print('[AuthRepository] fetchProfile error: $e');
      return null;
    }
  }

  /// Cập nhật thông tin cá nhân lên Server
  Future<UserModel?> updateProfile({
    required String fullName,
    String? email,
    String? gender,
    String? address,
  }) async {
    print('[AuthRepository] Updating profile to ${ApiConstants.profile}');
    final response = await _dioClient.dio.put(
      ApiConstants.profile,
      data: {
        'fullName': fullName,
        if (email != null && email.isNotEmpty) 'email': email,
        if (gender != null) 'gender': gender,
        if (address != null) 'address': address,
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
    return UserModel.fromJson(data);
  }

  /// Đăng xuất khỏi backend (thu hồi Refresh Token)
  Future<void> logout(String refreshToken) async {
    try {
      print('[AuthRepository] Revoking refresh token at ${ApiConstants.logout}');
      await _dioClient.dio.post(
        ApiConstants.logout,
        data: {'refreshToken': refreshToken},
      );
    } catch (e) {
      print('[AuthRepository] Logout error: $e');
    }
  }

  /// Đổi mật khẩu
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    print('[AuthRepository] Requesting changePassword to ${ApiConstants.changePassword}');
    await _dioClient.dio.post(
      ApiConstants.changePassword,
      data: {
        'currentPassword': currentPassword,
        'newPassword': newPassword,
        'confirmPassword': confirmPassword,
      },
    );
  }

  /// Quên mật khẩu - Yêu cầu gửi token reset
  Future<void> forgotPassword(String phone) async {
    String formattedPhone = phone.trim();
    if (formattedPhone.startsWith('0')) {
      formattedPhone = '+84${formattedPhone.substring(1)}';
    }
    print('[AuthRepository] Requesting forgotPassword to ${ApiConstants.forgotPassword}');
    await _dioClient.dio.post(
      ApiConstants.forgotPassword,
      data: {'phoneNumber': formattedPhone},
    );
  }

  /// Đặt lại mật khẩu với token
  Future<void> resetPassword({
    required String phone,
    required String token,
    required String newPassword,
    required String confirmPassword,
  }) async {
    String formattedPhone = phone.trim();
    if (formattedPhone.startsWith('0')) {
      formattedPhone = '+84${formattedPhone.substring(1)}';
    }
    print('[AuthRepository] Requesting resetPassword to ${ApiConstants.resetPassword}');
    await _dioClient.dio.post(
      ApiConstants.resetPassword,
      data: {
        'phoneNumber': formattedPhone,
        'token': token,
        'newPassword': newPassword,
        'confirmPassword': confirmPassword,
      },
    );
  }
}
