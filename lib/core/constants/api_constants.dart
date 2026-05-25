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
  static const String otpSend = '/auth/otp/send';
  static const String otpVerify = '/auth/otp/verify';
  static const String forgotPassword = '/auth/forgot-password';
  static const String resetPassword = '/auth/reset-password';
  static const String changePassword = '/auth/change-password';
  static const String googleAuth = '/auth/google';

  // Users
  static const String profile = '/api/users/profile';
  static const String profileAvatar = '/api/users/profile/avatar';
  static const String userList = '/users';
  static String userDetail(String id) => '/users/$id';

  // Categories
  static const String categories = '/categories';
}
