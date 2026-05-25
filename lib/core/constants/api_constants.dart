class ApiConstants {
  ApiConstants._();

  static const String baseUrl =
      'http://api.asrp.io.vn'; // Change for production

  // Auth
  static const String login = '/api/auth/app/login';
  static const String register = '/api/auth/app/register';
  static const String logout = '/api/auth/app/logout';
  static const String refresh = '/api/auth/app/refresh';
  static const String me = '/auth/me';
  static const String otpSend = '/api/auth/app/otp/send';
  static const String otpVerify = '/api/auth/app/otp/verify';
  static const String forgotPassword = '/api/auth/app/forgot-password';
  static const String resetPassword = '/api/auth/app/reset-password';
  static const String changePassword = '/api/auth/change-password';
  static const String googleAuth = '/auth/google';

  // Users
  static const String profile = '/api/users/profile';
  static const String profileAvatar = '/api/users/profile/avatar';
  static const String userList = '/users';
  static String userDetail(String id) => '/users/$id';

  // Categories
  static const String categories = '/categories';
}
