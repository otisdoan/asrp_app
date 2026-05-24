import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

/// Change Password Page — 3 fields: old password, new password, confirm new password.
/// Follows RULE: UI-only widgets, AppColors 100%, responsive.
class ChangePasswordPage extends StatefulWidget {
  const ChangePasswordPage({super.key});

  @override
  State<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  final _oldPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _oldVisible = false;
  bool _newVisible = false;
  bool _confirmVisible = false;
  bool _loading = false;
  bool _success = false;
  String? _oldError;
  String? _newError;
  String? _confirmError;

  @override
  void dispose() {
    _oldPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _validate() {
    setState(() {
      _oldError = null;
      _newError = null;
      _confirmError = null;
    });
    if (_oldPasswordController.text.isEmpty) {
      setState(() => _oldError = 'Vui lòng nhập mật khẩu cũ');
    }
    final pw = _newPasswordController.text;
    if (pw.length < 8) {
      setState(() => _newError = 'Mật khẩu mới tối thiểu 8 ký tự');
    } else if (!RegExp(r'[a-zA-Z]').hasMatch(pw)) {
      setState(() => _newError = 'Mật khẩu mới phải bao gồm chữ cái');
    } else if (!RegExp(r'[0-9]').hasMatch(pw)) {
      setState(() => _newError = 'Mật khẩu mới phải bao gồm số');
    } else if (_oldPasswordController.text == pw) {
      setState(() => _newError = 'Mật khẩu mới phải khác mật khẩu cũ');
    }
    if (_confirmPasswordController.text != pw) {
      setState(() => _confirmError = 'Mật khẩu xác nhận không khớp');
    }
  }

  Future<void> _changePassword() async {
    _validate();
    if (_oldError != null || _newError != null || _confirmError != null) return;
    setState(() => _loading = true);
    await Future.delayed(const Duration(milliseconds: 800));
    if (mounted) {
      setState(() {
        _loading = false;
        _success = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
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
              const SizedBox(height: 24),
              // Brand logo
              Center(
                child: Column(
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
                  ],
                ),
              ),
              const SizedBox(height: 24),
              if (!_success) ...[
                _buildChangeForm(),
              ] else ...[
                _buildSuccessState(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChangeForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Center(
          child: Text(
            'Đổi mật khẩu',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        const SizedBox(height: 6),
        const Center(
          child: Text(
            'Nhập mật khẩu cũ và tạo mật khẩu mới',
            style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
          ),
        ),
        const SizedBox(height: 28),
        // Old password
        const Text(
          'Mật khẩu cũ',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _oldPasswordController,
          obscureText: !_oldVisible,
          style: const TextStyle(fontSize: 15, color: AppColors.textPrimary),
          decoration: _inputDecoration(
            hint: 'Nhập mật khẩu hiện tại',
            prefixIcon: Icons.lock_outline,
            errorText: _oldError,
            suffixIcon: IconButton(
              icon: Icon(
                _oldVisible ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                size: 20,
                color: AppColors.textTertiary,
              ),
              onPressed: () => setState(() => _oldVisible = !_oldVisible),
            ),
          ),
        ),
        const SizedBox(height: 16),
        // New password
        const Text(
          'Mật khẩu mới',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _newPasswordController,
          obscureText: !_newVisible,
          style: const TextStyle(fontSize: 15, color: AppColors.textPrimary),
          decoration: _inputDecoration(
            hint: 'Ít nhất 8 ký tự, có chữ và số',
            prefixIcon: Icons.lock_outline,
            errorText: _newError,
            suffixIcon: IconButton(
              icon: Icon(
                _newVisible ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                size: 20,
                color: AppColors.textTertiary,
              ),
              onPressed: () => setState(() => _newVisible = !_newVisible),
            ),
          ),
        ),
        const SizedBox(height: 16),
        // Confirm new password
        const Text(
          'Xác nhận mật khẩu mới',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _confirmPasswordController,
          obscureText: !_confirmVisible,
          style: const TextStyle(fontSize: 15, color: AppColors.textPrimary),
          decoration: _inputDecoration(
            hint: 'Nhập lại mật khẩu mới',
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
        const SizedBox(height: 28),
        // Change button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _loading ? null : _changePassword,
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
                    'Đổi mật khẩu',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
          ),
        ),
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _buildSuccessState() {
    return Column(
      children: [
        const SizedBox(height: 40),
        Container(
          width: 80,
          height: 80,
          decoration: const BoxDecoration(
            color: AppColors.successContainer,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.check_circle, size: 44, color: AppColors.success),
        ),
        const SizedBox(height: 24),
        const Text(
          'Đổi mật khẩu thành công!',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        const Text(
          'Mật khẩu của bạn đã được cập nhật.',
          style: TextStyle(
            fontSize: 14,
            color: AppColors.textSecondary,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.onPrimary,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
            child: const Text(
              'Quay lại',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
          ),
        ),
      ],
    );
  }

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
