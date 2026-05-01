// lib/features/subscription/presentation/subscribe_bottom_sheet.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import '../../semester/semester_repository.dart';
import '../subscription_repository.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_snackbar.dart';
import '../../auth/auth_repository.dart';

class SubscribeBottomSheet extends ConsumerStatefulWidget {
  final int semesterId;
  final String semesterName;

  const SubscribeBottomSheet({
    super.key,
    required this.semesterId,
    required this.semesterName,
  });

  @override
  ConsumerState<SubscribeBottomSheet> createState() =>
      _SubscribeBottomSheetState();
}

class _SubscribeBottomSheetState
    extends ConsumerState<SubscribeBottomSheet> {
  late Razorpay _razorpay;
  bool _loading = false;
  String? _orderId;

  @override
  void initState() {
    super.initState();
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _onPaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _onPaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _onExternalWallet);
  }

  @override
  void dispose() {
    _razorpay.clear();
    super.dispose();
  }

  Future<void> _initiatePayment() async {
    setState(() => _loading = true);
    try {
      final response = await ref
          .read(subscriptionRepositoryProvider)
          .createOrder(widget.semesterId);

      _orderId = response['order_id']?.toString();
      
      if (_orderId == null) {
        throw Exception('Server did not return an order ID');
      }

      // Ensure amount is an integer (Razorpay requires paise as int)
      final rawAmount = response['amount'] ?? AppConstants.semesterPrice;
      final int amount = rawAmount is num ? rawAmount.toInt() : int.tryParse(rawAmount.toString()) ?? 7500;

      final options = {
        'key': AppConstants.razorpayKeyId,
        'amount': amount,
        'name': AppConstants.companyName,
        'description': '${widget.semesterName} Access',
        'order_id': _orderId,
        'currency': AppConstants.currency,
        'prefill': {
          'name': response['user_name']?.toString() ?? 'User',
          'email': response['user_email']?.toString() ?? 'user@example.com',
          'contact': response['user_mobile']?.toString() ?? '',
        },
        'timeout': 300, // 5 minutes
        'retry': {'enabled': false},
      };

      debugPrint('🚀 Opening Razorpay with Options: $options');
      try {
        _razorpay.open(options);
      } catch (e) {
        debugPrint('❌ Razorpay Crash: $e');
        AppSnackbar.error(context, 'Could not open payment gateway');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        AppSnackbar.error(context, 'Payment Init Error: ${e.toString()}');
      }
    }
  }

  Future<void> _onPaymentSuccess(PaymentSuccessResponse response) async {
    try {
      await ref.read(subscriptionRepositoryProvider).verifyPayment(
            semesterId: widget.semesterId,
            razorpayOrderId: response.orderId ?? _orderId ?? '',
            razorpayPaymentId: response.paymentId ?? '',
            razorpaySignature: response.signature ?? '',
          );

      // Invalidate all related caches for this specific semester and globally
      ref.invalidate(subscriptionStatusProvider(widget.semesterId));
      ref.invalidate(semesterDetailProvider(widget.semesterId));
      ref.invalidate(oldPapersProvider(widget.semesterId));
      ref.invalidate(pdfsBySubjectProvider);
      ref.invalidate(semestersProvider);
      ref.invalidate(subjectsProvider);

      if (mounted) {
        Navigator.of(context).pop();
        AppSnackbar.success(
            context, '🎉 Subscription activated! Pull down to refresh if needed.');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        AppSnackbar.error(
            context, 'Payment received but verification failed. Contact support.');
      }
    }
  }

  void _onPaymentError(PaymentFailureResponse response) {
    if (mounted) {
      setState(() => _loading = false);
      
      String errorMsg = response.message ?? 'Unknown Error';
      
      // Map Razorpay error codes to user-friendly messages
      // Code 0: Network error
      // Code 1: Invalid payment ID
      // Code 2: User cancelled
      // Code 3: Invalid data
      // Code 4: App error
      // Code 5: Bad request
      
      switch (response.code) {
        case 0:
          if (errorMsg.contains('ERR_NAME_NOT_RESOLVED') || errorMsg.contains('ERR_INTERNET_DISCONNECTED')) {
            errorMsg = 'Network error. Please check your internet connection and try again.';
          } else {
            errorMsg = 'A connection error occurred. Please try again later.';
          }
          break;
        case 2:
          errorMsg = 'Payment cancelled. If the amount was debited, it will be refunded automatically.';
          break;
        default:
          errorMsg = 'Payment failed: $errorMsg';
          break;
      }

      debugPrint('❌ Razorpay Error: Code ${response.code} | Message: ${response.message}');
      
      // If code is 0, it might be an internal SDK error or bad options
      if (response.code == 0) {
        debugPrint('💡 Hint: Check if your Order ID was generated with the matching Secret Key.');
      }

      AppSnackbar.error(context, errorMsg);
    }
  }

  void _onExternalWallet(ExternalWalletResponse response) {
    if (mounted) {
      setState(() => _loading = false);
      AppSnackbar.info(
          context, 'External wallet selected: ${response.walletName}');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : AppColors.textPrimary;
    final secondaryTextColor = isDark ? AppColors.darkTextSecondary : AppColors.textSecondary;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkDivider : AppColors.divider,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),
          // Lock icon
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(
              Icons.lock_open_rounded,
              color: Colors.white,
              size: 30,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Unlock ${widget.semesterName}',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: textColor,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Get full access to all summary book and past paper of this semester',
            style: TextStyle(
              fontSize: 14,
              color: secondaryTextColor,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          // Features list
          ...[
            ('Summary book + past paper + IMP', Icons.description_rounded),
            ('6 month full access to semester', Icons.calendar_today_rounded),
            ('Unlimited access', Icons.visibility_rounded),
            ('Secure content', Icons.security_rounded),
          ].map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.secondary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(item.$2,
                        size: 16, color: AppColors.secondary),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    item.$1,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: textColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          // Price badge
          Container(
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurfaceVariant : AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'One-time payment',
                  style: TextStyle(
                    color: secondaryTextColor,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    '₹75',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          AppButton(
            label: 'Pay ₹75 & Unlock Access',
            loading: _loading,
            onPressed: _initiatePayment,
            icon: Icons.payment_rounded,
          ),
          const SizedBox(height: 12),
          Text(
            'Secure payment powered by Razorpay',
            style: TextStyle(
              fontSize: 12,
              color: isDark ? AppColors.darkTextSecondary.withOpacity(0.5) : AppColors.textHint,
            ),
          ),
        ],
      ),
    );
  }
}
