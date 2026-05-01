// lib/features/auth/presentation/login_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../auth_repository.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/app_snackbar.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _identifierCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _obscure = true;
  bool _loading = false;
  bool _usePhone = false;

  @override
  void dispose() {
    _identifierCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    
    final success = await ref.read(authNotifierProvider.notifier).login(
          identifier: _identifierCtrl.text.trim(),
          password: _passwordCtrl.text,
          deviceId: 'unique_device_id', // TODO: Use device_info_plus
          deviceName: 'Android Device',
        );
    
    if (mounted) {
      if (success) {
        context.go('/home');
      } else {
        final error = ref.read(authNotifierProvider).error;
        AppSnackbar.error(context, error ?? 'Login failed');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    final isLoading = authState.status == AuthStatus.authenticating;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 48),
                // Logo
                Center(
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? AppColors.darkSurface
                          : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Image.asset(
                        'assets/images/logo.png',
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => const Icon(
                          Icons.school_rounded,
                          color: AppColors.primary,
                          size: 40,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                Text(
                  'Welcome back!',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Sign in to access your study materials',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? AppColors.darkTextSecondary
                            : AppColors.textSecondary,
                      ),
                ),
                const SizedBox(height: 36),
                // Toggle email/phone
                Row(
                  children: [
                    _ModeChip(
                      label: 'Email',
                      selected: !_usePhone,
                      onTap: () => setState(() {
                        _usePhone = false;
                        _identifierCtrl.clear();
                      }),
                    ),
                    const SizedBox(width: 8),
                    _ModeChip(
                      label: 'Mobile',
                      selected: _usePhone,
                      onTap: () => setState(() {
                        _usePhone = true;
                        _identifierCtrl.clear();
                      }),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                AppTextField(
                  controller: _identifierCtrl,
                  label: _usePhone ? 'Mobile Number' : 'Email Address',
                  hint: _usePhone ? '9876543210' : 'you@example.com',
                  keyboardType: _usePhone
                      ? TextInputType.phone
                      : TextInputType.emailAddress,
                  prefixIcon:
                      _usePhone ? Icons.phone_outlined : Icons.email_outlined,
                  enabled: !isLoading,
                  validator: (v) {
                    if (v == null || v.isEmpty) {
                      return _usePhone
                          ? 'Enter mobile number'
                          : 'Enter email address';
                    }
                    if (_usePhone &&
                        !AppConstants.phoneRegex.hasMatch(v.trim())) {
                      return 'Enter valid 10-digit mobile number';
                    }
                    if (!_usePhone &&
                        !AppConstants.emailRegex.hasMatch(v.trim())) {
                      return 'Enter valid email address';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                AppTextField(
                  controller: _passwordCtrl,
                  label: 'Password',
                  hint: '••••••••',
                  obscureText: _obscure,
                  enabled: !isLoading,
                  prefixIcon: Icons.lock_outline_rounded,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscure
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? AppColors.darkTextSecondary
                          : AppColors.textSecondary,
                    ),
                    onPressed: () => setState(() => _obscure = !_obscure),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Enter password';
                    if (v.length < 6) return 'Password too short';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: isLoading ? null : () => context.push('/forgot-password'),
                    child: const Text('Forgot password?'),
                  ),
                ),
                const SizedBox(height: 8),
                AppButton(
                  label: 'Sign In',
                  loading: isLoading,
                  onPressed: _submit,
                ),
                const SizedBox(height: 24),
                Center(
                  child: RichText(
                    text: TextSpan(
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).brightness == Brightness.dark
                                ? AppColors.darkTextSecondary
                                : AppColors.textSecondary,
                          ),
                      children: [
                        const TextSpan(text: "Don't have an account? "),
                        TextSpan(
                          text: 'Sign Up',
                          style: TextStyle(
                            color: Theme.of(context).brightness == Brightness.dark
                                ? AppColors.secondary
                                : AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                          recognizer: TapGestureRecognizer()
                            ..onTap = () => context.push('/register'),
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

class _ModeChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ModeChip(
      {required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? (isDark ? AppColors.secondary : AppColors.primary)
              : (isDark ? AppColors.darkSurfaceVariant : AppColors.surfaceVariant),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: selected
                ? (isDark ? AppColors.primaryDark : Colors.white)
                : (isDark ? AppColors.darkTextSecondary : AppColors.textSecondary),
          ),
        ),
      ),
    );
  }
}
