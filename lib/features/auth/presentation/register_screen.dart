// lib/features/auth/presentation/register_screen.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../auth_repository.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/app_snackbar.dart';
import '../../../core/constants/app_constants.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _obscurePass = true;
  bool _obscureConfirm = true;
  bool _loading = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _passCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    try {
      final String mobile = _phoneCtrl.text.trim();
      final String email = _emailCtrl.text.trim();

      // Send OTP to email only as per requirement
      await ref.read(authNotifierProvider.notifier).sendOtp(
            mobile: mobile,
            email: email,
          );

      if (mounted) {
        context.push('/verify-otp', extra: {
          'mobile': mobile,
          'email': email,
          'registrationData': {
            'name': _nameCtrl.text.trim(),
            'mobile': mobile,
            'email': email,
            'password': _passCtrl.text,
            'password_confirmation': _confirmCtrl.text,
            'device_name': 'Android Device',
            'device_id': 'unique_device_id',
          }
        });
      }
    } catch (e) {
      if (mounted) {
        AppSnackbar.error(context, e.toString());
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String b64Encode(String input) {
    return base64Encode(utf8.encode(input));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: () => context.pop()),
        title: const Text('Create Account'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Join YD APP',
                  style:
                      Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Access unlimited study materials',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? AppColors.darkTextSecondary
                            : AppColors.textSecondary,
                      ),
                ),
                const SizedBox(height: 28),
                AppTextField(
                  controller: _nameCtrl,
                  label: 'Full Name',
                  hint: 'John Doe',
                  prefixIcon: Icons.person_outline_rounded,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Enter your full name';
                    }
                    if (v.trim().length < 2) return 'Name too short';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                AppTextField(
                  controller: _emailCtrl,
                  label: 'Email Address',
                  hint: 'you@example.com',
                  keyboardType: TextInputType.emailAddress,
                  prefixIcon: Icons.email_outlined,
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Enter email';
                    if (!AppConstants.emailRegex.hasMatch(v.trim())) {
                      return 'Enter valid email';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                AppTextField(
                  controller: _phoneCtrl,
                  label: 'Mobile Number',
                  hint: '9876543210',
                  keyboardType: TextInputType.phone,
                  prefixIcon: Icons.phone_outlined,
                  maxLength: 10,
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Enter mobile number';
                    if (!AppConstants.phoneRegex.hasMatch(v.trim())) {
                      return 'Enter valid 10-digit number';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                AppTextField(
                  controller: _passCtrl,
                  label: 'Password',
                  hint: 'Min 8 chars with uppercase, number, symbol',
                  obscureText: _obscurePass,
                  prefixIcon: Icons.lock_outline_rounded,
                  suffixIcon: IconButton(
                    icon: Icon(_obscurePass
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined),
                    onPressed: () =>
                        setState(() => _obscurePass = !_obscurePass),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Enter password';
                    if (v.length < 8) return 'Password must be at least 8 chars';
                    if (!v.contains(RegExp(r'[A-Z]'))) {
                      return 'Add at least one uppercase letter';
                    }
                    if (!v.contains(RegExp(r'[0-9]'))) {
                      return 'Add at least one number';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                AppTextField(
                  controller: _confirmCtrl,
                  label: 'Confirm Password',
                  hint: 'Re-enter password',
                  obscureText: _obscureConfirm,
                  prefixIcon: Icons.lock_outline_rounded,
                  suffixIcon: IconButton(
                    icon: Icon(_obscureConfirm
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined),
                    onPressed: () =>
                        setState(() => _obscureConfirm = !_obscureConfirm),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Confirm your password';
                    if (v != _passCtrl.text) return 'Passwords do not match';
                    return null;
                  },
                ),
                const SizedBox(height: 28),
                AppButton(
                  label: 'Create Account',
                  loading: _loading,
                  onPressed: _submit,
                ),
                const SizedBox(height: 20),
                Center(
                  child: RichText(
                    text: TextSpan(
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).brightness == Brightness.dark
                                ? AppColors.darkTextSecondary
                                : AppColors.textSecondary,
                          ),
                      children: [
                        const TextSpan(text: 'Already have an account? '),
                        TextSpan(
                          text: 'Sign In',
                          style: TextStyle(
                            color: Theme.of(context).brightness == Brightness.dark
                                ? AppColors.secondary
                                : AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                          recognizer: TapGestureRecognizer()
                            ..onTap = () => context.pop(),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
