import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import '../presentation/pages/auth/login_page.dart';
import '../presentation/pages/auth/register_page.dart';
import '../presentation/pages/auth/forgot_password_page.dart';
import '../presentation/pages/auth/reset_password_page.dart';
import '../presentation/pages/auth/onboarding_survey_page.dart';
import '../presentation/pages/staff/staff_home_page.dart';
import '../presentation/pages/staff/cashier_page.dart';
import '../presentation/pages/shop/home_page.dart';
import '../core/constants/app_constants.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);

  return GoRouter(
    initialLocation: AppConstants.routeHome,
    redirect: (context, state) {
      // Currently no redirect logic - all routes accessible
      // In production: redirect to login if not authenticated for protected routes
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
      // ===== Shop Routes =====
      GoRoute(
        path: AppConstants.routeHome,
        builder: (context, state) => const HomePage(),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Text('Page not found: ${state.error}'),
      ),
    ),
  );
});
