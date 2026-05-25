import '../../core/network/dio_client.dart';
import '../../core/constants/api_constants.dart';
import '../models/auth_response_model.dart';
import 'package:dio/dio.dart';

class AuthRepository {
  final DioClient _dioClient = DioClient();

  Map<String, dynamic> _extractData(dynamic rawData) {
    if (rawData is Map<String, dynamic>) {
      if (rawData['data'] is Map<String, dynamic>) {
        return rawData['data'] as Map<String, dynamic>;
      }
      return rawData;
    }
    return <String, dynamic>{};
  }

  /// Đăng ký tài khoản mới bằng idToken từ Firebase và password.
  Future<AuthResponseModel> register({
    required String idToken,
    required String password,
  }) async {
    print('[AuthRepository] Requesting register to ${ApiConstants.register}');
    print(
        '[AuthRepository] Payload: { idToken: ${idToken.length > 50 ? "${idToken.substring(0, 30)}... [Length: ${idToken.length}]" : idToken} }');
    final response = await _dioClient.dio.post(
      ApiConstants.register,
      data: {
        'idToken': idToken,
        'password': password,
      },
    );
    print('[AuthRepository] Response status code: ${response.statusCode}');
    print('[AuthRepository] Response data: ${response.data}');

    return AuthResponseModel.fromJson(_extractData(response.data));
  }

  /// Đăng nhập tài khoản bằng số điện thoại và mật khẩu.
  Future<AuthResponseModel> login({
    required String phone,
    required String password,
  }) async {
    print('[AuthRepository] Requesting login to ${ApiConstants.login}');
    print(
        '[AuthRepository] Payload: { phoneNumber: "$phone", password: "$password" }');
    final response = await _dioClient.dio.post(
      ApiConstants.login,
      data: {
        'phoneNumber': phone,
        'password': password,
      },
    );

    return AuthResponseModel.fromJson(_extractData(response.data));
  }

  Future<Response<dynamic>> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    return _dioClient.dio.post(
      ApiConstants.changePassword,
      data: {
        'currentPassword': currentPassword,
        'newPassword': newPassword,
        'confirmPassword': confirmPassword,
      },
    );
  }

  Future<Response<dynamic>> forgotPassword({
    required String phoneOrEmail,
  }) async {
    return _dioClient.dio.post(
      ApiConstants.forgotPassword,
      data: {
        'phoneOrEmail': phoneOrEmail,
      },
    );
  }

  Future<Response<dynamic>> verifyOtpForReset({
    required String phoneOrEmail,
    required String otp,
  }) async {
    return _dioClient.dio.post(
      ApiConstants.otpVerify,
      data: {
        'phoneOrEmail': phoneOrEmail,
        'otp': otp,
      },
    );
  }

  Future<Response<dynamic>> resetPassword({
    required String otp,
    required String newPassword,
    required String phone,
  }) async {
    return _dioClient.dio.post(
      ApiConstants.resetPassword,
      data: {
        'otp': otp,
        'newPassword': newPassword,
        'phone': phone,
      },
    );
  }

  /// Thong bao backend huy refresh token.
  Future<void> logout(String refreshToken) async {
    await _dioClient.dio.post(
      ApiConstants.logout,
      data: {
        'refreshToken': refreshToken,
      },
    );
  }
}
