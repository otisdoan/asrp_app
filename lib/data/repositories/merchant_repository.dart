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

  /// Lấy cấu hình chi nhánh (GET /api/branches/{branchId}/settings)
  Future<Map<String, dynamic>> getBranchSettings(String branchId) async {
    final token = _dioClient.accessToken;
    print('[MerchantRepository] --- START API GET BRANCH SETTINGS ---');
    print('[MerchantRepository] Target URL: ${_dioClient.dio.options.baseUrl}/branches/$branchId/settings');
    print('[MerchantRepository] Access Token in DioClient: ${token != null ? (token.length > 25 ? "${token.substring(0, 15)}... (len: ${token.length})" : token) : "NULL"}');

    try {
      final response = await _dioClient.dio.get(
        '/branches/$branchId/settings',
      );
      print('[MerchantRepository] Response status code: ${response.statusCode}');
      print('[MerchantRepository] Response data: ${response.data}');
      print('[MerchantRepository] --- END API GET BRANCH SETTINGS (SUCCESS) ---');
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      print('[MerchantRepository] --- API ERROR DETECTED ---');
      print('[MerchantRepository] Status code: ${e.response?.statusCode}');
      print('[MerchantRepository] Response error data: ${e.response?.data}');
      print('[MerchantRepository] Error message: ${e.message}');
      print('[MerchantRepository] --- END API GET BRANCH SETTINGS (ERROR) ---');
      
      final serverDetail = e.response?.data?['detail'] ?? e.response?.data?['message'];
      if (serverDetail != null) {
        throw Exception('Lỗi từ máy chủ: $serverDetail');
      }
      rethrow;
    }
  }

  /// Cập nhật cấu hình chi nhánh (PATCH /api/branches/{branchId}/settings)
  Future<void> updateBranchSettings(String branchId, Map<String, dynamic> payload) async {
    final token = _dioClient.accessToken;
    print('[MerchantRepository] --- START API UPDATE BRANCH SETTINGS ---');
    print('[MerchantRepository] Target URL: ${_dioClient.dio.options.baseUrl}/branches/$branchId/settings');
    print('[MerchantRepository] Access Token in DioClient: ${token != null ? (token.length > 25 ? "${token.substring(0, 15)}... (len: ${token.length})" : token) : "NULL"}');
    print('[MerchantRepository] Payload data: $payload');

    try {
      final response = await _dioClient.dio.patch(
        '/branches/$branchId/settings',
        data: payload,
      );
      print('[MerchantRepository] Response status code: ${response.statusCode}');
      print('[MerchantRepository] Response data: ${response.data}');
      print('[MerchantRepository] --- END API UPDATE BRANCH SETTINGS (SUCCESS) ---');
    } on DioException catch (e) {
      print('[MerchantRepository] --- API ERROR DETECTED ---');
      print('[MerchantRepository] Status code: ${e.response?.statusCode}');
      print('[MerchantRepository] Response error data: ${e.response?.data}');
      print('[MerchantRepository] Error message: ${e.message}');
      print('[MerchantRepository] --- END API UPDATE BRANCH SETTINGS (ERROR) ---');
      
      final serverDetail = e.response?.data?['detail'] ?? e.response?.data?['message'];
      if (serverDetail != null) {
        throw Exception('Lỗi từ máy chủ: $serverDetail');
      }
      rethrow;
    }
  }

  /// Tải ảnh lên server (POST /api/storage/images)
  Future<String> uploadImage(String filePath, String folder) async {
    final token = _dioClient.accessToken;
    print('[MerchantRepository] --- START API UPLOAD IMAGE ---');
    print('[MerchantRepository] Target URL: ${_dioClient.dio.options.baseUrl}/storage/images');
    print('[MerchantRepository] Access Token in DioClient: ${token != null ? (token.length > 25 ? "${token.substring(0, 15)}... (len: ${token.length})" : token) : "NULL"}');
    print('[MerchantRepository] File path: $filePath, Folder: $folder');

    try {
      final fileName = filePath.split('/').last;
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(filePath, filename: fileName),
        'folder': folder,
      });

      final response = await _dioClient.dio.post(
        '/storage/images',
        data: formData,
      );

      print('[MerchantRepository] Response status code: ${response.statusCode}');
      print('[MerchantRepository] Response data: ${response.data}');
      print('[MerchantRepository] --- END API UPLOAD IMAGE (SUCCESS) ---');

      // The backend returns StorageUploadResult: { imageKey, imageUrl }
      final data = response.data['data'] ?? response.data;
      final imageUrl = data['imageUrl'] as String;
      return imageUrl;
    } on DioException catch (e) {
      print('[MerchantRepository] --- API ERROR DETECTED ---');
      print('[MerchantRepository] Status code: ${e.response?.statusCode}');
      print('[MerchantRepository] Response error data: ${e.response?.data}');
      print('[MerchantRepository] Error message: ${e.message}');
      print('[MerchantRepository] --- END API UPLOAD IMAGE (ERROR) ---');
      
      final serverDetail = e.response?.data?['detail'] ?? e.response?.data?['message'];
      if (serverDetail != null) {
        throw Exception('Lỗi từ máy chủ: $serverDetail');
      }
      rethrow;
    }
  }
}
