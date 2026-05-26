import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/api_constants.dart';
import '../../core/network/dio_client.dart';
import '../models/user_model.dart';

class UserRepository {
  final DioClient _dioClient = DioClient();
  Future<UserModel> getProfile() async {
    try {
      final response = await _dioClient.dio.get(ApiConstants.profile);
      // Removed profile sync debug log

      final rawData = response.data;
      final profileData = rawData is Map<String, dynamic> &&
              rawData['data'] is Map<String, dynamic>
          ? rawData['data'] as Map<String, dynamic>
          : rawData as Map<String, dynamic>;

      final user = UserModel.fromJson(profileData);
      // Removed profile sync debug log
      return user;
    } on DioException {
      rethrow;
    }
  }

  Future<Response<dynamic>> updateProfile(
      {String? fullName, String? email}) async {
    try {
      return await _dioClient.dio.put(
        ApiConstants.profile,
        data: {
          'fullName': fullName,
          'email': email,
        },
      );
    } on DioException {
      rethrow;
    }
  }

  Future<String?> uploadAvatar(String imagePath) async {
    final fileName = imagePath.split(RegExp(r'[\\/]')).last;
    final formData = FormData.fromMap({
      'File': await MultipartFile.fromFile(
        imagePath,
        filename: fileName,
      ),
    });

    final response = await _dioClient.dio.post(
      ApiConstants.profileAvatar,
      data: formData,
      options: Options(
        contentType: Headers.multipartFormDataContentType,
      ),
    );

    final rawData = response.data;
    if (rawData is Map<String, dynamic>) {
      final data = rawData['data'] is Map<String, dynamic>
          ? rawData['data'] as Map<String, dynamic>
          : rawData;

      final avatarUrl =
          data['avatar'] ?? data['avatarUrl'] ?? data['url'] ?? data['path'];
      if (avatarUrl != null) {
        return avatarUrl.toString();
      }
    }

    return null;
  }
}

final userRepositoryProvider =
    Provider<UserRepository>((ref) => UserRepository());
