class ApiConstants {
  ApiConstants._();

  // Base URL (Switch between Local and Production)
  // Android Emulator default loopback: http://10.0.2.2:5100/api
  // iOS Simulator / Web: http://localhost:5100/api
  // Physical Device: http://<YOUR_LOCAL_IP>:5100/api (e.g. 10.12.26.38)
  static const String baseUrl = 'http://10.0.2.2:5100/api';
  // Production URL:
  // static const String baseUrl = 'https://api.asrp.io.vn/api';

  // Domain URL without /api prefix (used for SignalR Hubs)
  static String get domainUrl => baseUrl.replaceAll(RegExp(r'/api/?$'), '');

  // SignalR Hubs
  static String get chatAgentHubUrl => '$domainUrl/hubs/chat-agent';
  static String get notificationHubUrl => '$domainUrl/hubs/notifications';

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
