import '../../core/network/dio_client.dart';
import '../../core/constants/api_constants.dart';
import '../models/auth_response_model.dart';

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
