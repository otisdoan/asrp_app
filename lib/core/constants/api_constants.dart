class ApiConstants {
  ApiConstants._();

  static const String baseUrl =
      'http://api.asrp.io.vn/api';

  // Auth
  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String logout = '/auth/logout';
  static const String refresh = '/auth/refresh';
  static const String me = '/auth/me';
  static const String otpSend = '/auth/otp/send';
  static const String otpVerify = '/auth/otp/verify';
  static const String forgotPassword = '/auth/forgot-password';
  static const String resetPassword = '/auth/reset-password';
  static const String changePassword = '/auth/change-password';
  static const String googleAuth = '/auth/google';

  // Users
  static const String profile = '/users/profile';
  static const String userList = '/users';
  static String userDetail(String id) => '/users/$id';

  // Categories
  static const String categories = '/categories';
}
