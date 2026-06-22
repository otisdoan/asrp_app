import 'package:dio/dio.dart';
import '../../core/network/dio_client.dart';

class MerchantRepository {
  final DioClient _dioClient = DioClient();

  /// Đăng ký thương hiệu và chi nhánh đầu tiên (POST /api/merchant-applications)
  Future<void> submitMerchantApplication({
    required String brandName,
    required String category,
    required String taxCode,
    required String bankName,
    required String bankAccount,
    required String bankOwner,
    required String branchName,
    required String phone,
    required String address,
  }) async {
    final payload = {
      "brandName": brandName,
      "category": category,
      "taxCode": taxCode,
      "bankName": bankName,
      "bankAccount": bankAccount,
      "bankOwner": bankOwner,
      "firstBranch": {
        "name": branchName,
        "phone": phone,
        "address": address,
      }
    };

    final token = _dioClient.accessToken;
    print('[MerchantRepository] --- START API SUBMIT MERCHANT APPLICATION ---');
    print('[MerchantRepository] Target URL: ${_dioClient.dio.options.baseUrl}/merchant-applications');
    print('[MerchantRepository] Access Token in DioClient: ${token != null ? (token.length > 25 ? "${token.substring(0, 15)}... (len: ${token.length})" : token) : "NULL"}');
    print('[MerchantRepository] Payload data: $payload');
    
    try {
      final response = await _dioClient.dio.post(
        '/merchant-applications',
        data: payload,
      );
      print('[MerchantRepository] Response success status: ${response.statusCode}');
      print('[MerchantRepository] Response data: ${response.data}');
      print('[MerchantRepository] --- END API SUBMIT MERCHANT APPLICATION (SUCCESS) ---');
    } on DioException catch (e) {
      print('[MerchantRepository] --- API ERROR DETECTED ---');
      print('[MerchantRepository] Status code: ${e.response?.statusCode}');
      print('[MerchantRepository] Response error data: ${e.response?.data}');
      print('[MerchantRepository] Request headers sent: ${e.requestOptions.headers}');
      print('[MerchantRepository] Request payload sent: ${e.requestOptions.data}');
      print('[MerchantRepository] Error message: ${e.message}');
      print('[MerchantRepository] --- END API SUBMIT MERCHANT APPLICATION (ERROR) ---');
      
      if (e.response?.statusCode == 401) {
        String errorMsg = 'Phiên đăng nhập không hợp lệ hoặc đã hết hạn (401 Unauthorized).';
        if (token != null && token.contains('mock')) {
          errorMsg += '\nLưu ý: Bạn đang đăng nhập bằng tài khoản giả định (Mock). Vui lòng đăng xuất và đăng ký/đăng nhập bằng tài khoản thật để lưu trữ dữ liệu lên server.';
        }
        throw Exception(errorMsg);
      }
      
      final serverDetail = e.response?.data?['detail'] ?? e.response?.data?['message'];
      if (serverDetail != null) {
        throw Exception('Lỗi từ máy chủ: $serverDetail');
      }
      
      rethrow;
    }
  }
}
