class ApiConstants {
  ApiConstants._();

  static const String baseUrl = 'https://api.asrp.io.vn/api'; // Change for production

  // Auth
  static const String login = '/auth/app/login';
  static const String register = '/auth/app/register';
  static const String logout = '/auth/app/logout';
  static const String refresh = '/auth/app/refresh';
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

  // Branches
  static const String branches = '/branches';
  static String branchDetail(String id) => '/branches/$id';
  static String branchMenu(String branchId) => '/branches/$branchId/menu';
}
