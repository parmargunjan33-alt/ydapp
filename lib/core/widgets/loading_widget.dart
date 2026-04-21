// lib/core/widgets/loading_widget.dart
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../theme/app_theme.dart';

class LoadingWidget extends StatelessWidget {
  final bool shimmer;
  const LoadingWidget({super.key, this.shimmer = false});

  @override
  Widget build(BuildContext context) {
    if (shimmer) return const _ShimmerList();
    return const Center(
      child: CircularProgressIndicator(color: AppColors.primary),
    );
  }
}

class _ShimmerList extends StatelessWidget {
  const _ShimmerList();

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.divider,
      highlightColor: AppColors.surfaceVariant,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 6,
        itemBuilder: (_, __) => Container(
          margin: const EdgeInsets.only(bottom: 12),
          height: 80,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }
}
