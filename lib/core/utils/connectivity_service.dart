// lib/core/utils/connectivity_service.dart
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

final connectivityProvider = StreamProvider<bool>((ref) {
  return Connectivity().onConnectivityChanged.map(
        (results) => results.any((r) => r != ConnectivityResult.none),
      );
});

/// Widget — wrap inside any screen's Scaffold body to show a banner
/// when internet is lost.
class NoInternetBanner extends ConsumerWidget {
  final Widget child;
  const NoInternetBanner({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connAsync = ref.watch(connectivityProvider);

    return connAsync.when(
      data: (isConnected) => Column(
        children: [
          if (!isConnected)
            Material(
              color: AppColors.accent,
              child: const SafeArea(
                bottom: false,
                child: Padding(
                  padding:
                      EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      Icon(Icons.wifi_off_rounded,
                          color: Colors.white, size: 18),
                      SizedBox(width: 8),
                      Text(
                        'No internet connection',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          Expanded(child: child),
        ],
      ),
      loading: () => child,
      error: (_, __) => child,
    );
  }
}
