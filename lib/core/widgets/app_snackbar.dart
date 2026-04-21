// lib/core/widgets/app_snackbar.dart
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class AppSnackbar {
  static void show(
    BuildContext context,
    String message, {
    Color backgroundColor = AppColors.textPrimary,
    IconData? icon,
    Duration duration = const Duration(seconds: 3),
  }) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Row(
            children: [
              if (icon != null) ...[
                Icon(icon, color: Colors.white, size: 18),
                const SizedBox(width: 10),
              ],
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          backgroundColor: backgroundColor,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
          duration: duration,
        ),
      );
  }

  static void success(BuildContext context, String message) => show(
        context,
        message,
        backgroundColor: AppColors.secondary,
        icon: Icons.check_circle_rounded,
      );

  static void error(BuildContext context, String message) => show(
        context,
        message,
        backgroundColor: AppColors.accent,
        icon: Icons.error_rounded,
      );

  static void info(BuildContext context, String message) => show(
        context,
        message,
        backgroundColor: AppColors.primary,
        icon: Icons.info_rounded,
      );
}
