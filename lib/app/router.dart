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
          if (role == 'staff') return AppConstants.routeStaffHome;
          if (role == 'manager') return AppConstants.routeCashier;
          if (role == 'admin') return '/admin/dashboard';
          if (role == 'superadmin') return AppConstants.routeSuperAdminDashboard;
          return AppConstants.routeHome;
        }

        // Role-based route protection
        if (role == 'staff') {
          // Staff only allowed in staff pos page and profile pages
          if (path != AppConstants.routeStaffHome &&
              path != AppConstants.routeProfile &&
              path != AppConstants.routeEditProfile &&
              path != AppConstants.routeBranchRegistration &&
              path != AppConstants.routeStoreSetup &&
              path != AppConstants.routeMenuBuilder) {
            return AppConstants.routeStaffHome;
          }
        } else if (role == 'manager') {
          // Managers allowed in cashier page, staff pos page, and profile pages
          if (path != AppConstants.routeCashier &&
              path != AppConstants.routeStaffHome &&
              path != AppConstants.routeProfile &&
              path != AppConstants.routeEditProfile &&
              path != AppConstants.routeBranchRegistration &&
              path != AppConstants.routeStoreSetup &&
              path != AppConstants.routeMenuBuilder) {
            return AppConstants.routeCashier;
          }
        } else if (role == 'admin') {
          // Admins allowed in admin dashboard page, cashier page, staff pos page, and profile pages
          if (path != '/admin/dashboard' &&
              path != AppConstants.routeCashier &&
              path != AppConstants.routeStaffHome &&
              path != AppConstants.routeProfile &&
              path != AppConstants.routeEditProfile &&
              path != AppConstants.routeBranchRegistration &&
              path != AppConstants.routeStoreSetup &&
              path != AppConstants.routeMenuBuilder) {
            return '/admin/dashboard';
          }
        } else if (role == 'superadmin') {
          // SuperAdmins allowed in superadmin dashboard, and profile pages
          if (path != AppConstants.routeSuperAdminDashboard &&
              path != AppConstants.routeProfile &&
              path != AppConstants.routeEditProfile &&
              path != AppConstants.routeBranchRegistration &&
              path != AppConstants.routeStoreSetup &&
              path != AppConstants.routeMenuBuilder) {
            return AppConstants.routeSuperAdminDashboard;
          }
        } else if (role == 'customer') {
          // Customers not allowed in staff, cashier, admin, or superadmin pages
          if (path == AppConstants.routeStaffHome || 
              path == AppConstants.routeCashier ||
              path == '/admin/dashboard' ||
              path == AppConstants.routeSuperAdminDashboard) {
            return AppConstants.routeHome;
          }
        }
      } 
      
      // 2. If NOT logged in:
      else {
        // Guests not allowed in staff, cashier, admin, or superadmin pages
        if (path == AppConstants.routeStaffHome || 
            path == AppConstants.routeCashier ||
            path == '/admin/dashboard' ||
            path == AppConstants.routeSuperAdminDashboard) {
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
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Text('Page not found: ${state.error}'),
      ),
    ),
  );
});
