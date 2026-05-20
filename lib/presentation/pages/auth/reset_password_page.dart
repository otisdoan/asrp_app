import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/constants/app_constants.dart';

class ResetPasswordPage extends ConsumerStatefulWidget {
  const ResetPasswordPage({super.key});
  @override
  ConsumerState<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends ConsumerState<ResetPasswordPage> {
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _passwordVisible = false;
  bool _confirmVisible = false;
  bool _loading = false;
  bool _done = false;
  String? _error;

  @override
  void dispose() { _passwordController.dispose(); _confirmController.dispose(); super.dispose(); }

  Future<void> _submit() async {
    final pw = _passwordController.text;
    if (pw.length < 8) { setState(() => _error = 'Mat khau toi thieu 8 ky tu'); return; }
    if (!RegExp(r'[a-zA-Z]').hasMatch(pw)) { setState(() => _error = 'Mat khau phai bao gom chu cai'); return; }
    if (!RegExp(r'[0-9]').hasMatch(pw)) { setState(() => _error = 'Mat khau phai bao gom so'); return; }
    if (_confirmController.text != pw) { setState(() => _error = 'Mat khau xac nhan khong khop'); return; }
    setState(() { _loading = true; _error = null; });
    await Future.delayed(const Duration(milliseconds: 800));
    setState(() { _loading = false; _done = true; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Đặt lại mật khẩu'), backgroundColor: AppColors.primary, foregroundColor: Colors.white, elevation: 0),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: _done ? _buildSuccessState(context) : _buildFormState(context),
        ),
      ),
    );
  }

  Widget _buildFormState(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Mật khẩu mới', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
        const SizedBox(height: 8),
        Text('Nhập mật khẩu mới cho tài khoản của bạn', style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 32),
        const Text('Mật khẩu mới', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        TextFormField(controller: _passwordController, obscureText: !_passwordVisible, decoration: InputDecoration(hintText: 'Ít nhất 8 ký tự', prefixIcon: const Icon(Icons.lock_outline), suffixIcon: IconButton(icon: Icon(_passwordVisible ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 20), onPressed: () => setState(() => _passwordVisible = !_passwordVisible))), textInputAction: TextInputAction.next),
        const SizedBox(height: 14),
        const Text('Xác nhận mật khẩu', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        TextFormField(controller: _confirmController, obscureText: !_confirmVisible, decoration: InputDecoration(hintText: 'Nhập lại mật khẩu', prefixIcon: const Icon(Icons.lock_outline), suffixIcon: IconButton(icon: Icon(_confirmVisible ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 20), onPressed: () => setState(() => _confirmVisible = !_confirmVisible))), textInputAction: TextInputAction.done, onFieldSubmitted: (_) => _submit()),
        if (_error != null) ...[const SizedBox(height: 8), Text(_error!, style: const TextStyle(color: AppColors.error, fontSize: 12))],
        const SizedBox(height: 24),
        SizedBox(width: double.infinity, child: ElevatedButton(onPressed: _loading ? null : _submit, child: _loading ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Text('Đặt lại mật khẩu'))),
      ],
    );
  }

  Widget _buildSuccessState(BuildContext context) {
    return Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.center, children: [
      Container(width: 80, height: 80, decoration: BoxDecoration(color: AppColors.successContainer, borderRadius: BorderRadius.circular(40)), child: const Icon(Icons.check_circle_outline, size: 40, color: AppColors.success)),
      const SizedBox(height: 24),
      Text('Đặt lại thành công!', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
      const SizedBox(height: 8),
      const Text('Mật khẩu đã được cập nhật. Vui lòng đăng nhập lại.', textAlign: TextAlign.center),
      const SizedBox(height: 32),
      SizedBox(width: double.infinity, child: ElevatedButton(onPressed: () => context.go(AppConstants.routeLogin), child: const Text('Đăng nhập ngay'))),
    ]);
  }
}
