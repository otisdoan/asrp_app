import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../providers/auth_provider.dart';

/// Register Page — professional, clean design.
/// Two tabs: Khách hàng (phone + password + confirm → OTP) and Nhân viên (phone + password + confirm → done).
/// Follows RULE: UI-only widgets, AppColors 100%, responsive.
class RegisterPage extends ConsumerStatefulWidget {
  const RegisterPage({super.key});
  @override
  ConsumerState<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends ConsumerState<RegisterPage> {
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _passwordVisible = false;
  bool _confirmVisible = false;
  bool _loading = false;
  String? _phoneError;
  String? _passwordError;
  String? _confirmError;

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _validate() {
    setState(() {
      _phoneError = null;
      _passwordError = null;
      _confirmError = null;
    });
    final phone = _phoneController.text.trim();
    if (phone.isEmpty || !RegExp(r'^0[0-9]{8,9}$').hasMatch(phone)) {
      setState(() => _phoneError = 'Số điện thoại không hợp lệ');
    }
    final pw = _passwordController.text;
    if (pw.length < 8) {
      setState(() => _passwordError = 'Mật khẩu tối thiểu 8 ký tự');
    } else if (!RegExp(r'[a-zA-Z]').hasMatch(pw)) {
      setState(() => _passwordError = 'Mật khẩu phải bao gồm chữ cái');
    } else if (!RegExp(r'[0-9]').hasMatch(pw)) {
      setState(() => _passwordError = 'Mật khẩu phải bao gồm số');
    }
    if (_confirmPasswordController.text != pw) {
      setState(() => _confirmError = 'Mật khẩu xác nhận không khớp');
    }
  }

  bool _isFirebaseAvailable() {
    try {
      Firebase.app();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> _register() async {
    if (_loading) return;
    _validate();
    if (_phoneError != null || _passwordError != null || _confirmError != null) return;
    setState(() => _loading = true);

    final phone = _phoneController.text.trim();

    // Check if Firebase is available and it's not a development test phone number
    if (!_isFirebaseAvailable() || phone == '0000000000') {
      // Mock Mode: Navigate to OTP directly
      await Future.delayed(const Duration(milliseconds: 500));
      if (!mounted) return;
      setState(() => _loading = false);
      _navigateToOtp('mock_verification_id');
      return;
    }

    // Real Firebase Phone Auth
    final formattedPhone = '+84${phone.substring(1)}';
    try {
      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: formattedPhone,
        verificationCompleted: (PhoneAuthCredential credential) async {
          // Instant verification on Android
          try {
            final authResult = await FirebaseAuth.instance.signInWithCredential(credential);
            final user = authResult.user;
            if (user != null) {
              final idToken = await user.getIdToken();
              if (idToken != null) {
                print('[Firebase ID Token (Auto)]: $idToken');
                // Call backend API to register directly
                final repository = ref.read(authRepositoryProvider);
                final response = await repository.register(
                  idToken: idToken,
                  displayName: '',
                  password: _passwordController.text,
                );
                await ref.read(authProvider.notifier).setCredentials(response);
                
                const storage = FlutterSecureStorage();
                await storage.write(key: 'user_role', value: response.user.role);

                if (mounted) {
                  Navigator.of(context).popUntil((route) => route.isFirst);
                  final role = response.user.role.toLowerCase();
                  if (role == 'customer') {
                    final hasOnboarded = await storage.read(key: 'onboarding_completed');
                    if (!mounted) return;
                    if (hasOnboarded == 'true') {
                      context.go(AppConstants.routeHome);
                    } else {
                      context.go(AppConstants.routeOnboarding);
                    }
                  } else if (role == 'staff') {
                    context.go(AppConstants.routeStaffHome);
                  } else if (role == 'admin' || role == 'manager') {
                    context.go(AppConstants.routeCashier);
                  } else {
                    context.go(AppConstants.routeCashier);
                  }
                }
              }
            }
          } catch (e) {
            if (e is DioException) {
              print('[Backend Register Error (Auto)] Status: ${e.response?.statusCode}');
              print('[Backend Register Error (Auto)] Data: ${e.response?.data}');
            } else {
              print('[Auto Verify Error]: $e');
            }
            setState(() {
              _loading = false;
              _phoneError = 'Đăng ký tự động thất bại: $e';
            });
          }
        },
        verificationFailed: (FirebaseAuthException e) {
          setState(() {
            _loading = false;
            _phoneError = e.message ?? 'Xác thực số điện thoại thất bại';
          });
        },
        codeSent: (String verificationId, int? resendToken) {
          setState(() => _loading = false);
          _navigateToOtp(verificationId);
        },
        codeAutoRetrievalTimeout: (String verificationId) {},
      );
    } catch (e) {
      setState(() {
        _loading = false;
        _phoneError = 'Lỗi gửi mã OTP: $e';
      });
    }
  }

  void _navigateToOtp(String verificationId) {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => OtpVerificationPage(
          phone: _phoneController.text.trim(),
          password: _passwordController.text,
          verificationId: verificationId,
        ),
        transitionsBuilder: (_, animation, __, child) {
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(1, 0),
              end: Offset.zero,
            ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              // Back button
              _buildBackButton(),
              const SizedBox(height: 24),
              // Header
              Center(child: _buildHeader()),
              const SizedBox(height: 24),
              // Form
              _buildPhoneField(),
              const SizedBox(height: 16),
              _buildPasswordField(),
              const SizedBox(height: 16),
              _buildConfirmPasswordField(),
              const SizedBox(height: 28),
              // Register button
              _buildRegisterButton(),
              const SizedBox(height: 24),
              // Login link
              _buildLoginLink(),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Back Button ───────────────────────────────────────────────────────
  Widget _buildBackButton() {
    return GestureDetector(
      onTap: () => context.pop(),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppColors.bgSoft,
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Icon(Icons.arrow_back, size: 20, color: AppColors.textPrimary),
      ),
    );
  }

  // ─── Header ────────────────────────────────────────────────────────────
  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.primary, AppColors.secondary],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(14),
          ),
          padding: const EdgeInsets.all(8),
          child: Image.asset('assets/logo.png', fit: BoxFit.contain),
        ),
        const SizedBox(height: 12),
        const Text(
          'DineX',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          'Tạo tài khoản',
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 6),
        const Text(
          'Đăng ký để đặt món và nhận ưu đãi',
          style: TextStyle(
            fontSize: 14,
            color: AppColors.textSecondary,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  // ─── Phone Field ───────────────────────────────────────────────────────
  Widget _buildPhoneField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Số điện thoại',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _phoneController,
          keyboardType: TextInputType.phone,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(10),
          ],
          style: const TextStyle(fontSize: 15, color: AppColors.textPrimary),
          decoration: _inputDecoration(
            hint: '0901234567',
            prefixIcon: Icons.phone_outlined,
            errorText: _phoneError,
          ),
        ),
      ],
    );
  }

  // ─── Password Field ────────────────────────────────────────────────────
  Widget _buildPasswordField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Mật khẩu',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _passwordController,
          obscureText: !_passwordVisible,
          style: const TextStyle(fontSize: 15, color: AppColors.textPrimary),
          decoration: _inputDecoration(
            hint: 'Ít nhất 8 ký tự, có chữ và số',
            prefixIcon: Icons.lock_outline,
            errorText: _passwordError,
            suffixIcon: IconButton(
              icon: Icon(
                _passwordVisible ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                size: 20,
                color: AppColors.textTertiary,
              ),
              onPressed: () => setState(() => _passwordVisible = !_passwordVisible),
            ),
          ),
        ),
      ],
    );
  }

  // ─── Confirm Password Field ────────────────────────────────────────────
  Widget _buildConfirmPasswordField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Xác nhận mật khẩu',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _confirmPasswordController,
          obscureText: !_confirmVisible,
          style: const TextStyle(fontSize: 15, color: AppColors.textPrimary),
          decoration: _inputDecoration(
            hint: 'Nhập lại mật khẩu',
            prefixIcon: Icons.lock_outline,
            errorText: _confirmError,
            suffixIcon: IconButton(
              icon: Icon(
                _confirmVisible ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                size: 20,
                color: AppColors.textTertiary,
              ),
              onPressed: () => setState(() => _confirmVisible = !_confirmVisible),
            ),
          ),
        ),
      ],
    );
  }

  // ─── Register Button ───────────────────────────────────────────────────
  Widget _buildRegisterButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _loading ? null : _register,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.onPrimary,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 0,
        ),
        child: _loading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(color: AppColors.onPrimary, strokeWidth: 2),
              )
            : const Text(
                'Đăng ký',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
      ),
    );
  }

  // ─── Login Link ────────────────────────────────────────────────────────
  Widget _buildLoginLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          'Đã có tài khoản? ',
          style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
        ),
        GestureDetector(
          onTap: () => context.pop(),
          child: const Text(
            'Đăng nhập',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
            ),
          ),
        ),
      ],
    );
  }

  // ─── Input Decoration Helper ───────────────────────────────────────────
  InputDecoration _inputDecoration({
    required String hint,
    required IconData prefixIcon,
    Widget? suffixIcon,
    String? errorText,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: AppColors.textPlaceholder),
      prefixIcon: Icon(prefixIcon, size: 20, color: AppColors.textTertiary),
      suffixIcon: suffixIcon,
      errorText: errorText,
      filled: true,
      fillColor: AppColors.surfaceContainerLowest,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// OTP Verification Page — shown only for customer registration.
// ═══════════════════════════════════════════════════════════════════════════

class OtpVerificationPage extends ConsumerStatefulWidget {
  final String phone;
  final String password;
  final String verificationId;

  const OtpVerificationPage({
    super.key,
    required this.phone,
    required this.password,
    required this.verificationId,
  });

  @override
  ConsumerState<OtpVerificationPage> createState() => _OtpVerificationPageState();
}

class _OtpVerificationPageState extends ConsumerState<OtpVerificationPage> {
  final List<TextEditingController> _otpControllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());
  bool _loading = false;
  String? _error;
  int _resendCooldown = 60;
  bool _canResend = false;

  @override
  void initState() {
    super.initState();
    _startCooldown();
  }

  @override
  void dispose() {
    for (final c in _otpControllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  void _startCooldown() {
    setState(() {
      _resendCooldown = 60;
      _canResend = false;
    });
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return false;
      setState(() => _resendCooldown--);
      if (_resendCooldown <= 0) {
        setState(() => _canResend = true);
        return false;
      }
      return true;
    });
  }

  String get _otpValue => _otpControllers.map((c) => c.text).join();

  Future<void> _verifyOtp() async {
    if (_loading) return;
    if (_otpValue.length < 6) {
      setState(() => _error = 'Vui lòng nhập đủ 6 số OTP');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      String idToken = 'mock_firebase_id_token';

      if (widget.verificationId != 'mock_verification_id') {
        // Real Firebase Auth verification
        final credential = PhoneAuthProvider.credential(
          verificationId: widget.verificationId,
          smsCode: _otpValue,
        );

        final authResult = await FirebaseAuth.instance.signInWithCredential(credential);
        final firebaseUser = authResult.user;
        if (firebaseUser == null) {
          throw Exception('Không thể đăng nhập Firebase');
        }
        final token = await firebaseUser.getIdToken();
        if (token == null) {
          throw Exception('Không lấy được ID Token từ Firebase');
        }
        idToken = token;
        print('[Firebase ID Token]: $idToken');
      } else {
        // Mock Mode
        await Future.delayed(const Duration(milliseconds: 800));
        if (_otpValue != '123456') {
          throw Exception('Mã OTP không đúng (Chế độ thử nghiệm: 123456)');
        }
      }

      // Call API Đăng ký ở Backend
      final repository = ref.read(authRepositoryProvider);
      final response = await repository.register(
        idToken: idToken,
        displayName: '', // Gửi rỗng như backend mong đợi
        password: widget.password,
      );

      // Lưu trữ credentials và JWT token mới
      await ref.read(authProvider.notifier).setCredentials(response);

      if (!mounted) return;

      const storage = FlutterSecureStorage();
      await storage.write(key: 'user_role', value: response.user.role);
      
      if (mounted) {
        Navigator.of(context).popUntil((route) => route.isFirst);
        final role = response.user.role.toLowerCase();
        if (role == 'customer') {
          final hasOnboarded = await storage.read(key: 'onboarding_completed');
          if (!mounted) return;
          if (hasOnboarded == 'true') {
            GoRouter.of(context).go(AppConstants.routeHome);
          } else {
            GoRouter.of(context).go(AppConstants.routeOnboarding);
          }
        } else if (role == 'staff') {
          GoRouter.of(context).go(AppConstants.routeStaffHome);
        } else if (role == 'admin' || role == 'manager') {
          GoRouter.of(context).go(AppConstants.routeCashier);
        } else {
          GoRouter.of(context).go(AppConstants.routeCashier);
        }
      }
    } catch (e) {
      if (e is DioException) {
        print('[Backend Register Error] Status: ${e.response?.statusCode}');
        print('[Backend Register Error] Headers: ${e.response?.headers}');
        print('[Backend Register Error] Data: ${e.response?.data}');
      } else {
        print('[Verify OTP Error]: $e');
      }
      setState(() {
        _loading = false;
        _error = e is DioException 
            ? (e.response?.data['message'] ?? 'Đăng ký thất bại từ máy chủ')
            : e.toString().replaceAll('Exception: ', '');
      });
    }
  }

  Future<void> _resendOtp() async {
    if (!_canResend) return;
    setState(() {
      _error = null;
    });

    if (widget.verificationId == 'mock_verification_id') {
      _startCooldown();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã gửi lại mã OTP (Chế độ thử nghiệm: 123456)')),
      );
      return;
    }

    setState(() => _loading = true);
    final formattedPhone = '+84${widget.phone.substring(1)}';

    try {
      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: formattedPhone,
        verificationCompleted: (PhoneAuthCredential credential) {},
        verificationFailed: (FirebaseAuthException e) {
          setState(() {
            _loading = false;
            _error = e.message ?? 'Gửi lại OTP thất bại';
          });
        },
        codeSent: (String verificationId, int? resendToken) {
          setState(() => _loading = false);
          _startCooldown();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Mã OTP mới đã được gửi')),
          );
        },
        codeAutoRetrievalTimeout: (String verificationId) {},
      );
    } catch (e) {
      setState(() {
        _loading = false;
        _error = 'Lỗi gửi lại OTP: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              // Back button
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.bgSoft,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.arrow_back, size: 20, color: AppColors.textPrimary),
                ),
              ),
              const SizedBox(height: 32),
              // Header
              const Text(
                'Xác thực OTP',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Mã xác thực đã được gửi đến\n${widget.phone}',
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 36),
              // OTP Input
              _buildOtpInput(),
              // Error
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(
                  _error!,
                  style: const TextStyle(fontSize: 13, color: AppColors.error),
                ),
              ],
              const SizedBox(height: 24),
              // Resend
              _buildResendRow(),
              const SizedBox(height: 32),
              // Verify button
              _buildVerifyButton(),
            ],
          ),
        ),
      ),
    );
  }

  // ─── OTP Input ─────────────────────────────────────────────────────────
  Widget _buildOtpInput() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(6, (index) {
        return SizedBox(
          width: 48,
          height: 56,
          child: TextFormField(
            controller: _otpControllers[index],
            focusNode: _focusNodes[index],
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            maxLength: 1,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
            decoration: InputDecoration(
              counterText: '',
              filled: true,
              fillColor: AppColors.surfaceContainerLowest,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.primary, width: 2),
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 14),
            ),
            onChanged: (value) {
              if (value.isNotEmpty && index < 5) {
                _focusNodes[index + 1].requestFocus();
              } else if (value.isEmpty && index > 0) {
                _focusNodes[index - 1].requestFocus();
              }
              // Auto verify when all filled
              if (_otpValue.length == 6) {
                _verifyOtp();
              }
            },
          ),
        );
      }),
    );
  }

  // ─── Resend Row ────────────────────────────────────────────────────────
  Widget _buildResendRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          'Không nhận được mã? ',
          style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
        ),
        GestureDetector(
          onTap: _canResend ? _resendOtp : null,
          child: Text(
            _canResend ? 'Gửi lại' : 'Gửi lại (${_resendCooldown}s)',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: _canResend ? AppColors.primary : AppColors.textTertiary,
            ),
          ),
        ),
      ],
    );
  }

  // ─── Verify Button ─────────────────────────────────────────────────────
  Widget _buildVerifyButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _loading ? null : _verifyOtp,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.onPrimary,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 0,
        ),
        child: _loading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(color: AppColors.onPrimary, strokeWidth: 2),
              )
            : const Text(
                'Xác nhận',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
      ),
    );
  }
}
