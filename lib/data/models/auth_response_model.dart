import 'user_model.dart';

class AuthResponseModel {
  final UserModel user;
  final String accessToken;

  const AuthResponseModel({
    required this.user,
    required this.accessToken,
  });

  factory AuthResponseModel.fromJson(Map<String, dynamic> json) {
    return AuthResponseModel(
      user: UserModel.fromJson(json['user'] as Map<String, dynamic>? ?? <String, dynamic>{}),
      accessToken: json['accessToken']?.toString() ?? '',
    );
  }
}

class ApiResponse<T> {
  final bool success;
  final String message;
  final T data;

  const ApiResponse({
    required this.success,
    required this.message,
    required this.data,
  });
}
