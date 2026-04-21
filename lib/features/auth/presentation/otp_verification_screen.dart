// lib/features/auth/presentation/otp_verification_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../auth_repository.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_snackbar.dart';

class OtpVerificationScreen extends ConsumerStatefulWidget {
  final String mobile;
  final String? email;
  final Map<String, dynamic> registrationData;

  const OtpVerificationScreen({
    super.key,
    required this.mobile,
    this.email,
    required this.registrationData,
  });

  @override
  ConsumerState<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends ConsumerState<OtpVerificationScreen> {
  final List<TextEditingController> _controllers = List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());
  bool _loading = false;
  int _timerSeconds = 30;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _timerSeconds = 30;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_timerSeconds == 0) {
        timer.cancel();
      } else {
        setState(() => _timerSeconds--);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (var c in _controllers) {
      c.dispose();
    }
    for (var f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  Future<void> _resendOtp() async {
    if (_timerSeconds > 0) return;
    
    setState(() => _loading = true);
    try {
      await ref.read(authNotifierProvider.notifier).sendOtp(
        mobile: widget.mobile,
        email: widget.email!,
      );
      _startTimer();
      if (mounted) AppSnackbar.success(context, 'OTP resent successfully');
    } catch (e) {
      if (mounted) AppSnackbar.error(context, e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _verifyAndRegister() async {
    final otp = _controllers.map((e) => e.text).join();
    if (otp.length < 6) {
      AppSnackbar.error(context, 'Please enter complete 6-digit OTP');
      return;
    }

    setState(() => _loading = true);
    
    final verifyToken = await ref.read(authNotifierProvider.notifier).verifyOtp(
      email: widget.email!,
      otp: otp,
    );

    if (verifyToken != null && mounted) {
      final success = await ref.read(authNotifierProvider.notifier).register(
            name: widget.registrationData['name'],
            mobile: widget.registrationData['mobile'],
            email: widget.registrationData['email'],
            password: widget.registrationData['password'],
            passwordConfirmation: widget.registrationData['password_confirmation'],
            verifyToken: verifyToken,
            deviceName: widget.registrationData['device_name'] ?? 'Android Device',
            deviceId: widget.registrationData['device_id'] ?? 'unique_id',
          );

      if (mounted) {
        if (success) {
          context.go('/home');
        } else {
          final error = ref.read(authNotifierProvider).error;
          AppSnackbar.error(context, error ?? 'Registration failed');
        }
      }
    } else if (mounted) {
      AppSnackbar.error(context, 'Invalid OTP');
    }
    
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Verify OTP')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const SizedBox(height: 20),
            Text(
              'Verification Code',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'We have sent a 6-digit code to\n${widget.email}',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 40),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(6, (index) {
                return SizedBox(
                  width: 45,
                  child: TextField(
                    controller: _controllers[index],
                    focusNode: _focusNodes[index],
                    textAlign: TextAlign.center,
                    keyboardType: TextInputType.number,
                    maxLength: 1,
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                    decoration: InputDecoration(
                      counterText: "",
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onChanged: (value) {
                      if (value.isNotEmpty && index < 5) {
                        _focusNodes[index + 1].requestFocus();
                      } else if (value.isEmpty && index > 0) {
                        _focusNodes[index - 1].requestFocus();
                      }
                    },
                  ),
                );
              }),
            ),
            const SizedBox(height: 40),
            AppButton(
              label: 'Verify & Register',
              loading: _loading,
              onPressed: _verifyAndRegister,
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text("Didn't receive code? "),
                TextButton(
                  onPressed: _timerSeconds == 0 ? _resendOtp : null,
                  child: Text(
                    _timerSeconds == 0 ? 'Resend' : 'Resend in ${_timerSeconds}s',
                    style: TextStyle(
                      color: _timerSeconds == 0 ? AppColors.primary : AppColors.textSecondary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
