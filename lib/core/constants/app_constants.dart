class AppConstants {
  AppConstants._();

  // Routes
  static const String routeLogin = '/login';
  static const String routeRegister = '/register';
  static const String routeForgotPassword = '/forgot-password';
  static const String routeResetPassword = '/reset-password';
  static const String routeOnboarding = '/onboarding';
  static const String routeStaffHome = '/staff';
  static const String routeCashier = '/cashier';
  static const String routeSplash = '/';
  static const String routeHome = '/home';
  static const String routeProfile = '/profile';
  static const String routeEditProfile = '/profile/edit';
  static const String routeBranchRegistration = '/profile/branch-registration';
  static const String routeFavoriteShops = '/shops/favorite';
  static const String routeSuperAdminDashboard = '/superadmin/dashboard';
  static const String routeStoreSetup = '/merchant/store-setup';
  static const String routeMenuBuilder = '/merchant/menu-builder';
  static const String routeStaffManagement = '/merchant/staff-management';

  // Storage keys
  static const String storageKeyAccessToken = 'access_token';
  static const String storageKeyRefreshToken = 'refresh_token';
  static const String storageKeyUser = 'asrp_user';

  // App info
  static const String appName = 'DineX';
  static const String appTagline = 'Nền tảng nhà hàng thông minh';

  // Branches
  static const List<String> branches = [
    'Chi nhánh Quận 1 · Tầng 1',
    'Chi nhánh Quận 3 · Tầng trệt',
    'Chi nhánh Phú Nhuận · Tầng 2',
  ];

  // Cart
  static const int maxQuantity = 20;
  static const int minQuantity = 1;

  // OTP
  static const int otpLength = 6;
  static const int otpCooldownSeconds = 60;
  static const int otpExpirySeconds = 300;
  static const String mockOtp = '123456'; // Remove in production
}
