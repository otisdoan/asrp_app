import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import '../presentation/pages/auth/login_page.dart';
import '../presentation/pages/auth/register_page.dart';
import '../presentation/pages/auth/forgot_password_page.dart';
import '../presentation/pages/auth/reset_password_page.dart';
import '../presentation/pages/auth/onboarding_survey_page.dart';
import '../presentation/pages/auth/profile_page.dart';
import '../presentation/pages/auth/edit_profile_page.dart';
import '../presentation/pages/auth/branch_registration_page.dart';
import '../presentation/pages/staff/staff_home_page.dart';
import '../presentation/pages/staff/cashier_page.dart';
import '../presentation/pages/admin/admin_dashboard_page.dart';
import '../presentation/pages/admin/superadmin_dashboard_page.dart';
import '../presentation/pages/shop/home_page.dart';
import '../presentation/pages/shop/search_page.dart';
import '../presentation/pages/shop/favorite_shops_page.dart';
import '../presentation/pages/merchant/store_setup_page.dart';
import '../presentation/pages/merchant/menu_builder_page.dart';
import '../presentation/pages/merchant/staff_management_page.dart';
import '../providers/branch_registration_provider.dart';
import '../presentation/pages/shop/section_detail_page.dart';
import '../core/constants/app_constants.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);
  final isLoggedIn = authState.isAuthenticated;
  final user = authState.user;

  return GoRouter(
    initialLocation: AppConstants.routeHome,
    redirect: (context, state) {
      final path = state.uri.path;

      // 1. If logged in:
      if (isLoggedIn && user != null) {
        final role = user.role.toLowerCase();

        // Prevent going to login/register if already logged in
        if (path == AppConstants.routeLogin || path == AppConstants.routeRegister) {
          return AppConstants.routeHome;
        }

        // Protect admin and staff routes from unauthorized users
        if (role == 'customer') {
          // Customers not allowed in POS, Cashier, Admin/SuperAdmin dashboards, Staff Management, or Merchant Setup/Menu
          if (path == AppConstants.routeStaffHome || 
              path == AppConstants.routeCashier ||
              path == '/admin/dashboard' ||
              path == AppConstants.routeSuperAdminDashboard ||
              path == AppConstants.routeStaffManagement ||
              path == AppConstants.routeStoreSetup ||
              path == AppConstants.routeMenuBuilder) {
            return AppConstants.routeHome;
          }
        } else if (role == 'staff') {
          // Staff not allowed in Cashier, dashboards, Staff Management, or Merchant Setup/Menu
          if (path == AppConstants.routeCashier ||
              path == '/admin/dashboard' ||
              path == AppConstants.routeSuperAdminDashboard ||
              path == AppConstants.routeStaffManagement ||
              path == AppConstants.routeStoreSetup ||
              path == AppConstants.routeMenuBuilder) {
            return AppConstants.routeHome;
          }
        } else if (role == 'manager') {
          // Managers not allowed in Admin/SuperAdmin dashboards or Staff Management
          if (path == '/admin/dashboard' ||
              path == AppConstants.routeSuperAdminDashboard ||
              path == AppConstants.routeStaffManagement) {
            return AppConstants.routeHome;
          }
        } else if (role == 'admin') {
          // If admin has only 1 branch, redirect them from multi-branch SuperAdmin dashboard to single branch dashboard
          final registration = ref.read(branchRegistrationProvider);
          final hasMultipleBranches = registration.registeredBranches.length > 1;
          if (path == AppConstants.routeSuperAdminDashboard && !hasMultipleBranches) {
            return '/admin/dashboard';
          }
          if (path == '/admin/dashboard' && hasMultipleBranches) {
            return AppConstants.routeSuperAdminDashboard;
          }
        }
        // Admin (Chủ thương hiệu) and SuperAdmin are allowed to access all routes.
      } 
      
      // 2. If NOT logged in:
      else {
        // Guests not allowed in staff, cashier, admin, superadmin, or staff management pages
        if (path == AppConstants.routeStaffHome || 
            path == AppConstants.routeCashier ||
            path == '/admin/dashboard' ||
            path == AppConstants.routeSuperAdminDashboard ||
            path == AppConstants.routeStaffManagement) {
          return AppConstants.routeLogin;
        }
      }

      // Root redirect to home
      if (path == '/') {
        return AppConstants.routeHome;
      }
      return null;
    },
    routes: [
      // ===== Auth Routes =====
      GoRoute(
        path: AppConstants.routeLogin,
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: AppConstants.routeRegister,
        builder: (context, state) => const RegisterPage(),
      ),
      GoRoute(
        path: AppConstants.routeForgotPassword,
        builder: (context, state) => const ForgotPasswordPage(),
      ),
      GoRoute(
        path: AppConstants.routeResetPassword,
        builder: (context, state) => const ResetPasswordPage(),
      ),
      GoRoute(
        path: AppConstants.routeOnboarding,
        builder: (context, state) => const OnboardingSurveyPage(),
      ),
      GoRoute(
        path: AppConstants.routeStaffHome,
        builder: (context, state) => const StaffHomePage(),
      ),
      GoRoute(
        path: AppConstants.routeCashier,
        builder: (context, state) => const CashierPage(),
      ),
      GoRoute(
        path: '/admin/dashboard',
        builder: (context, state) => const AdminDashboardPage(),
      ),
      GoRoute(
        path: AppConstants.routeSuperAdminDashboard,
        builder: (context, state) => const SuperAdminDashboardPage(),
      ),
      // ===== Shop Routes =====
      GoRoute(
        path: AppConstants.routeHome,
        builder: (context, state) => const HomePage(),
      ),
      GoRoute(
        path: '/search',
        builder: (context, state) {
          final category = state.uri.queryParameters['category'];
          return SearchPage(initialCategory: category);
        },
      ),
      GoRoute(
        path: '/section-detail',
        builder: (context, state) {
          final type = state.uri.queryParameters['type'] ?? 'deals';
          final title = state.uri.queryParameters['title'] ?? '';
          return SectionDetailPage(type: type, title: title);
        },
      ),
      GoRoute(
        path: AppConstants.routeProfile,
        builder: (context, state) => const ProfilePage(),
      ),
      GoRoute(
        path: AppConstants.routeEditProfile,
        builder: (context, state) => const EditProfilePage(),
      ),
      GoRoute(
        path: AppConstants.routeBranchRegistration,
        builder: (context, state) => const BranchRegistrationPage(),
      ),
      GoRoute(
        path: AppConstants.routeFavoriteShops,
        builder: (context, state) => const FavoriteShopsPage(),
      ),
      GoRoute(
        path: AppConstants.routeStoreSetup,
        builder: (context, state) => const StoreSetupPage(),
      ),
      GoRoute(
        path: AppConstants.routeMenuBuilder,
        builder: (context, state) => const MenuBuilderPage(),
      ),
      GoRoute(
        path: AppConstants.routeStaffManagement,
        builder: (context, state) => const StaffManagementPage(),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Text('Page not found: ${state.error}'),
      ),
    ),
  );
});
