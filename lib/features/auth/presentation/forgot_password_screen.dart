// lib/features/auth/presentation/forgot_password_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/api/api_exception.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/app_snackbar.dart';
import '../auth_repository.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _pageController = PageController();
  int _currentStep = 0;

  // Step 1: Email
  final _emailFormKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();

  // Step 2: OTP
  final _otpFormKey = GlobalKey<FormState>();
  final _otpCtrl = TextEditingController();

  // Step 3: Reset
  final _resetFormKey = GlobalKey<FormState>();
  final _passwordCtrl = TextEditingController();
  final _confirmPasswordCtrl = TextEditingController();

  bool _loading = false;
  String? _verifyToken;

  @override
  void dispose() {
    _pageController.dispose();
    _emailCtrl.dispose();
    _otpCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmPasswordCtrl.dispose();
    super.dispose();
  }

  Future<void> _sendOtp() async {
    if (!_emailFormKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await ref
          .read(authRepositoryProvider)
          .sendForgotPasswordOtp(_emailCtrl.text.trim());
      AppSnackbar.success(context, 'OTP sent to your email');
      _pageController.nextPage(
          duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
      setState(() => _currentStep = 1);
    } on ApiException catch (e) {
      AppSnackbar.error(context, e.message);
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _verifyOtp() async {
    if (!_otpFormKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      _verifyToken = await ref.read(authRepositoryProvider).verifyForgotPasswordOtp(
            email: _emailCtrl.text.trim(),
            otp: _otpCtrl.text.trim(),
          );
      _pageController.nextPage(
          duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
      setState(() => _currentStep = 2);
    } on ApiException catch (e) {
      AppSnackbar.error(context, e.message);
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _resetPassword() async {
    if (!_resetFormKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await ref.read(authRepositoryProvider).resetPassword(
            email: _emailCtrl.text.trim(),
            verifyToken: _verifyToken!,
            password: _passwordCtrl.text,
            passwordConfirmation: _confirmPasswordCtrl.text,
          );
      if (mounted) {
        AppSnackbar.success(context, 'Password reset successful. Please login.');
        context.go('/login');
      }
    } on ApiException catch (e) {
      AppSnackbar.error(context, e.message);
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Forgot Password'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (_currentStep > 0) {
              _pageController.previousPage(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut);
              setState(() => _currentStep--);
            } else {
              context.pop();
            }
          },
        ),
      ),
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          _buildEmailStep(),
          _buildOtpStep(),
          _buildResetStep(),
        ],
      ),
    );
  }

  Widget _buildEmailStep() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _emailFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Reset Password',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Enter your email address and we will send you an OTP to reset your password.',
              style: TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 32),
            AppTextField(
              controller: _emailCtrl,
              label: 'Email',
              hint: 'Enter your email',
              keyboardType: TextInputType.emailAddress,
              prefixIcon: Icons.email_outlined,
              validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 24),
            AppButton(
              label: 'Send OTP',
              onPressed: _sendOtp,
              loading: _loading,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOtpStep() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _otpFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Verify OTP',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Enter the 6-digit code sent to ${_emailCtrl.text}',
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 32),
            AppTextField(
              controller: _otpCtrl,
              label: 'OTP Code',
              hint: '000000',
              keyboardType: TextInputType.number,
              prefixIcon: Icons.lock_outline,
              maxLength: 6,
              validator: (v) => (v == null || v.length != 6) ? 'Enter 6-digit OTP' : null,
            ),
            const SizedBox(height: 24),
            AppButton(
              label: 'Verify OTP',
              onPressed: _verifyOtp,
              loading: _loading,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResetStep() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _resetFormKey,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'New Password',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Set a strong password for your account',
                style: TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 32),
              AppTextField(
                controller: _passwordCtrl,
                label: 'Password',
                hint: 'Enter new password',
                obscureText: true,
                prefixIcon: Icons.lock_outline,
                validator: (v) => (v == null || v.length < 6) ? 'Min 6 chars' : null,
              ),
              const SizedBox(height: 16),
              AppTextField(
                controller: _confirmPasswordCtrl,
                label: 'Confirm Password',
                hint: 'Re-enter new password',
                obscureText: true,
                prefixIcon: Icons.lock_outline,
                validator: (v) {
                  if (v != _passwordCtrl.text) return 'Passwords do not match';
                  return null;
                },
              ),
              const SizedBox(height: 24),
              AppButton(
                label: 'Reset Password',
                onPressed: _resetPassword,
                loading: _loading,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
